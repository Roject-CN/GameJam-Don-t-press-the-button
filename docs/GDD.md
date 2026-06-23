# GDD — "别按那个键"（工程现状）

> 引擎: Godot 4.7 | 分辨率: 1280×720 | 纹理过滤: Nearest（像素风格）

## 概述

桌面隐喻风格 2D 塔防。敌人是鼠标光标，试图点击地图上的按钮。玩家部署防御设施保护按钮，阻止它们触发"失败按钮"。

---

## 已实现

### BaseClickedButton — 按钮基类

> `scripts/buttons/base_button.gd` | `scenes/buttons/base_button.tscn`
> Node2D → class_name BaseClickedButton | 全局组 `ClickedButtons`

可被敌人点击的按钮。内置 Godot Button 子节点（toggle_mode），由敌人调用 `press()`/`release()` 模拟按下弹起动画。点击时触发 `_on_button_pressed()`，子类覆写此方法实现具体效果。

| 导出 | 默认 | 说明 |
|---|---|---|
| text | "" | 按钮显示文本 |

方法: `press()` `release()` `_on_button_pressed()`

场景: `Node2D (×2)` → `Button (8×8, toggle_mode)`

---

### BaseEnemy — 敌人（鼠标光标）

> `scripts/enemies/base_enemy.gd` | `scenes/enemies/base_enemy.tscn`
> Node2D → class_name BaseEnemy

鼠标光标外观的敌人。从 `ClickedButtons` 组中随机选取目标，NavigationAgent2D 自动寻路。到达后播放点击动画、调用按钮的 press/release。点击次数耗尽后播放淡出动画并销毁。

| 导出 | 默认 | 说明 |
|---|---|---|
| health | 1 | （预留，未使用） |
| click_times | 2 | 剩余点击次数，≤0 时触发 free_self() |
| speed | 200 | 移动速度 |

click_times setter: ≤0 → `free_self()`; >0 → `navigation()` 重新寻路

current_button setter: 赋值时自动同步 `navigation_agent_2d.target_position`

方法: `navigation()` `click()` `free_self()` `_physics_process(delta)` `_on_navigation_agent_2d_navigation_finished()`

场景:
```
Node2D (×0.5)
├── Sprite2D (mouse.png, rot≈28.5°)
├── AnimationPlayer (RESET / clicked / free)
├── Area2D → CollisionShape2D (CircleShape2D, r≈24)
└── NavigationAgent2D
```

---

### BuffEffect — 效果数据 Resource

> `scripts/buffs/buff_effect.gd`
> Resource → class_name BuffEffect

纯数据容器。描述一个 Buff：目标类型、属性乘数、持续波次。可在编辑器中创建 `.tres` 文件定义具体效果。目前仅数据定义，尚未接入任何系统。

| 导出 | 类型 | 说明 |
|---|---|---|
| display_name | String | UI 显示名 |
| target | Target 枚举 | ENEMY / DEFENSE / PLAYER / TERRAIN |
| props | Dictionary | 属性乘数，如 `{"speed": 1.3}` |
| duration_waves | int | 持续波次数，0 = 永久 |

方法: `init()` — 初始化计数器; `tick_wave()` → bool — 波次结束倒计数，返回 true 表示过期

---

### main.tscn — 主场景

> `scenes/main/main.tscn` | 脚本 `scenes/main/main.gd`

根场景。预置 1 个敌人 + 3 个按钮 + 导航区域。`main.gd` 监听 `left_mouse`，左键点击在鼠标位置生成敌人——纯调试用途。

场景:
```
Main (Node2D)
├── NavigationRegion2D (~1280×720, 隐藏)
├── BaseButton ×3（测速1/2/3）
└── BaseEnemy ×1
```

---

## 输入映射

| 动作 | 绑定 | 用途 |
|---|---|---|
| left_mouse | 鼠标左键 | 调试生成敌人 |
| slam_ability | 空格 | 预留 |
| cancel_action | 鼠标右键 | 预留 |

## 全局组

| 组名 | 说明 |
|---|---|
| ClickedButtons | 敌人寻路目标池 |

## 尚未实现

- SignalBus / GameState Autoloads
- FailureButton / DebuffButton 子类
- BaseEnemy 接入 Buff 系统
- 波次生成系统
- 防御设施（炮塔等）
- 碎片经济系统
- HUD / UI / 商店面板
- 音效 / 美术素材
