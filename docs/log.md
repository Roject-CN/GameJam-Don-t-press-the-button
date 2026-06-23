# 更新日志 — "别按那个键"

## 2026-06-23
- 实现 BuffContainer + BuffEmitter（Buff 路由链路）
- 实现 StageManager FSM（BUILD/BATTLE/SETTLE 三阶段状态机）
- 实现 EnemyContainer（继承 BuffContainer，敌人生成 + battle_over 信号）
- BaseClickedButton 新增 buff_effect 数组 + buff_effect_applied 信号
- BaseEnemy 新增 enemy_died 信号
- 文档重写：GDD.md 精简为类概述+方法清单，TODO.md 对齐实现状态
- 新增 docs/log.md（本文件）
- 修复：BuffEmitter connect/disconnect 空指针防护，battle_overd→battle_over 重命名，_exit_build 对称断连+停 Timer，_enter_battle 防重复连接

## 2026-06-22
- BuffEffect Resource 创建（Target 枚举 + prop + duration_waves）
- 队友关卡模块合入（level.gd / level_loader.gd）
- 测试场景与 UI 声明

## 2026-06-21
- BaseClickedButton + BaseEnemy 基类实现
- 敌人鼠标光标精灵
- 命名/分支/Commit 规范文档

## 2026-06-20
- Godot 4.7 项目初始化
