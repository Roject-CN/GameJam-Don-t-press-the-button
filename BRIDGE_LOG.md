# BRIDGE_LOG.md — 桌面/手机工作交接日志

## 用途

此文件用于桌面端 VS Code Claude Code 与手机端 QQ Bot 之间
的工作交接。双方通过此日志了解对方的最新进展，无需
互相复制完整对话历史。

## 工作流

### 桌面端（你在电脑前）
完成一轮工作后，使用 `/bridge-update` 技能更新此日志。

### 手机端（你在外面）
通过 QQ 发送 `/bridge <消息>` 时，Bot 会：
1. 先读取此文件末尾，获知桌面端最新进展
2. 将你的指令发给 Claude 处理
3. 完成后，将指令和结果追加到此文件

### 桌面端再次接手
回到电脑前，使用 `/bridge-log` 技能查看手机端工作了什么。

---

### 【手机】 2026-06-23 11:51 ~ 12:56 工作摘要

本轮手机端共 17 轮对话，主要工作：
- 浏览项目文件，了解工程现状（只读）
- **Buff 系统方案讨论**：确定 BuffEffect 作为 Resource 挂在按钮上，采用 BuffEmitter + BuffContainer 去中心化方案替代集中式 SignalBus/GameState；讨论了属性重算机制（信号触发 vs 每帧查询 vs 惰性缓存）
- **游戏阶段流程讨论**：决定准备阶段和调整阶段合并为同一状态，战斗期间可部署防御，增加结算状态（胜利/失败）；完整方案写入 TODO.md
- 确认队友的关卡模块已合入

---

### 【桌面】 2026-06-23 约 14:00

**做了什么**：
- 重写 GDD.md：精简为每个类一行概述 + 方法清单 + 场景结构，移除所有不存在的类描述
- 重写 TODO.md：修正"已完成"列表，SignalBus/GameState/FailureButton/DebuffButton 退回"下一步"
- git pull 拉取远程，解决 TODO.md 合并冲突（保留本地版本，去除队友占位话）
- main.tscn 实际有 3 个 BaseButton + 1 个 BaseEnemy（更新 GDD 以匹配）

**下一步**：
- TODO.md 合并冲突已修但需手动 `git commit` 完成 merge
- 手机端讨论的 Buff 系统方案细节已不在 TODO.md 中（被精简），如需恢复可回看 BRIDGE_LOG 历史

---

### 【桌面】 2026-06-23 约 15:00

**做了什么**：
- 实现 BuffContainer（apply_buff/remove_buff/_recalc + 信号）
- 实现 BuffEmitter（连接按钮信号 → 路由到 BuffContainer，connect_all/disconnect_all）
- 实现 StageManager FSM（BUILD/BATTLE/SETTLE 三阶段，enter/exit/process 钩子，@export 直接拿模块引用调接口）
- 实现 FailureButton（调 StageManager.lose_life()）
- BaseEnemy 接入 BuffContainer（bind_container / _on_buffs_changed）
- start_wave/end_wave 改名 start_battle/end_battle

**下一步**：
- 敌人生成放在 EnemyContainer 内部，配合 wave_resource（搭载每波敌人类型+数量）
- StageManager 各阶段钩子继续填充实际逻辑

