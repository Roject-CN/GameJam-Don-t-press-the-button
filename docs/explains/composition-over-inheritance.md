# 为什么 DefenceManager 不用继承 BuffContainer？

> 组合优于继承（Composition over Inheritance）

## 1. 语义错误 — IS-A vs HAS-A

`DefenceManager` **不是一个** `BuffContainer`。它是一个防御设施管理器，只是恰好需要 buff 路由能力。用继承表达 "管理者是一种 Buff 容器" 扭曲了类型的语义，让阅读代码的人困惑。

```
继承:  DefenceManager IS A BuffContainer        ← 语义错误
组合:  DefenceManager HAS A BuffContainer        ← 语义正确
```

## 2. 单继承槽位被永久占用

GDScript（以及 Godot Object 系统）只支持单继承。`extends BuffContainer` 会永久占据唯一的父类槽位。如果将来 `DefenceManager` 需要继承其他基类（例如一个通用的 `BaseManager` 或带有编辑器集成功能的 Node 扩展），`BuffContainer` 会挡在路上。

## 3. 接口污染 — 暴露不应公开的内部细节

继承会将父类的所有 public/protected 成员全部暴露：


| 暴露的成员                        | 问题                                       |
| --------------------------------- | ------------------------------------------ |
| `active_buffs: Array[BuffEffect]` | 外部可以直接操作内部数组，绕过管理器       |
| `buff_applied` 信号               | 变成了 DefenceManager 的公开信号，语义混乱 |
| `buff_expired` 信号               | 同上                                       |
| `buffs_changed` 信号              | 同上                                       |
| `apply_buff()` / `remove_buff()`  | 外部可以直接调，破坏管理器的封装           |
| `target_type`                     | 外部可以修改，导致 buff 路由错乱           |

组合模式下，`buff_container` 是内部成员，外部只能通过 `defense_manager.buff_container` 访问（且只在 `BuffEmitter` 一路使用），其余接口完全不暴露。

## 4. 脆弱基类问题（Fragile Base Class）

`BuffContainer._ready()` 已经有行为逻辑：

```gdscript
func _ready() -> void:
    if not target_type:
        print(self.name + "还未设置好相应的target_type")
```

如果将来 `BuffContainer` 增加更多 `_ready` / `_process` / `_physics_process` 行为，会与 `DefenceManager` 产生隐式耦合。组合模式下，`BuffContainer` 是一个独立的子节点，它的生命周期行为不会渗透到 `DefenceManager`。

## 5. 测试与替换困难

继承把 buff 行为焊死在类型层级中。组合模式下：

- 单元测试时可以轻松将 `buff_container` 替换为 mock 对象
- 如果将来需要不同的 buff 路由策略，只需替换成员对象，无需修改类层级

## 实际调用链路

```
BuffEmitter._on_buff_effect_applied(BuffEffect)
  → _get_container_for(DEFENSE)
    → return defense_manager.buff_container    ← 穿透到组合成员
      → buff_container.apply_buff(effect)      ← 标准 BuffContainer 行为
```

`DefenceManager` 通过持有 `buff_container: BuffContainer` 成员（组合）获得 buff 路由能力，保持类型语义清晰、接口干净、层级灵活。
