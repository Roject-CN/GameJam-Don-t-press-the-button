# 别按那个键 — GameJam 项目

注意：如果ClaudeCode想要执行任务，必须是todo.md里面的任务，其他文档里的内容仅供参考，不要直接修改，除非用户明确要求修改。

## 项目概述
- Godot 4.7 2D 塔防游戏，"桌面隐喻"风格
- 2周单人开发，纯 GDScript
- 敌人是鼠标光标，试图点击地图上的按钮
- 玩家部署钓鱼弹窗、炮塔、盾牌猛击防御

## 文档角色说明
- `docs/GDD.md` — **工程现状文档**。只描述已实现的类设计、系统设计和运行时行为。所有 agent 的权威参考。
- `docs/TODO.md` — 需要我们完成的任务列表。**agent 只执行此文件中的任务。**
- `docs/IDEA.md` — 个人想法存储和灵感草稿。**agent 不需要读取此文件**，里面的设计不一定是要做的。

## 命名规范（编写 GDScript 时必须遵循）
- 类名/节点名: PascalCase（`BaseEnemy` `FailureButton`）
- 变量名/方法名/文件名: snake_case（`click_times` `current_button` `base_button.gd`）
- 私有方法: 前缀 `_`（`_ready()` `_on_xxx()`）
- 枚举值: UPPER_SNAKE_CASE（`FAILURE` `DEBUFF`）
- 详细规范见 `README.md`

## 项目配置
### 基本设置
- 应用名称: `"别按那个键"`
- 主场景: `res://scenes/main/main.tscn`
- 分辨率: 1280 × 720
- 纹理过滤: Nearest（像素风格）
- Godot 版本: 4.7

### 输入映射
| 动作名 | 绑定 | 用途 |
|---|---|---|
| `left_mouse` | 鼠标左键 | 主点击 / 当前用于调试生成敌人 |
| `slam_ability` | 空格键 (Key 32) | 盾牌猛击技能（预留，未实现） |
| `cancel_action` | 鼠标右键 | 取消当前操作（预留，未实现） |

### 全局组 (Global Groups)
- `"ClickedButtons"` — 所有按钮节点，供敌人寻路查询目标

### Autoloads (全局单例)
- `SignalBus` — `scripts/autoloads/signal_bus.gd`（buff_applied / buff_expired / button_clicked）
- `GameState` — `scripts/autoloads/game_state.gd`（fragments / lives / active_buffs / query / modifier）

### 全局类 (class_name)
- `BuffEffect` (Resource) — `scripts/buffs/buff_effect.gd`，Buff 效果数据（Target 枚举 + props）
- `BaseClickedButton` — `scripts/buttons/base_button.gd`，按钮基类
- `FailureButton` — `scripts/buttons/failure_button.gd`，失败按钮（占位）
- `DebuffButton` — `scripts/buttons/debuff_button.gd`，负面效果按钮（占位）
- `BaseEnemy` — `scripts/enemies/base_enemy.gd`，敌人基类，集成 Buff 系统实时速度响应

## 目录结构
```
GameJam/
├── project.godot              ✅ 项目配置
├── icon.svg                   ✅ 应用图标
├── CLAUDE.md                  ✅ 项目说明（给 AI Agent）
├── README.md                  ✅ 团队协作规范
├── .gitignore                 ✅
├── docs/
│   ├── GDD.md                 ✅ 工程现状文档
│   ├── IDEA.md                📝 个人想法存储（非工程文档）
│   └── TODO.md                ⏳ 任务列表（空）
├── scripts/
│   ├── buttons/
│   │   ├── base_button.gd     ✅ BaseClickedButton 类
│   │   ├── failure_button.gd  ✅ FailureButton 占位
│   │   └── debuff_button.gd   ✅ DebuffButton 占位
│   ├── enemies/
│   │   └── base_enemy.gd      ✅ BaseEnemy 类（集成 Buff 系统）
│   ├── buffs/
│   │   └── buff_effect.gd     ✅ BuffEffect Resource
│   ├── autoloads/
│   │   ├── signal_bus.gd      ✅ SignalBus
│   │   └── game_state.gd      ✅ GameState
│   ├── components/            ⏳ 空
│   ├── defenses/              ⏳ 空
│   ├── systems/               ⏳ 空
│   └── ui/                    ⏳ 空
├── scenes/
│   ├── main/
│   │   ├── main.tscn          ✅ 主场景
│   │   └── main.gd            ✅ 主场景脚本（调试生成器）
│   ├── buttons/
│   │   └── base_button.tscn   ✅ 按钮场景
│   ├── enemies/
│   │   └── base_enemy.tscn    ✅ 敌人场景
│   ├── defenses/              ⏳ 空
│   ├── effects/               ⏳ 空
│   └── ui/                    ⏳ 空
├── resources/
│   ├── buffs/                 ⏳ 空（BuffEffect .tres 将放在此）
│   ├── defenses/              ⏳ 空
│   ├── enemies/               ⏳ 空
│   ├── upgrades/              ⏳ 空
│   └── waves/                 ⏳ 空
├── assets/
│   ├── mouse.png              ✅ 鼠标光标贴图（敌人外观）
│   ├── fonts/                 ⏳ 空
│   ├── sounds/
│   │   ├── music/             ⏳ 空
│   │   └── sfx/               ⏳ 空
│   ├── sprites/               ⏳ 空（含子目录）
│   └── themes/                ⏳ 空
└── shaders/                   ⏳ 空
```
> ✅ = 已实现  ⏳ = 空目录/待填充  📝 = 参考文档

## 当前进度
- ✅ 设计文档 (GDD.md — 工程现状)
- ✅ Godot 项目骨架 (project.godot)
- ✅ 主场景 main.tscn（预置敌人 + 导航区域）
- ✅ BaseClickedButton 基类（press/release + SignalBus 集成）
- ✅ FailureButton + DebuffButton 占位类
- ✅ BaseEnemy 基类（NavigationAgent2D 寻路 + Buff 实时速度响应）
- ✅ BuffEffect Resource + SignalBus + GameState Autoloads
- ✅ 调试敌人生成器（鼠标左键点击生成敌人）
- ✅ README 团队协作规范
- ⏳ 按钮点击的实际效果（FailureButton/DebuffButton 子类逻辑）
- ⏳ 波次系统
- ⏳ 防御设施
- ⏳ 经济系统
- ⏳ UI/HUD
- ⏳ 音效/美术素材

## Godot 调试日志路径

Godot 编辑器和运行时的所有输出（报错、警告、print）会写入：

```
C:\Users\Roject\AppData\Roaming\Godot\app_userdata\别按那个键\logs\godot.log
```

- `godot.log` 是当前/最近一次运行的日志
- 带时间戳的 `godotYYYY-MM-DDTHH.MM.SS.log` 是历史日志
- 用户报告 Godot 报错时，**直接 Read 这个文件**，不需要用户复制粘贴

## 启动方式
1. 用 Godot 4.7 打开 `project.godot`
2. 直接按 F5 运行 (会加载 `scenes/main/main.tscn`)
