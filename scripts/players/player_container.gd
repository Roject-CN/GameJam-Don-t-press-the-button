extends Node2D
class_name PlayerContainer

## 玩家容器 — 接收 PLAYER 目标的 BuffEffect，处理扣命等效果
## 采用组合持有 BuffContainer，通过 buff_applied 信号驱动 life_lost

signal life_lost(amount: int)

## 内部 Buff 容器（组合代替继承）
var buff_container: BuffContainer


func _ready() -> void:
	buff_container = BuffContainer.new()
	buff_container.target_type = BuffEffect.Target.PLAYER
	buff_container.name = "PlayerBuffContainer"
	add_child(buff_container)

	buff_container.buff_applied.connect(_on_buff_applied)


func _on_buff_applied(effect: BuffEffect) -> void:
	var loss := int(effect.prop)
	if loss > 0:
		life_lost.emit(loss)
