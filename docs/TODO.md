# TODO — "别按那个键"

## 已完成
- [X] project.godot 骨架 + 输入映射
- [X] BaseClickedButton 按钮基类
- [X] BaseEnemy 敌人类（配置驱动位置寻路）
- [X] EnemyConfig 敌人配置 Resource
- [X] BuffEffect / PropertyBuffEffect / BuffContainer / BuffEmitter（策略模式 + 存储管理 + 波次过期）
- [X] EnemyController（波次+生成+计数+ENEMY Buff 路由）
- [X] WaveEntry / WaveData / EnemyCatalog / EnemyTypeMapping（波次配置系统）
- [X] SpawnMarker（关卡标记点）
- [X] GlobalManager（信号 hub）
- [X] PlayerContainer（lives_changed + life_lost + lives_depleted，current_lives setter）
- [X] 防御系统（BaseDefence + TurretDefense + PhishingWindowDefense + ReWindowDefense + Projectile + DefenceContainer）
- [X] WindowDefense（taunt_resistance 抵抗判定 + lure_count 实时生效）
- [X] HUD（Ready + 命数 + 结算 + CountLabel + 卡组系统）
- [X] CardContainer / BaseCard / CardDeck / CardEntry
- [X] BaseCard 右键取消拖拽放置
- [X] LevelController（关卡切换）
- [X] 基于表格编辑的关卡设计范式(波次)
- [X] DebugBuffPanel 实时调试面板
- [X] 对话系统（DialogueManager/DialogueBox，打字机效果，资源驱动）

## 待做
- [ ] 关卡设计其余内容的范式设计(路径，关键点，按钮以及对应效果)
- [ ] 音效/美术素材
- [ ] 防御设施升级系统
- [ ] 更多敌人类型和防御类型
