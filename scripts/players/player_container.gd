extends BuffContainer
class_name PlayerContainer

## 玩家容器 — 接收 PLAYER 目标的 BuffEffect，处理扣命等效果

signal life_lost(amount: int)

func _ready() -> void:
	target_type = BuffEffect.Target.PLAYER

func apply_buff(effect: BuffEffect) -> void:
	super(effect)
	var loss := int(effect.prop)
	if loss > 0:
		life_lost.emit(loss)


func remove_buff(effect: BuffEffect) -> void:
	super(effect)
