extends Node2D
class_name BaseDefense

## 防御工事基类 — ghost 预览 + 放置 + 子类覆写

@export var cost: int = 0
@export var defense_name: String = ""

var is_placed: bool = false


@onready var area_node: Area2D = $Area


func _process(_delta: float) -> void:
	if not is_placed:
		_ghost()

func _ghost() -> void:
	global_position = get_global_mouse_position()
	modulate.a = 0.5

func place() -> void:
	is_placed = true
	modulate.a = 1.0
	_on_placed()


func _on_placed() -> void:
	pass
