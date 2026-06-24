# GDD — "别按那个键"（工程现状）

> 引擎: Godot 4.7 | 分辨率: 1280×720 | 纹理过滤: Nearest

## 概述

桌面隐喻风格 2D 塔防。敌人是鼠标光标，试图点击地图上的按钮。玩家部署防御设施保护按钮。

---

## BaseClickedButton — 按钮基类

> `scripts/buttons/base_button.gd` | `scenes/buttons/base_button.tscn`
> Node2D → class_name BaseClickedButton | 全局组 `ClickedButtons`

内置 Godot Button 子节点。可搭载多个 BuffEffect，点击时逐一发射 `buff_effect_applied` 信号。

| 导出 | 类型 | 说明 |
|---|---|---|
| text | String | 按钮显示文本 |
| buff_effect | Array[BuffEffect] | 搭载的效果列表 |

方法: `press()` `release()` `_on_button_pressed()`
信号: `buff_effect_applied(effect: BuffEffect)`
场景: `Node2D (×2)` → `Button (8×8, toggle_mode)`

---

## BaseEnemy — 敌人

> `scripts/enemies/base_enemy.gd` | `scenes/enemies/base_enemy.tscn`
> Node2D → class_name BaseEnemy

鼠标光标外观。从 ClickedButtons 组随机选目标，NavigationAgent2D 寻路，到达后播放点击动画。click_times 耗尽后播放淡出动画，发射 `enemy_died` 信号并销毁。

| 导出 | 默认 | 说明 |
|---|---|---|
| health | 1 | 预留 |
| click_times | 2 | 剩余点击次数，≤0 → free_self() |
| speed | 200 | 移动速度 |

信号: `enemy_died()`
方法: `navigation()` `click()` `free_self()` `_physics_process(delta)` `_on_navigation_agent_2d_navigation_finished()`

场景: `Node2D (×0.5)` → Sprite2D + AnimationPlayer (RESET/clicked/free) + Area2D + NavigationAgent2D

---

## BuffEffect — 效果数据 Resource

> `scripts/buffs/buff_effect.gd` | Resource → class_name BuffEffect

纯数据容器。描述 Buff 的目标类型、属性乘数、持续波次。

| 导出 | 类型 | 说明 |
|---|---|---|
| buff_name | String | 效果名称 |
| target | Target 枚举 | ENEMY / DEFENSE / PLAYER / TERRAIN |
| prop | float | 属性乘数（1.3=+30%） |
| duration_waves | int | 持续波次，0=永久 |

枚举: `Target { ENEMY, DEFENSE, PLAYER, TERRAIN }`
方法: `init()` `tick_wave()` → bool

---

## BuffContainer — Buff 容器

> `scripts/buffs/buff_container.gd` | Node2D → class_name BuffContainer

维护活跃 Buff 列表。`apply_buff`/`remove_buff` 时发信号。具体逻辑由子类（如 EnemyContainer）覆写。

| 导出 | 说明 |
|---|---|
| target_type | 本容器对应哪种 Target |

方法: `apply_buff(effect)` `remove_buff(effect)`
信号: `buff_applied` `buff_expired` `buffs_changed`

---

## BuffEmitter — Buff 触发路由

> `scripts/buffs/buff_emitter.gd` | Node2D → class_name BuffEmitter

遍历 button_container 下所有 BaseClickedButton，连接 `buff_effect_applied` 信号。收到后 duplicate BuffEffect → 查 target → 调用对应 BuffContainer 的 `apply_buff()`。

| 导出 | 说明 |
|---|---|
| enemy_container 等 | BuffContainer 引用，编辑器拖入 |
| button_container | 按钮父节点 |

方法: `connect_all()` `disconnect_all()`

---

## EnemyContainer — 敌人容器

> `scripts/main/enemy_container.gd` | 继承 BuffContainer → class_name EnemyContainer

管理敌人生成和存活计数。`enemies_spawn(amount)` 在鼠标附近生成敌人，全灭时发射 `battle_over`。

方法: `enemies_spawn(amount)` `apply_buff(e)` `remove_buff(e)`
信号: `battle_over`

---

## 防御系统 — Phase 1

### BaseDefense — 防御基类

> `scripts/defenses/base_defense.gd` | Node2D → class_name BaseDefense

防御工事基类。`_process` 中未放置时调用 `_ghost()`（跟随鼠标 + modulate.a=0.5 半透明），`place()` 恢复不透明并触发 `_on_placed()`。

| 导出 | 类型 | 说明 |
|---|---|---|
| cost | int | 放置消耗碎片 |
| defense_name | String | 显示名称 |

方法: `place()` `_ghost()` `_on_placed()`（子类覆写）

### TurretDefense — 射击炮塔

> `scripts/defenses/turret_defense.gd` | extends BaseDefense → class_name TurretDefense

自动索敌射击。`_on_placed()` 连接 `area_node.area_entered/area_exited`，`_process` 中选最近敌人发射 Projectile。

| 导出 | 默认 | 说明 |
|---|---|---|
| fire_rate | 1.5 | 射击间隔(秒) |
| damage | 1 | 每发伤害 |

### Projectile — 弹丸

> `scripts/defenses/projectile.gd` | Node2D → class_name Projectile

炮塔发射的弹丸，`_physics_process` 中飞向目标敌人，命中后调用 `take_damage()` 并自毁。

方法: `setup(target, damage)` — 设置目标与伤害

### PhishingWindowDefense — 钓鱼窗口

> `scripts/defenses/phishing_window.gd` | extends BaseDefense → class_name PhishingWindowDefense

引诱范围内敌人改向到内置隐藏 BaseButton。双计数器：`live_count`（引诱次数 → 变灰）、`_life`（被点击次数 → 淡出销毁）。生命归零时遍历已引诱敌人调用 `clear_taunt_target()` 归还正常导航。

| 导出 | 默认 | 说明 |
|---|---|---|
| live_count | 10 | 引诱次数上限 |
| taunt_radius | 150 | 引诱半径(px) |

方法: `on_enemy_click()` `_on_enemy_entered(area)`

### DefenseContainer — 防御容器

> `scripts/defenses/defense_container.gd` | 继承 BuffContainer → class_name DefenseContainer

存放已放置的防御实例，接收 DEFENSE 目标的 Buff。`_ready()` 自设 `target_type = DEFENSE`。

### PlacementManager — 测试放置

> `scripts/defenses/placement_manager.gd` | Node2D → class_name PlacementManager

简单测试放置：按 1/2 选防御 → ghost 跟鼠标 → left_mouse 点击放置 → spend_fragments 扣碎片。

---

## PlayerContainer — 玩家容器

> `scripts/players/player_container.gd` | 继承 BuffContainer → class_name PlayerContainer

接收 PLAYER 目标的 BuffEffect。`apply_buff()` 覆写：按 `effect.prop` 值发射 `life_lost` 信号，由 StageManager 连接 → `lose_life()`。

方法: `apply_buff(e)` `remove_buff(e)`
信号: `life_lost(amount: int)`

---

## StageManager — 阶段状态机

> `scripts/main/stage_manager.gd` | Node2D → class_name StageManager

FSM 模式管理 BUILD → BATTLE → SETTLE 三个阶段。`change_stage()` 为唯一转换入口，每个阶段有 `_enter_xxx` / `_exit_xxx` 钩子。所有模块信号在 `_ready()` 中一次性集中连接，enter/exit 只负责阶段行为（UI 显隐、Timer 启停、生成敌人）。

| 导出 | 说明 |
|---|---|
| enemy_container | EnemyContainer 引用 |
| buff_emitter | BuffEmitter 引用 |
| player_container | PlayerContainer 引用 |
| wave_label / lives_label / game_over_label | HUD Label 引用 |
| total_waves 等 | 波数/碎片/命数配置 |

枚举: `Stage { BUILD, BATTLE, SETTLE }`
方法: `change_stage(s)` `start_battle()` `end_battle()` `lose_life(n)` `add_fragments(n)` `spend_fragments(n) -> bool`
信号: `fragments_changed` `lives_changed` `game_won` `game_lost`

当前行为:
- _ready: 集中连接所有模块信号 + lives_changed → _update_lives_label
- BUILD 进入: 隐藏 game_over_label，显示 Ready + 倒计时，启动 Timer，更新 wave_label
- BUILD 退出: 隐藏 UI，停 Timer，spawn 5 敌人
- BATTLE 进入: pass
- SETTLE 进入: 断开 BuffEmitter，显示 game_over_label（"你赢了/输了"）

---

## main.gd — 主场景脚本

> `scripts/main/main.gd` | extends Control

调试用。右键点击 → EnemyContainer 生成 5 个敌人。

---

## 输入映射

| 动作 | 绑定 | 用途 |
|---|---|---|
| left_mouse | 鼠标左键 | 预留 |
| right_mouse | 鼠标右键 | 调试生成敌人 |
| slam_ability | 空格 | 预留 |
| cancel_action | 鼠标右键 | 预留 |

## 全局组

| 组名 | 说明 |
|---|---|
| ClickedButtons | 敌人寻路目标池 |

## 尚未实现

- wave_resource 波次数据
- 防御设施 Phase 2（正式放置 UI / 升级 / 盾牌猛击）
- HUD Phase 2（碎片显示 / 冷却环 / 商店面板）
- 音效 / 美术
