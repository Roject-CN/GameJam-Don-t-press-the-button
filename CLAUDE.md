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
- `docs/log.md` — 团队更新日志，记录 commit 级别的变更。
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

### 全局类 (class_name)
- `BuffEffect` (Resource) — `scripts/buffs/buff_effect.gd`，Buff 效果数据（Target 枚举 + prop + duration_waves）
- `BaseClickedButton` — `scripts/buttons/base_button.gd`，按钮基类（buff_effect + buff_effect_applied + button_clicked 信号）
- `BaseEnemy` — `scripts/enemies/base_enemy.gd`，敌人基类（寻路 + 点击 + 死亡 + redirect_to + take_damage + enemy_died 信号）
- `BuffContainer` — `scripts/buffs/buff_container.gd`，Buff 容器基类（apply/remove + 信号）
- `BuffEmitter` — `scripts/buffs/buff_emitter.gd`，Buff 触发路由（按钮信号 → 容器）
- `EnemyContainer` — `scripts/main/enemy_container.gd`，敌人容器（继承 BuffContainer，生成 + 存活计数）
- `StageManager` — `scripts/main/stage_manager.gd`，阶段状态机（BUILD/BATTLE/SETTLE FSM，信号集中 _ready 连接）
- `PlayerContainer` — `scripts/players/player_container.gd`，玩家容器（继承 BuffContainer，life_lost → StageManager.lose_life）
- `BaseDefense` — `scripts/defenses/base_defense.gd`，防御基类（ghost 预览 + 放置 + _on_placed 覆写）
- `TurretDefense` — `scripts/defenses/turret_defense.gd`，射击炮塔（自动索敌 + 弹丸射击）
- `PhishingWindowDefense` — `scripts/defenses/phishing_window.gd`，钓鱼窗口（引诱 + 双计数器）
- `Projectile` — `scripts/defenses/projectile.gd`，弹丸（飞行 + 命中伤害）
- `DefenseContainer` — `scripts/defenses/defense_container.gd`，防御容器（继承 BuffContainer，存放已放置防御）
- `PlacementManager` — `scripts/defenses/placement_manager.gd`，测试放置（按键 1/2 + 鼠标放置）

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
│   │   └── base_button.gd     ✅ BaseClickedButton 类
│   ├── enemies/
│   │   └── base_enemy.gd      ✅ BaseEnemy 类
│   ├── buffs/
│   │   ├── buff_effect.gd     ✅ BuffEffect Resource
│   │   ├── buff_container.gd  ✅ BuffContainer 基类
│   │   └── buff_emitter.gd    ✅ BuffEmitter 路由
│   ├── main/
│   │   ├── main.gd            ✅ 主场景脚本（调试）
│   │   ├── stage_manager.gd   ✅ StageManager FSM
│   │   └── enemy_container.gd ✅ EnemyContainer
│   ├── players/
│   │   └── player_container.gd ✅ PlayerContainer
│   ├── level_control/         🆕 队友的关卡模块
│   │   ├── level.gd           ✅ 关卡定义
│   │   └── level_loader.gd    ✅ 关卡加载器
│   ├── autoloads/             ⏳ 空目录
│   ├── components/            ⏳ 空
│   ├── defenses/
│   │   ├── base_defense.gd     ✅ BaseDefense 基类
│   │   ├── turret_defense.gd   ✅ TurretDefense
│   │   ├── phishing_window.gd  ✅ PhishingWindowDefense
│   │   ├── projectile.gd       ✅ Projectile
│   │   ├── defense_container.gd ✅ DefenseContainer
│   │   └── placement_manager.gd ✅ PlacementManager
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
│   ├── defenses/
│   │   ├── base_defense.tscn       ✅
│   │   ├── turret_defense.tscn     ✅
│   │   ├── phishing_window.tscn    ✅
│   │   └── projectile.tscn         ✅
│   ├── effects/               ⏳ 空
│   └── ui/                    ⏳ 空
├── resources/
│   ├── buff_effect/
│   │   ├── test.tres            ✅ 测试用
│   │   └── failure_effect.tres   ✅ 扣命效果（target=PLAYER, prop=1.0）
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
- ✅ Godot 项目骨架 (project.godot)
- ✅ 主场景 main.tscn（按钮 + 敌人 + 导航区域）
- ✅ BaseClickedButton 基类（buff_effect 数组 + buff_effect_applied 信号）
- ✅ BaseEnemy 基类（NavigationAgent2D 寻路 / 点击 / 死亡动画 / enemy_died 信号）
- ✅ BuffEffect Resource（Target 枚举 + prop + duration_waves）
- ✅ BuffContainer + BuffEmitter（Buff 路由链路）
- ✅ EnemyContainer（继承 BuffContainer，敌人生成 + battle_overd）
- ✅ StageManager FSM（信号集中 _ready，阶段守卫防呆）
- ✅ PlayerContainer（继承 BuffContainer，life_lost → StageManager.lose_life）
- ✅ FailureEffect（failure_effect.tres，target=PLAYER prop=1.0）
- ✅ 调试敌人生成器（右键生成敌人）
- ✅ 队友关卡模块（level.gd / level_loader.gd）
- ✅ 防御设施 Phase 1（炮塔 + 钓鱼窗口核心逻辑 + Projectile，PlacementManager 测试放置）
- ✅ 临时 HUD（波次 / 命数 / 结算页面）
- ⏳ wave_resource 波次数据
- ⏳ 防御设施 Phase 2（正式放置 UI / 升级 / 盾牌猛击）
- ⏳ HUD Phase 2（碎片显示 / 冷却环 / 商店面板）
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
