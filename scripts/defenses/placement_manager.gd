extends Node2D
class_name PlacementManager

## 简单测试放置系统 — 按键选防御 + ghost 跟随 + 点击放置

@export var stage_manager: StageManager
@export var defense_container: DefenseContainer

const turret_scene := preload("res://scenes/defenses/turret_defense.tscn")
const phishing_scene := preload("res://scenes/defenses/window_defense.tscn")

var _ghost: BaseDefense = null


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			_select(turret_scene)
		elif event.keycode == KEY_2:
			_select(phishing_scene)

	if event.is_action_pressed("left_mouse") and _ghost:
		if _ghost:
			_try_place()


func _select(scene: PackedScene) -> void:
	if _ghost:
		_ghost.queue_free()

	_ghost = scene.instantiate() as BaseDefense
	_ghost.is_placed = false
	_ghost.global_position = get_global_mouse_position()
	add_child(_ghost)


func _try_place() -> void:
	#if not stage_manager.spend_fragments(_ghost.cost):
		#return

	_ghost.place()
	_ghost.reparent(defense_container)
	_ghost = null
