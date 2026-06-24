# TODO — "别按那个键"

## 已完成
- [x] project.godot 骨架 + main.tscn 主场景 + 输入映射
- [x] BaseClickedButton 按钮基类（buff_effect + buff_effect_applied 信号）
- [x] BaseEnemy 敌人类（寻路 / 点击 / 死亡 / enemy_died 信号）
- [x] BuffEffect Resource 数据容器
- [x] BuffContainer + BuffEmitter（Buff 路由链路）
- [x] EnemyContainer（继承 BuffContainer，敌人生成 + 波次结束检测）
- [x] StageManager FSM（BUILD/BATTLE/SETTLE 三阶段状态机）
- [x] FailureEffect 按钮效果（PlayerContainer + failure_effect.tres → StageManager.lose_life）
- [x] PlayerContainer（继承 BuffContainer，life_lost 信号）
- [x] 防御设施 Phase 1（炮塔 + 钓鱼窗口核心逻辑 + Projectile，PlacementManager 测试放置）
- [x] 临时 HUD（波次显示 / 命数显示 / 结算页面）

---

## 待做
- [ ] 敌人生成系统（wave_resource 定义每波敌人类型+数量）
- [ ] HUD Phase 2（碎片 / 冷却 / 商店面板）
- [ ] 防御设施 Phase 2（正式放置 UI、升级系统、盾牌猛击）

---

## 队友模块
- 关卡和切换模块（宇宙霸主绝赞爆肝中）
