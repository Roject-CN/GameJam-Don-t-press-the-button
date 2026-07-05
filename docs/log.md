# 更新日志 — "别按那个键"

## 2026-07-05 — menu_and_defense

### 菜单系统
- 新增 MainMenu（主菜单）：开始游戏/继续游戏/退出，新游戏覆盖存档确认弹窗
- 新增 LevelSelect（选关地图）：关卡节点链表 + 贝塞尔虚线连线
- 新增 LevelNode：三态按钮（锁定/可选/已完成）
- 新增 LevelInfo Resource：关卡元数据（id/名称/场景路径/描述）
- 新增 SaveManager：ConfigFile 持久化，记录关卡解锁/完成状态

### 防御放置验证
- BaseDefense._ghost() 实时网格吸附 + tile 类型检查 + 重叠检测，无效变红
- 新增 allowed_tiles 导出：不同防御可配置允许的 tile atlas 坐标（炮塔空地+地形，窗口仅地形）
- card_unit._end_drag() 放置前二次验证，无效则取消

### 防御拆除
- 已放置防御 hover 显示摧毁按钮（self_modulate 淡入淡出）
- defence_remove_requested 信号 → DefenceContainer.remove_defence()

### 关卡流程
- level.gd 新增 level_id / next_level_id 导出
- GlobalManager._settle() 胜利时写存档自动解锁下一关
- HUD 游戏结束 AcceptDialog 确认后返回选关

## 2026-07-01 — enemy_subclasses
- 新增 RouteHijackerEnemy（路由劫持者）：移动光环塔，复用基类 LURED + A* 寻路在失败按钮间漫游，AuraArea 实时修改 300px 内友方敌人 speed/health
- 新增 SplitterEnemy（分裂者）：死亡时隐藏本体生成 2 个 mini_splitter（50% 血量/70% 速度/1 次点击），子体死完后才 queue_free
- failure_effect.tres 转 PropertyBuffEffect（ADD -1, property_name="current_lives"）
- PlayerContainer 修复：支持 PropertyBuffEffect.apply() 使回血按钮正确 +1 生命，delta!=0 保证 HUD 标签同步刷新
- EnemyCatalog 注册 hijacker / splitter / mini_splitter 类型 + 对应 EnemyConfig
- test_waves.csv Wave1 加入 hijacker + splitter 测试条目

## 2026-06-27 — merge_dialogue_system
- 合并队友对话系统（feat/dialogue-system）
- 新增 DialogueManager/DialogueTrigger/DialogueSequence/DialogueLine
- 新增 DialogueBox CanvasLayer 对话框 UI
- 示例对话：tutorial_welcome / tutorial_before_wave1 / cinematic_intro
- 清理孤立 .uid 文件

## 2026-06-27 — merge_buff_into_teammate_refactor
- 合并队友 EnemyController 架构，注入 buff 策略模式
- DefenceManager → DefenceContainer 全项目 rename
- 修复 freed 节点 buff apply 报错、新生成敌人 buff 被覆盖的时序 bug
- 场景恢复 11 测试按钮 + DebugBuffPanel
- 同步更新各类文档

## 2026-06-25 — feature_re_window ->main ->rebuild_64f

- 新增 ReWindowDefense：继承窗口防御，持续引诱模式（redirect repeated=true）
- 修复：删除 enemy_container 和 wave_controller 中对不存在的 buttons_container 字段的赋值
- BaseButton：鼠标悬停时取消 toggle_mode，离开恢复
- 卡组调整：新增 re_window_defense 卡牌（2张），炮塔数量 4→2
- 重构:精简容器
- 新增:关卡的敌人生成配置由csv完成，更好的局外编辑
- 修复:局内的一堆小bug

## 2026-06-25 — rebuild_64f

- 架构重构：StageManager → GlobalManager，移除阶段枚举，纯信号 hub
- 波次系统：WaveEntry + WaveData + EnemyCatalog + WaveController，时间戳驱动生成
- 敌人改造：位置驱动寻路（spawn_point → target_point），EnemyConfig 配置驱动
- Buff 精简：移除 active_buffs 死代码，BuffContainer 11 行纯路由
- 容器解耦：全部 BuffContainer 改为组合模式（EnemyController / PlayerContainer / DefenceContainer）
- 移除冗余：删除 TerrainContainer / PlacementManager / DefenseContainer
- 卡组系统：CardDeck / CardEntry 资源配置，替代单卡种硬编码
- HUD 重构：前后端分离，HUD 监听 GlobalManager 信号自主更新
- 移除倒计时/波次显示，Ready 首次确认后自动推进
- 窗口防御简化：双层 Area（外层引诱 + 内层秒杀）
- 新文件结构：scripts/enemies/ / scripts/systems/ 分类整理

## 2026-06-24

- 防御工事系统 Phase 1：BaseDefense + TurretDefense + PhishingWindowDefense + Projectile
- DefenceContainer（组合 BuffContainer）
- 初始 Buff 系统：BuffEffect / BuffContainer / BuffEmitter
- EnemyController + PlayerContainer
- StageManager FSM（BUILD/BATTLE/SETTLE）
- BaseEnemy 基类（NavigationAgent2D 寻路）
- BaseClickedButton 按钮基类
