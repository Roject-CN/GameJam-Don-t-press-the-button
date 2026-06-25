# 更新日志 — "别按那个键"

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
