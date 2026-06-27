# TODO — "别按那个键"

## 已完成
- [x] project.godot 骨架 + 输入映射
- [x] BaseClickedButton 按钮基类
- [x] BaseEnemy 敌人类（配置驱动位置寻路）
- [x] EnemyConfig 敌人配置 Resource
- [x] BuffEffect / PropertyBuffEffect / BuffContainer / BuffEmitter（策略模式 + 存储管理 + 波次过期）
- [x] EnemyManager（存活计数 + battle_over）
- [x] WaveEntry / WaveData / EnemyCatalog / WaveController（波次系统）
- [x] SpawnMarker（关卡标记点）
- [x] GlobalManager（信号 hub，无阶段枚举）
- [x] PlayerManager（lives_changed + life_lost + lives_depleted，current_lives setter）
- [x] 防御系统（BaseDefense + TurretDefense + PhishingWindowDefense + Projectile + DefenceManager）
- [x] HUD（Ready + 命数 + 结算 + 卡组系统）
- [x] CardContainer / BaseCard / CardDeck / CardEntry
- [x] LevelController（关卡切换）

- [X]  project.godot 骨架 + 输入映射
- [X]  BaseClickedButton 按钮基类
- [X]  BaseEnemy 敌人类（配置驱动位置寻路）
- [X]  EnemyConfig 敌人配置 Resource
- [X]  BuffEffect / BuffContainer / BuffEmitter（组合模式）
- [X]  EnemyContainer（存活计数 + battle_over）
- [X]  WaveEntry / WaveData / EnemyCatalog / WaveController（波次系统）
- [X]  SpawnMarker（关卡标记点）
- [X]  GlobalManager（信号 hub）
- [X]  PlayerContainer（life_lost）
- [X]  防御系统（BaseDefense + TurretDefense + PhishingWindowDefense + Projectile + DefenceManager）
- [X]  HUD（Ready + 命数 + 结算 + 卡组系统）
- [X]  CardContainer / BaseCard / CardDeck / CardEntry
- [X]  LevelController（关卡切换）
- [X]  基于表格编辑的关卡设计范式(波次)

## 待做

- [ ]  关卡设计其余内容的范式设计(路径，关键点，按钮以及对应效果)
- [ ]  取消自动寻路，改为固定路径配置方案
- [ ]  音效/美术素材
- [ ]  防御设施升级系统
- [ ]  更多敌人类型和防御类型
