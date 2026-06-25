# 更新日志 — "别按那个键"

## 2026-06-24

* 防御工事系统 Phase 1：BaseDefense（ghost 半透明鼠标跟随 / place 变不透明）、TurretDefense（Area2D area\_entered 索敌 + Projectile 弹丸射击）、PhishingWindowDefense（Area2D 检测敌人 + redirect\_to 隐藏按钮 + live\_count/\_life 双计数器 + 淡出销毁）
* 实现 Projectile（\_physics\_process 飞行 + 命中 take\_damage）、DefenseContainer（BuffContainer target\_type=DEFENSE）、PlacementManager（按键 1/2 选防御 + left\_mouse 放置 + 扣碎片）
* BaseEnemy 新增 redirect\_to(BaseClickedButton)、clear\_taunt\_target()、take\_damage()、taunt\_resistance；导航改用 EnemyContainer 传入的 buttons\_container 替代全局 group
* BaseButton 新增 button\_clicked 信号，\_on\_button\_pressed 中先于 buff\_effect\_applied 发射
* EnemyContainer 新增 button\_container 导出，enemies\_spawn 中注入给每个敌人
* BuffContainer target\_type 从 @export 改为 var（各容器子类 \_ready 自设）
* StageManager 新增 spend\_fragments()、WaveLabel/LivesLabel/GameOverLabel 绑定，\_is\_win SETTLE 结算逻辑
* 场景：base\_defense/turret\_defense/window\_defense/projectile 四个 .tscn
* 文档同步：TODO/GDD/CLAUDE/log 更新

## 2026-06-23

* 实现 PlayerContainer（继承 BuffContainer，life\_lost 信号 → StageManager.lose\_life）
* 创建 failure\_effect.tres（扣命 BuffEffect，target=PLAYER prop=1.0）
* StageManager 信号重构：4 条 connect 集中 \_ready()，删除 enter/exit 中的动态连接/断连
* 主场景更新：PlayerContainer 脚本绑定，测试按钮挂载 failure\_effect
* 实现 BuffContainer + BuffEmitter（Buff 路由链路）
* 实现 StageManager FSM（BUILD/BATTLE/SETTLE 三阶段状态机）
* 实现 EnemyContainer（继承 BuffContainer，敌人生成 + battle\_over 信号）
* BaseClickedButton 新增 buff\_effect 数组 + buff\_effect\_applied 信号
* BaseEnemy 新增 enemy\_died 信号
* 文档重写：GDD.md 精简为类概述+方法清单，TODO.md 对齐实现状态
* 新增 docs/log.md（本文件）
* 修复：BuffEmitter connect/disconnect 空指针防护，battle\_overd→battle\_over 重命名，\_exit\_build 对称断连+停 Timer，\_enter\_battle 防重复连接

## 2026-06-22

* BuffEffect Resource 创建（Target 枚举 + prop + duration\_waves）
* 队友关卡模块合入（level.gd / level\_loader.gd）
* 测试场景与 UI 声明

## 2026-06-21

* BaseClickedButton + BaseEnemy 基类实现
* 敌人鼠标光标精灵
* 命名/分支/Commit 规范文档

## 2026-06-20

* Godot 4.7 项目初始化

