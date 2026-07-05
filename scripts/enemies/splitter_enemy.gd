extends BaseEnemy
class_name SplitterEnemy

## 分裂者 — 死后生成小型子体，子体死完才真正结束

@export var split_count: int = 2
@export var split_mini_scene: PackedScene

var _alive_children: int = 0
var _controller: EnemyController


func _ready() -> void:
	super._ready()
	_controller = _find_controller()


func _find_controller() -> EnemyController:
	var node := get_parent()
	while node:
		for child in node.get_children():
			if child is EnemyController:
				return child
		node = node.get_parent()
	return null


func _die() -> void:
	_dying = true
	visible = false
	if area_2d:
		area_2d.set_deferred("monitoring", false)
		area_2d.set_deferred("monitorable", false)

	var child_health := maxi(1, health / 2)
	var child_speed := speed * 0.7

	for i in range(split_count):
		_spawn_child(child_speed, child_health)

	if _alive_children <= 0:
		enemy_died.emit()
		call_deferred("queue_free")


func _spawn_child(child_speed: float, child_health: int) -> void:
	if not split_mini_scene:
		return

	var mini := split_mini_scene.instantiate() as BaseEnemy
	if not mini: return

	mini.global_position = global_position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
	mini.speed = child_speed
	mini.health = child_health
	mini.click_times = 1

	# 继承路径
	if path_line:
		mini.path_line = path_line
		mini._path_total_length = mini._build_segments(path_line.points)
		mini._path_progress = mini._closest_point_on_path(mini.global_position)

	mini._setup_done = true

	# 挂载到父节点同一容器
	var parent_node := get_parent()
	if parent_node:
		parent_node.add_child(mini)
	else:
		add_child(mini)

	# 注册到 EnemyController — 子体参与存活计数
	if _controller:
		_controller.total_spawned += 1
		_controller.enemies_alive += 1
		_controller.enemies.append(mini)
		mini.enemy_died.connect(_controller._on_enemy_died.bind(mini))

		# 继承导航网格
		var nav_tile: TileMapLayer = _controller.nav_tile_map
		if nav_tile:
			mini.set_nav_grid(nav_tile)

	mini.enemy_died.connect(_on_child_died)
	_alive_children += 1


func _on_child_died() -> void:
	_alive_children -= 1
	if _alive_children <= 0:
		enemy_died.emit()
		call_deferred("queue_free")
