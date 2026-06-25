# 更新日志 — "别按那个键"

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
- 容器解耦：全部 BuffContainer 改为组合模式（EnemyContainer / PlayerContainer / DefenceManager）
- 移除冗余：删除 TerrainContainer / PlacementManager / DefenseContainer
- 卡组系统：CardDeck / CardEntry 资源配置，替代单卡种硬编码
- HUD 重构：前后端分离，HUD 监听 GlobalManager 信号自主更新
- 移除倒计时/波次显示，Ready 首次确认后自动推进
- 窗口防御简化：双层 Area（外层引诱 + 内层秒杀）
- 新文件结构：scripts/enemies/ / scripts/systems/ 分类整理

## 2026-06-24

- 防御工事系统 Phase 1：BaseDefense + TurretDefense + PhishingWindowDefense + Projectile
- DefenceManager（组合 BuffContainer）
- 初始 Buff 系统：BuffEffect / BuffContainer / BuffEmitter
- EnemyContainer + PlayerContainer
- StageManager FSM（BUILD/BATTLE/SETTLE）
- BaseEnemy 基类（NavigationAgent2D 寻路）
- BaseClickedButton 按钮基类
