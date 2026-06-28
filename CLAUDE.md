# 别按那个键 — GameJam 项目

Godot 4.7 2D 塔防，"桌面隐喻"风格。敌人是鼠标光标，从生成点移动到目标点，点击按钮。玩家部署防御设施保护按钮。

## 文档
- `docs/GDD.md` — 工程现状文档，所有 agent 权威参考
- `docs/TODO.md` — 任务列表，agent 只执行此文件中任务
- `docs/log.md` — commit 级别更新日志

## 命名规范
- 类名/节点名: PascalCase | 变量/方法/文件: snake_case | 私有: `_` 前缀 | 枚举值: UPPER_SNAKE_CASE

## 项目配置
- 应用名: "别按那个键" | 分辨率: 1280×720 | 纹理过滤: Nearest | Godot 4.7

## 输入映射
| 动作 | 绑定 | 用途 |
|---|---|---|
| left_mouse | 鼠标左键 | 卡牌拖拽放置 |
| right_mouse | 鼠标右键 | 调试生成敌人 |

## 全局组
`ClickedButtons` — 敌人寻路目标池

## 全局类 (class_name)

### 运行时节点
- `BaseEnemy` — `scripts/enemies/base_enemy.gd`，敌人基类（位置驱动寻路 + setup + EnemyConfig）
- `EnemyController` — `scripts/enemies/enemy_controller.gd`，敌人总控（波次+生成+计数+ENEMY Buff）
- `PlayerContainer` — `scripts/players/player_container.gd`，玩家容器（组合 BuffContainer + lives_changed/life_lost）
- `DefenceContainer` — `scripts/defenses/defence_container.gd`，防御容器（组合 BuffContainer + ghost 孵化 + 放置）
- `GlobalManager` — `scripts/global_manager.gd`，全局信号 hub（连接 EnemyController/PlayerContainer）
- `BuffEmitter` — `scripts/buffs/buff_emitter.gd`，Buff 路由（按钮信号 → 各容器 .buff_container，含 tick_all_waves）
- `BuffContainer` — `scripts/buffs/buff_container.gd`，Buff 存储+路由节点（组合模式，含 tick_wave 波次过期）
- `SpawnMarker` — `scripts/systems/spawn_marker.gd`，关卡标记点
- `BaseClickedButton` — `scripts/buttons/base_button.gd`，桌面按钮
- `BaseDefense` — `scripts/defenses/base_defense.gd`，防御基类（ghost + place）
- `TurretDefense` — `scripts/defenses/turret_defense.gd`，射击炮塔
- `PhishingWindowDefense` — `scripts/defenses/window_defense.gd`，钓鱼窗口（双层区域）
- `Projectile` — `scripts/defenses/projectile.gd`，弹丸
- `BaseCard` — `scripts/uis/hud/card_unit.gd`，卡牌基类（长按拖拽放置）
- `CardContainer` — `scripts/uis/hud/cards.gd`，卡牌容器（从 CardDeck 初始化）
- `HUD` — `scripts/uis/hud/hud.gd`，UI 主控
- `ConutLabel` — `scripts/uis/hud/count_label.gd`，波次/击杀计数 UI
- `DebugBuffPanel` — `scripts/debug/debug_buff_panel.gd`，调试面板（实时属性 + buff 状态）

### Resource
- `BuffEffect` — `scripts/buffs/buff_effect.gd`，Buff 效果抽象基类（策略模式，Target: ENEMY/DEFENSE/PLAYER）
- `PropertyBuffEffect` — `scripts/buffs/property_buff_effect.gd`，属性修改 Buff 子类（ADD/MULTIPLY/SET）
- `EnemyConfig` — `scripts/enemies/enemy_config.gd`，敌人配置（speed/health/click_times 等）
- `WaveEntry` — `scripts/systems/wave_entry.gd`，生成条目（time_offset/wave_index/enemy_type/spawn_point/target_point）
- `WaveData` — `scripts/systems/wave_data.gd`，波次数据集合
- `EnemyTypeMapping` — `scripts/enemies/enemy_type_mapping.gd`，类型名 → PackedScene + EnemyConfig
- `EnemyCatalog` — `scripts/enemies/enemy_catalog.gd`，敌人目录
- `CardDeck` — `scripts/uis/hud/card_deck.gd`，卡组配置
- `CardEntry` — `scripts/uis/hud/card_entry.gd`，卡牌配置条目

## 目录结构
```
scripts/
├── buttons/base_button.gd
├── enemies/
│   ├── base_enemy.gd / enemy_config.gd / enemy_controller.gd
│   ├── enemy_catalog.gd / enemy_type_mapping.gd
├── buffs/
│   ├── buff_effect.gd / property_buff_effect.gd / buff_container.gd / buff_emitter.gd
├── global_manager.gd
├── players/player_container.gd
├── defenses/
│   ├── base_defense.gd / defence_container.gd
│   ├── turret_defense.gd / window_defense.gd / projectile.gd
├── systems/
│   ├── wave_entry.gd / wave_data.gd
│   └── spawn_marker.gd
├── level_control/level.gd / level_controller.gd
└── uis/hud/
	├── hud.gd / cards.gd / card_unit.gd
	├── card_deck.gd / card_entry.gd

scenes/
├── enemies/base_enemy.tscn
├── buttons/base_button.tscn
├── defenses/base_defense.tscn / turret_defense.tscn / window_defense.tscn
├── ui/hud.tscn / cards/ / count_label.tscn / logic_grid.tscn
└── levels/level_controller.tscn / test_level_0.tscn

resources/
├── buff_effect/ cards/ enemies/ waves/
```

## 当前进度
- Godot 项目骨架 + 输入映射
- BaseClickedButton 按钮基类
- BaseEnemy 敌人类（配置驱动寻路）
- EnemyConfig 敌人配置 Resource
- BuffEffect / BuffContainer / BuffEmitter（组合模式 Buff 路由）
- WaveEntry / WaveData / EnemyTypeMapping / EnemyCatalog（波次配置系统）
- EnemyController（波次时序 + 敌人生成 + 存活计数 + ENEMY Buff）
- SpawnMarker（关卡标记点）
- PlayerContainer（life_lost）
- GlobalManager（信号 hub，连接 EnemyController/PlayerContainer 驱动游戏流程）
- DefenceContainer + BaseDefense + TurretDefense + PhishingWindowDefense + Projectile
- HUD（Ready + 命数 + 结算 + 卡牌拖拽放置）
- CardContainer / BaseCard / CardDeck / CardEntry（卡组系统）
- LevelController（关卡切换）

## 启动方式
1. Godot 4.7 打开 `project.godot`
2. F5 运行
