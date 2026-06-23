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

管理敌人生成和存活计数。`enemies_spawn(amount)` 在鼠标附近生成敌人，全灭时发射 `battle_overd`。

方法: `enemies_spawn(amount)` `apply_buff(e)` `remove_buff(e)`
信号: `battle_overd`

---

## StageManager — 阶段状态机

> `scripts/main/stage_manager.gd` | Node2D → class_name StageManager

FSM 模式管理 BUILD → BATTLE → SETTLE 三个阶段。`change_stage()` 为唯一转换入口，每个阶段有 `_enter_xxx` / `_exit_xxx` 钩子。通过 @export 持有模块引用并直接调用接口。然后利用模块的信号连接change_stage()，实现阶段切换，比如敌人模块EnemyContainer发射battle_overd → StageManager.end_battle() → change_stage(SETTLE)。

| 导出 | 说明 |
|---|---|
| enemy_container | EnemyContainer 引用 |
| buff_emitter | BuffEmitter 引用 |
| total_waves 等 | 波数/碎片/命数配置 |

枚举: `Stage { BUILD, BATTLE, SETTLE }`
方法: `change_stage(s)` `start_battle()` `end_battle()` `lose_life(n)` `add_fragments(n)`
信号: `fragments_changed` `lives_changed` `game_won` `game_lost`

当前行为:
- BUILD 进入: 显示 Ready 按钮，连接点击/倒计时 → start_battle
- BUILD 退出: 隐藏按钮，断连信号，spawn 5 敌人
- BATTLE 进入: 连接 battle_overd → end_battle
- SETTLE 进入: buff_emitter.disconnect_all()

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

- FailureEffect（扣命逻辑连接 StageManager）
- wave_resource 波次数据
- 防御设施
- HUD / UI
- 音效 / 美术
