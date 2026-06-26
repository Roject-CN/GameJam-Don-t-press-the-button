# Buff 系统审查大纲

> 当前状态：框架完成，可游玩。待进一步调整。

---

## 架构总览

```
BuffEffect (Resource, 抽象基类)
  ├── PropertyBuffEffect  ← 覆盖 90% 场景
  └── [未来] 自定义效果子类
  
BuffContainer (Node2D, 存储 + 路由)
  ├── EnemyContainer.buff_container   (target=ENEMY)
  ├── DefenceManager.buff_container   (target=DEFENSE)
  └── PlayerContainer.buff_container  (target=PLAYER)

BuffEmitter (Node2D, 按钮→容器 路由)
  └── tick_all_waves() → GlobalManager 波次结束时调用
```

## 运行链路

```
按钮点击
  → BuffEmitter.duplicate → BuffContainer 存储 + init
    → buff_applied → 对应容器 _on_buff_applied
      → 遍历所有实体 effect.apply()
    → 新实体注册时自动 apply 当前所有活跃 buff

波次结束
  → GlobalManager → BuffEmitter.tick_all_waves()
    → BuffContainer.tick_wave()
      → 过期 buff 发射 buff_removed
        → 对应容器 → effect.remove() 还原属性
```

---

## 文件清单

### 核心 Buff 层

| 文件 | 操作 | 要点 |
|---|---|---|
| `scripts/buffs/buff_effect.gd` | 修改 | 抽象基类，`apply(target: Object)` / `remove(target: Object)` 虚方法，删 `prop`，加 `@export_multiline description` |
| `scripts/buffs/property_buff_effect.gd` | **新建** | 策略子类，ADD/MULTIPLY/SET 三种运算，`@export_enum` 下拉选属性，`_modified: Dictionary` 存原始值用于还原 |
| `scripts/buffs/buff_container.gd` | 修改 | 加 `_active_buffs` 存储、`tick_wave()` 过期、`buff_removed` 信号、`get_active_buffs()` |
| `scripts/buffs/buff_emitter.gd` | 修改 | 加 `tick_all_waves()` 门面方法 |

### 容器消费层

| 文件 | 操作 | 要点 |
|---|---|---|
| `scripts/players/player_container.gd` | 修改 | `current_lives` 加 setter（自动发射 `life_lost` + `lives_changed`），`_on_buff_applied` → `effect.apply(self)`，连接 `buff_removed` |
| `scripts/enemies/enemy_container.gd` | 修改 | 连接 `buff_applied`/`buff_removed`，遍历子 BaseEnemy apply/remove，`register_enemy()`/`enemies_spawn()` 新敌人自动 apply 活跃 buff |
| `scripts/defenses/defence_manager.gd` | 修改 | 连接 `buff_applied`/`buff_removed`，遍历 `placed_defenses` apply/remove，`confirm_placement()` 新防御 apply，`remove_defence()` 前 remove |

### 集成层

| 文件 | 操作 | 要点 |
|---|---|---|
| `scripts/global_manager.gd` | 修改 | `_on_all_enemies_defeated()` 中调用 `buff_emitter.tick_all_waves()` |
| `scripts/defenses/window_defense.gd` | 修改 | `_remaining` → `_used`（buf 改 `lure_count` 后实时生效），`_on_lure()` 加 `taunt_resistance` 抵抗判定 |
| `scripts/uis/hud/hud.gd` | 修改 | `life_lost` → `lives_changed`，回血也能刷新 UI |
| `scripts/debug/debug_buff_panel.gd` | **新建** | CanvasLayer 实时调试面板，合并同类 buff 显示数量 |

### 场景

| 文件 | 操作 | 要点 |
|---|---|---|
| `scenes/levels/test_level_0.tscn` | 修改 | 添加 11 个测试按钮（每按钮挂一种 buff）+ DebugBuffPanel 节点 |

---

## Buff 资源清单（11 个）

| 文件 | 目标 | 属性 | 运算 | 值 | 持续 |
|---|---|---|---|---|---|
| `failure_effect.tres` | PLAYER | current_lives | ADD | -1 | 永久 |
| `player_gain_life.tres` | PLAYER | current_lives | ADD | +1 | 永久 |
| `player_lose_fragments.tres` | PLAYER | fragments | ADD | -30 | 永久 |
| `enemy_speed_up.tres` | ENEMY | speed | MULTIPLY | 1.5 | 3 波 |
| `enemy_slow_down.tres` | ENEMY | speed | MULTIPLY | 0.5 | 3 波 |
| `enemy_health_up.tres` | ENEMY | health | ADD | +3 | 3 波 |
| `enemy_more_clicks.tres` | ENEMY | click_times | ADD | +2 | 3 波 |
| `enemy_taunt_resist.tres` | ENEMY | taunt_resistance | ADD | +0.3 | 3 波 |
| `defense_fire_rate_up.tres` | DEFENSE | fire_rate | MULTIPLY | 0.5 | 3 波 |
| `defense_damage_up.tres` | DEFENSE | damage | ADD | +2 | 3 波 |
| `defense_lure_up.tres` | DEFENSE | lure_count | ADD | +3 | 3 波 |

---

## 已知限制

1. **两个 buff 修改同一属性**：任意顺序移除时，还原值可能不准（game jam 范围可接受）
2. **`lure_count` buff 对 `_used`**：buff 改 `lure_count` 后 `_used` 不重置，剩余 = 新上限 - 旧消耗（设计如此）
3. **`damage`/`fire_rate` 对 WindowDefense 不适用**：容器遍历时 `property_name in target` 静默跳过，不会报错（但有 push_error 提醒）
4. **永久 buff 累积**：`duration_waves=0` 的 buff 永不消失，多次点击会叠加

---

## 待审查项

- [ ] ENEMY / DEFENSE 容器是否应该只对新实体 apply（而非遍历全部已有实体）
- [ ] `duration_waves=0` 永久 buff 是否需要某种清理机制
- [ ] `max_lives` 和 `fragments` 尚未实际消费（buff 生效但无 UI/逻辑联动）
- [ ] `current_lives` setter 在 `v > current_lives`（回血）时不发 `life_lost`，是否需要 `life_gained` 信号
- [ ] 是否需要 `stacking_type`（同类 buff 覆盖/叠加/取最大）
- [ ] `PropertyBuffEffect.operation = SET` 是否合理（覆盖后无法还原中间变化）
