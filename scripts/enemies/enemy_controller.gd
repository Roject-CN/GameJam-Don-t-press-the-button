extends Node2D
class_name EnemyController

## 敌人管理器 — 波次时序 + 存活计数 + 信号转发 + ENEMY Buff 路由

@export var wave_data: WaveData
@export var enemy_catalog: EnemyCatalog
@export var wave_clear_fragments: int = 50
@export var mount_node: Node2D
@export var nav_tile_map: TileMapLayer

var buff_container: BuffContainer
var enemies: Array[BaseEnemy] = []

var total_spawned: int = 0
var enemies_killed: int = 0:
	set(v):
		enemies_killed = v
		enemies_killed_count_changed.emit(enemies_killed)
		if total_spawned > 0 and enemies_killed >= total_spawned:
			all_enemies_defeated.emit()

var enemies_alive: int = 0
var total_waves: int:
	get:
		if not wave_data: return 0
		var m := 0
		for e in wave_data.entries:
			if e.wave_index > m: m = e.wave_index
		return m

var total_enemy: int:
	get:
		return wave_data.entries.size() if wave_data else 0

var current_wave: int = 0
var _wave_timer: float = 0.0
var _spawned: Array[int] = []
var _active: bool = false

signal all_enemies_defeated
signal enemies_killed_count_changed(count: int)
signal wave_changed(wave: int)


func _ready() -> void:
	buff_container = BuffContainer.new()
	buff_container.target_type = BuffEffect.Target.ENEMY
	buff_container.name = "EnemyBuffContainer"
	buff_container.buff_applied.connect(_on_buff_applied)
	buff_container.buff_removed.connect(_on_buff_removed)
	add_child(buff_container)

	if nav_tile_map:
		_bake_navigation()


func _bake_navigation() -> void:
	var tile_size: Vector2 = Vector2(nav_tile_map.tile_set.tile_size) * nav_tile_map.scale
	var half: Vector2 = tile_size / 2.0
	var tile_set: Dictionary = {}
	for cell: Vector2i in nav_tile_map.get_used_cells():
		tile_set[cell] = true

	# 贪心合并为最大矩形
	var rects: Array[Rect2] = []
	var visited: Dictionary = {}
	for cell: Vector2i in nav_tile_map.get_used_cells():
		if visited.get(cell, false): continue
		var max_x: int = cell.x
		while tile_set.get(Vector2i(max_x + 1, cell.y), false): max_x += 1
		var max_y: int = cell.y
		var extend: bool = true
		while extend:
			for x: int in range(cell.x, max_x + 1):
				if not tile_set.get(Vector2i(x, max_y + 1), false): extend = false; break
			if extend: max_y += 1
		for x: int in range(cell.x, max_x + 1):
			for y: int in range(cell.y, max_y + 1):
				visited[Vector2i(x, y)] = true
		var tl: Vector2 = nav_tile_map.to_global(nav_tile_map.map_to_local(Vector2i(cell.x, cell.y))) - half
		var sz: Vector2 = Vector2((max_x - cell.x + 1) * tile_size.x, (max_y - cell.y + 1) * tile_size.y)
		rects.append(Rect2(tl, sz))

	# 每个矩形注册为独立 NavigationRegion，避免 outline 共享边冲突
	for i: int in range(rects.size()):
		var r: Rect2 = rects[i]
		var poly := NavigationPolygon.new()
		poly.add_outline(PackedVector2Array([
			r.position, r.position + Vector2(r.size.x, 0),
			r.position + r.size, r.position + Vector2(0, r.size.y),
		]))
		poly.make_polygons_from_outlines()
		var region := NavigationRegion2D.new()
		region.name = "NavRect_%d" % i
		region.navigation_polygon = poly
		add_child(region)

	print("EnemyController: baked %d tiles → %d regions" % [nav_tile_map.get_used_cells().size(), rects.size()])


func _process(delta: float) -> void:
	if not _active: return
	_wave_timer += delta
	_check_spawns()


func _on_buff_applied(effect: BuffEffect) -> void:
	for enemy in enemies:
		if is_instance_valid(enemy): effect.apply(enemy)


func _on_buff_removed(effect: BuffEffect) -> void:
	for enemy in enemies:
		if is_instance_valid(enemy): effect.remove(enemy)


func _apply_active_buffs_to_enemy(enemy: BaseEnemy) -> void:
	for buff in buff_container.get_active_buffs(): buff.apply(enemy)


func start_wave(wave_index: int) -> void:
	current_wave = wave_index
	_wave_timer = 0.0
	_spawned.clear()
	_active = true
	wave_changed.emit(current_wave)


func stop_wave() -> void: _active = false
func is_wave_active() -> bool: return _active


func all_spawned() -> bool:
	if not wave_data: return true
	return _spawned.size() >= wave_data.get_wave_entries(current_wave).size()


func _check_spawns() -> void:
	if not wave_data: return
	var entries := wave_data.get_wave_entries(current_wave)
	for i in range(entries.size()):
		if i in _spawned: continue
		if entries[i].time_offset > _wave_timer: continue
		_spawn(entries[i])
		_spawned.append(i)


func _spawn(entry: WaveEntry) -> void:
	var scene := enemy_catalog.get_scene(entry.enemy_type) if enemy_catalog else null
	if not scene:
		push_error("EnemyController: unknown enemy_type '%s'" % entry.enemy_type)
		return

	var enemy := scene.instantiate() as BaseEnemy
	if not enemy: return

	var path_line_node: Line2D = null
	if not entry.path_line.is_empty():
		path_line_node = _find_marker(entry.path_line) as Line2D

	enemy.global_position = path_line_node.points[0] if path_line_node and path_line_node.points.size() > 0 else Vector2.ZERO

	var parent := mount_node if mount_node else self
	parent.add_child(enemy)
	enemy.enemy_died.connect(_on_enemy_died.bind(enemy))
	enemies.append(enemy)
	total_spawned += 1
	enemies_alive += 1

	var econfig := enemy_catalog.get_config(entry.enemy_type) if enemy_catalog else null
	if not econfig: econfig = EnemyConfig.new()
	enemy.setup(econfig, path_line_node)
	if nav_tile_map:
		enemy.set_nav_grid(nav_tile_map)

	_apply_active_buffs_to_enemy(enemy)


func _on_enemy_died(which: BaseEnemy) -> void:
	enemies_killed += 1
	enemies_alive -= 1
	enemies.erase(which)


@warning_ignore("shadowed_variable_base_class")
func _find_marker(name: String) -> Node2D:
	var root := mount_node if mount_node else get_parent()
	if not root: return null
	return root.find_child(name, true, false) as Node2D
