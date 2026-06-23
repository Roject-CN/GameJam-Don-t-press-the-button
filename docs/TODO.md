# TODO — "别按那个键"

## 已完成
- [x] project.godot 骨架 + main.tscn 主场景 + 输入映射
- [x] BaseClickedButton 按钮基类（buff_effect + buff_effect_applied 信号）
- [x] BaseEnemy 敌人类（寻路 / 点击 / 死亡 / enemy_died 信号）
- [x] BuffEffect Resource 数据容器
- [x] BuffContainer + BuffEmitter（Buff 路由链路）
- [x] EnemyContainer（继承 BuffContainer，敌人生成 + 波次结束检测）
- [x] StageManager FSM（BUILD/BATTLE/SETTLE 三阶段状态机）

---

## 待做
- [x] FailureEffect 按钮效果（PlayerContainer + failure_effect.tres → StageManager.lose_life）
- [ ] 敌人生成系统（wave_resource 定义每波敌人类型+数量）
- [ ] 防御设施（炮塔放置 + 自动射击）
- [ ] HUD（波次 / 碎片 / 命数 / 冷却显示）

---

## 队友模块
- 关卡和切换模块（宇宙霸主绝赞爆肝中）
