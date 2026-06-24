extends BuffContainer
class_name DefenseContainer

## 防御容器 — 存放所有已放置的防御工事，接收 DEFENSE 目标的 Buff

func _ready() -> void:
	target_type = BuffEffect.Target.DEFENSE


func apply_buff(effect: BuffEffect) -> void:
	super(effect)


func remove_buff(effect: BuffEffect) -> void:
	super(effect)
