extends BaseEnemy
class_name SplitterEnemy

## 分裂者 — 死后生成小型子体

@export var split_count: int = 2
@export var split_mini_scene: PackedScene

var _alive_children: int = 0


func _die() -> void:
	_dying = true

	visible = false
	if area_2d:
		area_2d.set_deferred("monitoring", false)
		area_2d.set_deferred("monitorable", false)

	var child_health := maxi(1, health / 2)
	var child_speed := speed * 0.7

	for i in range(split_count):
		_spawn_child(i, child_speed, child_health)

	if _alive_children <= 0:
		enemy_died.emit()
		call_deferred("queue_free")


func _spawn_child(_index: int, child_speed: float, child_health: int) -> void:
	if not split_mini_scene:
		return

	var mini := split_mini_scene.instantiate() as BaseEnemy
	if not mini:
		return

	mini.global_position = global_position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
	mini.speed = child_speed
	mini.health = child_health
	mini.click_times = 1

	if path_line:
		mini.path_line = path_line
		mini._path_total_length = mini._build_segments(path_line.points)
		mini._path_progress = mini._closest_point_on_path(mini.global_position)

	mini._setup_done = true

	var parent_node := get_parent()
	if parent_node:
		parent_node.add_child(mini)
	else:
		add_child(mini)

	mini.enemy_died.connect(_on_child_died.bind(mini))
	_alive_children += 1


func _on_child_died(_which: BaseEnemy) -> void:
	_alive_children -= 1
	if _alive_children <= 0:
		enemy_died.emit()
		call_deferred("queue_free")
