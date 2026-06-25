# GDD — "别按那个键"（工程现状）

> 引擎: Godot 4.7 | 分辨率: 1280×720 | 纹理过滤: Nearest

## 概述

桌面隐喻风格 2D 塔防。敌人是鼠标光标，从生成点移动到目标点，到达后点击附近按钮。玩家部署防御设施保护按钮。

---

## 运行时架构

```
GlobalManager (信号 hub)
  ├── HUD (UI 层)
  │   ├── Ready 按钮 → GlobalManager 首次确认
  │   ├── LivesLabel / GameOverLabel  ← 监听 GlobalManager 信号
  │   └── CardContainer → CardDeck 资源 → BaseCard × N
  ├── WaveController (波次时序)
  │   ├── WaveData (全部 WaveEntry)
  │   ├── EnemyCatalog (类型名 → PackedScene + EnemyConfig)
  │   └── 按 time_offset 生成敌人 → EnemyContainer
  ├── EnemyContainer (存活计数 → battle_over)
  ├── PlayerContainer (life_lost → GlobalManager)
  ├── DefenceManager (ghost 孵化 + 放置 + 列表)
  └── BuffEmitter (按钮 → 路由 buff 到各容器的 buff_container)
```

---

## 关卡设计范式

### 敌人进攻

应通过关卡的csv配置设计敌人进攻，纯时间/分波次，其依赖的出生点，目标点机制还未实现脱离场景，正在考虑必要性

### 路径

目前的路径系统基于自动寻路，关卡设计不能容忍这个瑕疵，将会在下次关卡设计范式更新中将其与出生点，目标点机制联动

由路径表维护定义在关卡场景上的路径 & 可行/不可行字典似乎是一个不错的选择。

## 子系统

### 波次系统

#### WaveEntry — 单条生成条目

> `scripts/systems/wave_entry.gd` | Resource → class_name WaveEntry

| 导出         | 类型   | 说明                                     |
| ------------ | ------ | ---------------------------------------- |
| time_offset  | float  | 相对本波开始的秒数                       |
| wave_index   | int    | 所属波次，0 = 纯时序模式（不受波次控制） |
| enemy_type   | String | 敌人类型名，查 EnemyCatalog              |
| spawn_point  | String | 产生点，匹配关卡中 SpawnMarker 节点名    |
| target_point | String | 目标点，匹配关卡中 SpawnMarker 节点名    |

#### WaveData — 波次数据集合

> `scripts/systems/wave_data.gd` | Resource → class_name WaveData

包装 `Array[WaveEntry]`，提供 `get_wave_entries(wave_index)` 按波次查询。`total_waves` 由 WaveController 自动计算（entries 中最大 wave_index）。

#### EnemyCatalog — 敌人目录

> `scripts/enemies/enemy_catalog.gd` | Resource → class_name EnemyCatalog

| 导出     | 说明                    |
| -------- | ----------------------- |
| mappings | Array[EnemyTypeMapping] |

方法: `get_scene(type_name)` `get_config(type_name)`

#### EnemyTypeMapping — 类型映射条目

> `scripts/enemies/enemy_type_mapping.gd` | Resource → class_name EnemyTypeMapping

| 导出         | 说明                     |
| ------------ | ------------------------ |
| type_name    | 敌人类型字符串           |
| scene        | PackedScene 引用         |
| enemy_config | EnemyConfig 引用（可选） |

#### WaveController — 波次控制器

> `scripts/systems/wave_controller.gd` | Node2D → class_name WaveController

| 导出                 | 说明                |
| -------------------- | ------------------- |
| wave_data            | WaveData 资源       |
| wave_clear_fragments | 每波通关奖励碎片    |
| enemy_catalog        | EnemyCatalog 资源   |
| enemy_container      | EnemyContainer 引用 |

属性: `total_waves`（自动计算）`all_spawned()`
方法: `start_wave(n)` `stop_wave()` `is_wave_active()`

#### SpawnMarker — 标记点

> `scripts/systems/spawn_marker.gd` | Node2D → class_name SpawnMarker

关卡中放置，通过节点名被 WaveEntry.spawn_point / target_point 匹配。编辑器中显示彩色圆圈。

---

### 敌人系统

#### BaseEnemy — 敌人基类

> `scripts/enemies/base_enemy.gd` | `scenes/enemies/base_enemy.tscn`
> Node2D → class_name BaseEnemy

位置驱动寻路。WaveController 通过 `setup(config, target_pos)` 注入配置和目标，NavigationAgent2D 从生成点移动到目标点，到达后在 `click_range` 内搜索按钮点击。

| 导出                                            | 默认 | 说明                  |
| ----------------------------------------------- | ---- | --------------------- |
| speed / health / click_times / taunt_resistance | —   | 可被 EnemyConfig 覆盖 |
| click_range                                     | 50   | 到达后搜索按钮范围    |

信号: `enemy_died()`
方法: `setup(config, target_pos)` `_navigate_to(pos)` `redirect_to(btn)` `clear_taunt_target()` `free_self()`

#### EnemyConfig — 敌人配置

> `scripts/enemies/enemy_config.gd` | Resource → class_name EnemyConfig

| 导出             | 默认 | 说明         |
| ---------------- | ---- | ------------ |
| speed            | 200  | 移动速度     |
| health           | 1    | 生命值       |
| click_times      | 2    | 点击次数     |
| taunt_resistance | 0.0  | 钓鱼抵抗概率 |
| click_range      | 50   | 搜索按钮范围 |

#### EnemyContainer — 敌人管理器

> `scripts/enemies/enemy_container.gd` | Node2D → class_name EnemyContainer

| 导出             | 说明         |
| ---------------- | ------------ |
| button_container | 按钮容器引用 |

信号: `battle_over`
方法: `enemies_spawn(amount)` `register_enemy(enemy)`

---

### Buff 系统

#### BuffEffect — 效果数据

> `scripts/buffs/buff_effect.gd` | Resource → class_name BuffEffect

| 导出           | 说明                     |
| -------------- | ------------------------ |
| target         | ENEMY / DEFENSE / PLAYER |
| prop           | 属性乘数                 |
| duration_waves | 持续波次                 |

#### BuffContainer — Buff 容器

> `scripts/buffs/buff_container.gd` | Node2D → class_name BuffContainer

纯路由节点。11 行。`apply_buff()` 发射 `buff_applied` 信号。组合在各管理器中。

#### BuffEmitter — Buff 路由

> `scripts/buffs/buff_emitter.gd` | Node2D → class_name BuffEmitter

遍历 button_container 下所有按钮，连接 `buff_effect_applied`。收到后按 target 路由到对应管理器的 `.buff_container`。缺失容器静默跳过。

---

### 玩家系统

#### PlayerContainer — 玩家容器

> `scripts/players/player_container.gd` | Node2D → class_name PlayerContainer

内部持有 `buff_container`，连接 `buff_applied` 信号驱动 `life_lost`。

信号: `life_lost(amount: int)`

---

### 防御系统

#### BaseDefense — 防御基类

> `scripts/defenses/base_defense.gd` | Node2D → class_name BaseDefense

ghost 半透明跟随鼠标，`place()` 恢复不透明并触发 `_on_placed()`。

#### TurretDefense — 射击炮塔

> `scripts/defenses/turret_defense.gd` | extends BaseDefense

自动索敌，发射 Projectile 造成伤害。

#### PhishingWindowDefense — 钓鱼窗口

> `scripts/defenses/window_defense.gd` | extends BaseDefense

双层区域：外层 Area 将敌人导航重定向到窗口中心，内层 AreaClick 秒杀敌人。`lure_count` 耗尽后变灰淡出。

#### ReWindowDefense — 持续引诱窗口

> `scripts/defenses/re_window_defense.gd` | extends WindowDefense

覆盖 `redirect()`，传入 repeated=true，使敌人被引诱后反复点击窗口而不返回原路线。

#### Projectile — 弹丸

> `scripts/defenses/projectile.gd` | Node2D → class_name Projectile

飞向目标敌人，命中后造成伤害并自毁。

#### DefenceManager — 防御管理器

> `scripts/defenses/defence_manager.gd` | Node2D → class_name DefenceManager

统一管理防御设施生命周期：`spawn_defence()` 孵化 ghost，`confirm_placement()` 正式放置，`remove_defence()` 移除。内部持有 `buff_container` 接收 DEFENSE 目标的 Buff。

---

### UI 系统

#### HUD — UI 主控

> `scripts/uis/hud/hud.gd` | `scenes/ui/hud.tscn`

监听 GlobalManager 信号驱动显示。管理 Ready 按钮 / 命数 / 结算 / 卡牌容器。

#### BaseCard — 卡牌基类

> `scripts/uis/hud/card_unit.gd` | Control → class_name BaseCard

长按拖拽生成防御 ghost，松手放置。自动从 HUD 获取 DefenceManager 和吸附栅格。

#### CardContainer — 卡牌容器

> `scripts/uis/hud/cards.gd` | Control → class_name CardContainer

从 CardDeck 资源读取配置，实例化多种卡牌并水平排列。

#### CardDeck / CardEntry — 卡组资源

> `scripts/uis/hud/card_deck.gd` `card_entry.gd` | Resource

CardDeck 包装 `Array[CardEntry]`，CardEntry 含 `card_scene: PackedScene` + `count: int`。

---

### 全局管理

#### GlobalManager — 全局信号 hub

> `scripts/global_manager.gd` | Node2D → class_name GlobalManager

纯后端，不持有阶段枚举。Ready 首次确认后自动推进波次序列。

信号: `lives_changed` `wave_started` `game_over(is_win)`

#### LevelController — 关卡切换

> `scripts/level_control/level_controller.gd` | Node2D

加载 / 缓存 / 切换关卡 PackedScene。

---

### 按钮

#### BaseClickedButton — 桌面按钮

> `scripts/buttons/base_button.gd` | Node2D → class_name BaseClickedButton

搭载 Array[BuffEffect]，点击时逐一发射 `buff_effect_applied`。

---

## 输入映射

| 动作          | 绑定     | 用途                |
| ------------- | -------- | ------------------- |
| left_mouse    | 鼠标左键 | 卡牌拖拽放置 / 调试 |
| right_mouse   | 鼠标右键 | 调试生成敌人        |
| slam_ability  | 空格     | 预留                |
| cancel_action | 鼠标右键 | 预留                |

## 全局组

| 组名           | 说明           |
| -------------- | -------------- |
| ClickedButtons | 敌人寻路目标池 |
