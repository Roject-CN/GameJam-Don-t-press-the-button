extends Node2D
class_name BuffContainer

## Buff 容器 — 纯路由节点，接收 BuffEffect 并发射信号
## 组合在各管理器中（非继承），BuffEmitter 直接路由到此

var target_type: BuffEffect.Target

signal buff_applied(effect: BuffEffect)


func apply_buff(effect: BuffEffect) -> void:
	buff_applied.emit(effect)
