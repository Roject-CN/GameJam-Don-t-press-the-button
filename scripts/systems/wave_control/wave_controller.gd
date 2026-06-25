extends Node2D
class_name WaveController

## 波次控制器 — 按时间戳生成敌人，传递配置和目标给 BaseEnemy

@export var wave_data: WaveData

var total_waves: int:
	get:
		if not wave_data:
			return 0
		var m := 0
		for e in wave_data.entries:
			if e.wave_index > m:
				m = e.wave_index
		return m

@export var wave_clear_fragments: int = 50
@export var enemy_catalog: EnemyCatalog
@export var enemy_container: EnemyContainer

var _current_wave: int = 0
var _wave_timer: float = 0.0
var _spawned: Array[int] = []
var _active: bool = false


func _process(delta: float) -> void:
	if not _active:
		return
	_wave_timer += delta
	_check_spawns()


func start_wave(wave_index: int) -> void:
	_current_wave = wave_index
	_wave_timer = 0.0
	_spawned.clear()
	_active = true


func stop_wave() -> void:
	_active = false
	_current_wave = 0


func is_wave_active() -> bool:
	return _active


## 当前波次是否已生成全部条目
func all_spawned() -> bool:
	if not wave_data:
		return true
	var entries := wave_data.get_wave_entries(_current_wave)
	return _spawned.size() >= entries.size()


func _check_spawns() -> void:
	if not wave_data:
		return
	var entries := wave_data.get_wave_entries(_current_wave)
	for i in range(entries.size()):
		if i in _spawned:
			continue
		var entry := entries[i]
		if entry.time_offset > _wave_timer:
			continue

		_spawn(entry)
		_spawned.append(i)


func _spawn(entry: WaveEntry) -> void:
	if not enemy_container:
		push_error("WaveController: enemy_container is null")
		return

	var scene := enemy_catalog.get_scene(entry.enemy_type) if enemy_catalog else null
	if not scene:
		push_error("WaveController: unknown enemy_type '%s'" % entry.enemy_type)
		return

	var enemy := scene.instantiate() as BaseEnemy
	if not enemy:
		return

	var spawn_node := _find_marker(entry.spawn_point)
	if spawn_node:
		enemy.global_position = spawn_node.global_position
	else:
		enemy.global_position = Vector2.ZERO

	var target_pos := enemy.global_position
	if not entry.target_point.is_empty():
		var target_node := _find_marker(entry.target_point)
		if target_node:
			target_pos = target_node.global_position


	var econfig := enemy_catalog.get_config(entry.enemy_type) if enemy_catalog else null
	if not econfig:
		econfig = EnemyConfig.new()
	enemy.setup(econfig, target_pos)

	enemy_container.register_enemy(enemy)


@warning_ignore("shadowed_variable_base_class")
func _find_marker(name: String) -> Node2D:
	var parent := get_parent()
	if not parent:
		return null
	return parent.find_child(name, true, false) as Node2D
