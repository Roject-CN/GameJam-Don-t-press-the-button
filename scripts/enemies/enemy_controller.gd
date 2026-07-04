extends Node2D
class_name EnemyController

## 敌人管理器 — 波次时序 + 存活计数 + 信号转发 + ENEMY Buff 路由

# ── 配置 ──
@export var wave_data: WaveData
@export var enemy_catalog: EnemyCatalog
@export var wave_clear_fragments: int = 50

## 敌人挂载节点 — 生成的敌人作为此节点的子节点添加
@export var mount_node: Node2D

## 导航网格 TileMapLayer — 定义可行走区域
@export var nav_tile_map: TileMapLayer

# ── Buff ──
var buff_container: BuffContainer

# ── 敌人引用 ──
var enemies: Array[BaseEnemy] = []

# ── 属性 ──
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
		if not wave_data:
			return 0
		var m := 0
		for e in wave_data.entries:
			if e.wave_index > m:
				m = e.wave_index
		return m

var total_enemy: int:
	get:
		return wave_data.entries.size() if wave_data else 0

var current_wave: int = 0

# ── 波次运行时状态 ──
var _wave_timer: float = 0.0
var _spawned: Array[int] = []
var _active: bool = false

# ── 信号 ──
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


func _process(delta: float) -> void:
	if not _active:
		return
	_wave_timer += delta
	_check_spawns()


# ── Buff 逻辑 ──

func _on_buff_applied(effect: BuffEffect) -> void:
	for enemy in enemies:
		if is_instance_valid(enemy):
			effect.apply(enemy)


func _on_buff_removed(effect: BuffEffect) -> void:
	for enemy in enemies:
		if is_instance_valid(enemy):
			effect.remove(enemy)


func _apply_active_buffs_to_enemy(enemy: BaseEnemy) -> void:
	for buff in buff_container.get_active_buffs():
		buff.apply(enemy)


# ── 波次控制 ──

func start_wave(wave_index: int) -> void:
	current_wave = wave_index
	_wave_timer = 0.0
	_spawned.clear()
	_active = true
	wave_changed.emit(current_wave)


func stop_wave() -> void:
	_active = false


func is_wave_active() -> bool:
	return _active


func all_spawned() -> bool:
	if not wave_data:
		return true
	var entries := wave_data.get_wave_entries(current_wave)
	return _spawned.size() >= entries.size()


# ── 内部逻辑 ──

func _check_spawns() -> void:
	if not wave_data:
		return
	var entries := wave_data.get_wave_entries(current_wave)
	for i in range(entries.size()):
		if i in _spawned:
			continue
		var entry := entries[i]
		if entry.time_offset > _wave_timer:
			continue
		_spawn(entry)
		_spawned.append(i)


func _spawn(entry: WaveEntry) -> void:
	var scene := enemy_catalog.get_scene(entry.enemy_type) if enemy_catalog else null
	if not scene:
		push_error("EnemyController: unknown enemy_type '%s'" % entry.enemy_type)
		return

	var enemy := scene.instantiate() as BaseEnemy
	if not enemy:
		return

	var path_line_node: Line2D = null
	if not entry.path_line.is_empty():
		path_line_node = _find_marker(entry.path_line) as Line2D

	if path_line_node and path_line_node.points.size() > 0:
		enemy.global_position = path_line_node.points[0]
	else:
		enemy.global_position = Vector2.ZERO

	# 先挂载到场景树 + 注册信号 + 登记计数（在 setup 之前，防止 setup 触发死亡时信号丢失）
	var parent := mount_node if mount_node else self
	parent.add_child(enemy)
	enemy.enemy_died.connect(_on_enemy_died.bind(enemy))
	enemies.append(enemy)
	total_spawned += 1
	enemies_alive += 1

	# setup 可能触发 free_self（如 click_times=0）
	var econfig := enemy_catalog.get_config(entry.enemy_type) if enemy_catalog else null
	if not econfig:
		econfig = EnemyConfig.new()
	enemy.setup(econfig, path_line_node)
	if nav_tile_map:
		print("EMYCONTROLLER:nav loaded")
		enemy.set_nav_grid(nav_tile_map)

	# setup 后注入活跃 buff；若 setup 中已死亡，enemies 列表中已移除，buff 会跳过
	_apply_active_buffs_to_enemy(enemy)


func _on_enemy_died(which: BaseEnemy) -> void:
	enemies_killed += 1
	enemies_alive -= 1
	enemies.erase(which)


@warning_ignore("shadowed_variable_base_class")
func _find_marker(name: String) -> Node2D:
	var root := mount_node if mount_node else get_parent()
	if not root:
		return null
	return root.find_child(name, true, false) as Node2D
