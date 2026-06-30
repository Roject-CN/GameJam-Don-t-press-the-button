extends Node2D
class_name BaseEnemy

## 敌人基类 — 完备状态机寻路 + 松散引诱 API
##
## 移动状态：
##   PATROL  — 沿 Line2D 路径前进；前方受阻则 A* 绕行进入 DETOUR
##   DETOUR  — 已偏离路径，沿 A* 绕行/直线走回最近路径点后回归 PATROL
##   LURED   — 被引诱，向引诱源目标移动→点击按钮
##
## 引诱模式（LURED 子状态）：
##   NONE     — 未被引诱
##   SINGLE   — 单击引诱，点击一次后回到路径
##   REPEATED — 持续引诱，反复点击直到 click_times 耗尽或源释放

# ── 枚举 ──
enum MoveState { PATROL, DETOUR, LURED }
enum LureMode { NONE, SINGLE, REPEATED }

# ── 节点 ──
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var area_2d: Area2D = $Area2D

# ── 属性 ──
@export var speed: float = 200.0
@export var health: int = 1
@export var click_times: int = 2
@export var taunt_resistance: float = 0.0
@export var click_range: float = 50.0

# ── 外部注入 ──
var config: EnemyConfig = null
var path_line: Line2D = null
var nav_tile_map: TileMapLayer = null

# ── 移动状态机 ──
var _move_state: MoveState = MoveState.PATROL
var _lure_mode: LureMode = LureMode.NONE
var _lure_source: WeakRef = null        # 当前引诱源（WeakRef）
var _lure_target: Vector2 = Vector2.INF
var _lure_queue: Array[Dictionary] = [] # [{source: WeakRef, target: Vector2, repeated: bool}]

# ── PATROL 状态数据 ──
var _path_progress: float = 0.0
var _path_total_length: float = 0.0
var _line_segments: Array[Dictionary] = []

# ── DETOUR 状态数据 ──
var _detour: PackedVector2Array = []    # A* 绕行路径（DETOUR 和 LURED 共用）
var _detour_idx: int = 0
var _rejoin_progress: float = 0.0       # DETOUR 绕行终点的路径进度

# ── 导航网格 ──
var _walkable: Dictionary = {}
var _tile_size: Vector2 = Vector2.ZERO

# ── 点击状态 ──
var _clicking: bool = false
var _click_btn: BaseClickedButton = null  # 当前点击的按钮（动画期间持有）
var _click_retry: float = 0.0
const CLICK_RETRY_INTERVAL: float = 0.5

# ── 生命状态 ──
var _setup_done: bool = false
var _dying: bool = false

signal enemy_died()


# ═══════════════════════════════════════
# 初始化
# ═══════════════════════════════════════

func _ready() -> void:
	if config:
		_apply_config()
		if path_line:
			_build_segments()
		if nav_tile_map:
			_build_walkable()
		_setup_done = true


func setup(p_config: EnemyConfig, p_path_line: Line2D) -> void:
	config = p_config
	path_line = p_path_line
	if p_path_line:
		_build_segments()
	if is_inside_tree():
		_apply_config()
		_setup_done = true


func set_nav_grid(p_tile_map: TileMapLayer) -> void:
	nav_tile_map = p_tile_map
	if nav_tile_map:
		_build_walkable()


func _apply_config() -> void:
	if not config:
		return
	speed = config.speed if config.speed > 0 else speed
	health = config.health if config.health > 0 else health
	click_times = config.click_times
	taunt_resistance = config.taunt_resistance


# ═══════════════════════════════════════
# Public API — 引诱
# ═══════════════════════════════════════

## 请求引诱本敌人。source 标识引诱来源，target 为目标世界坐标，repeated 为是否持续引诱。
## 若已被其他源引诱则排队等待，同源则更新目标与模式。
func request_lure(source: Node, target: Vector2, repeated: bool) -> void:
	if _dying:
		return
	if not is_instance_valid(source):
		return

	# 未被引诱 → 立即开始
	if _move_state != MoveState.LURED:
		_start_lure(source, target, repeated)
		return

	# 已被引诱 — 同源则更新，异源则排队
	var current_source: Node = _lure_source.get_ref() if _lure_source else null
	if current_source == source:
		_lure_target = target
		_lure_mode = LureMode.REPEATED if repeated else LureMode.SINGLE
		_detour = _find_path_astar(global_position, target)
		_detour_idx = 0
	else:
		_lure_queue.append({
			source = weakref(source),
			target = target,
			repeated = repeated,
		})


## 释放来自 source 的引诱。若当前正被该源引诱则回归路径，若在队列中则移除。
## 幂等：重复调用 / 非当前源调用均无副作用。
func release_lure(source: Node) -> void:
	if _dying:
		return

	# 正在被该源引诱 → 结束引诱，回归路径
	if is_lured_by(source):
		_end_lure()
		return

	# 在队列中 → 移除
	var i: int = _lure_queue.size() - 1
	while i >= 0:
		var entry: Dictionary = _lure_queue[i]
		var entry_source: Node = entry.source.get_ref() if entry.source else null
		if entry_source == source:
			_lure_queue.remove_at(i)
		i -= 1


## 受到一次打击，消耗 1 次 click_times。返回敌人是否仍存活（true=存活）。
func strike() -> bool:
	if _dying:
		return false
	_consume_click()
	_check_depleted()
	return not _dying


## 是否处于被引诱状态
func is_lured() -> bool:
	return _move_state == MoveState.LURED


## 是否正被指定 source 引诱
func is_lured_by(source: Node) -> bool:
	return is_lured() and _lure_source.get_ref() == source


# ═══════════════════════════════════════
# 生命周期
# ═══════════════════════════════════════

func _consume_click() -> void:
	click_times -= 1


func _check_depleted() -> void:
	if click_times <= 0 and not _dying:
		_die()


func _die() -> void:
	_dying = true
	_clicking = false
	# 若死亡时正按着按钮，先释放再播放死亡动画
	if _click_btn and is_instance_valid(_click_btn):
		_click_btn.release()
	_click_btn = null
	animation_player.play("free")
	await animation_player.animation_finished
	enemy_died.emit()
	call_deferred("queue_free")


func take_damage(amount: int) -> void:
	if _dying:
		return
	health -= amount
	if health <= 0:
		_die()


# ═══════════════════════════════════════
# 点击
# ═══════════════════════════════════════

func _try_click() -> void:
	if _dying or _clicking:
		return
	var btn: BaseClickedButton = _find_nearest_button(global_position)
	if not btn or btn.global_position.distance_to(global_position) > click_range:
		return
	_click_button(btn)


## 启动点击（非阻塞）：播放动画 + 按下按钮，动画结束时由 _on_click_anim_done 完成后续
func _click_button(btn: BaseClickedButton) -> void:
	_clicking = true
	_click_btn = btn

	animation_player.play("clicked")
	btn.press()
	# 不 await — 动画独立播放，_physics_process 继续驱动物理移动
	if not animation_player.animation_finished.is_connected(_on_click_anim_done):
		animation_player.animation_finished.connect(_on_click_anim_done, CONNECT_ONE_SHOT)


## 点击动画播完 → 释放按钮、消耗次数、决定后续状态
func _on_click_anim_done(_anim_name: StringName) -> void:
	if _dying:
		_clicking = false
		_click_btn = null
		return

	var btn := _click_btn
	_click_btn = null
	if not is_instance_valid(btn):
		_clicking = false
		return

	btn.release()
	_consume_click()
	_clicking = false

	_check_depleted()

	# 持续引诱模式 → 继续点击
	if not _dying and click_times > 0 and _lure_mode == LureMode.REPEATED:
		_click_button(btn)
		return

	# 单击引诱模式 → 结束引诱，回归路径
	if not _dying and click_times > 0:
		_end_lure()


func _find_nearest_button(pos: Vector2) -> BaseClickedButton:
	var best: BaseClickedButton = null
	var best_dist: float = INF
	for btn: Node in get_tree().get_nodes_in_group("ClickedButtons"):
		var b := btn as BaseClickedButton
		if not b:
			continue
		var d: float = b.global_position.distance_squared_to(pos)
		if d < best_dist:
			best_dist = d
			best = b
	return best


# ═══════════════════════════════════════
# 引诱 — 内部状态转换
# ═══════════════════════════════════════

## 开始引诱（内部，调用前保证当前非 LURED 状态）
func _start_lure(source: Node, target: Vector2, repeated: bool) -> void:
	_move_state = MoveState.LURED
	_lure_mode = LureMode.REPEATED if repeated else LureMode.SINGLE
	_lure_source = weakref(source)
	_lure_target = target
	_click_retry = 0.0
	_detour = _find_path_astar(global_position, target)
	_detour_idx = 0


## 结束当前引诱（内部），处理队列或回归路径
func _end_lure() -> void:
	_lure_mode = LureMode.NONE
	_lure_source = null
	_lure_target = Vector2.INF

	# 队列中有等待 → 启动下一个引诱
	if not _lure_queue.is_empty():
		var next: Dictionary = _lure_queue.pop_front()
		var next_source: Node = next.source.get_ref() if next.source else null
		if is_instance_valid(next_source):
			_start_lure(next_source, next.target, next.repeated)
			return

	# 无等待 → 回归路径
	_enter_off_path(global_position)


# ═══════════════════════════════════════
# 移动 — 主循环
# ═══════════════════════════════════════

func _physics_process(delta: float) -> void:
	if _dying or not _setup_done:
		return

	match _move_state:
		MoveState.LURED:
			_process_lured(delta)
		MoveState.DETOUR:
			_process_detour(delta)
		MoveState.PATROL:
			_process_patrol(delta)


# ── LURED：被引诱移动 ──

func _process_lured(delta: float) -> void:
	# 引诱源已失效 → 结束引诱
	if not _lure_source or not is_instance_valid(_lure_source.get_ref()):
		_end_lure()
		return

	# 有 A* 绕行 → 跟随导航点
	if not _detour.is_empty():
		_follow_detour(delta)
		return

	# 直接向引诱目标移动
	var to_target: Vector2 = _lure_target - global_position
	if to_target.length() < 4.0:
		global_position = _lure_target
		_try_click()
		return
	global_position += to_target.normalized() * speed * delta


# ── DETOUR：找回路径 ──

func _process_detour(delta: float) -> void:
	if not _detour.is_empty():
		_follow_detour(delta)
		return

	# 无绕行路径（无导航网格或 A* 失败）→ 直接向最近路径点移动
	var target: Vector2 = _pos_on_path(_rejoin_progress)
	var to_target: Vector2 = target - global_position
	if to_target.length() < 4.0:
		_path_progress = _rejoin_progress
		_move_state = MoveState.PATROL
		return
	global_position += to_target.normalized() * speed * delta


# ── PATROL：沿路径前进 ──

func _process_patrol(delta: float) -> void:
	if _path_total_length <= 0.0:
		return

	_path_progress += speed * delta

	# 到达路径终点
	if _path_progress >= _path_total_length:
		_path_progress = _path_total_length
		global_position = _pos_on_path(_path_progress)
		_click_retry -= delta
		if _click_retry <= 0.0:
			_click_retry = CLICK_RETRY_INTERVAL
			_try_click()
		return

	var next_pos: Vector2 = _pos_on_path(_path_progress)

	# 下一位置不可行走 → A* 绕行到前方可行走点
	if not _is_walkable_world(next_pos) and not _walkable.is_empty():
		var rejoin: Vector2 = _find_rejoin_point(_path_progress)
		_rejoin_progress = _closest_point_on_path(rejoin)
		_detour = _find_path_astar(global_position, rejoin)
		_detour_idx = 0
		if not _detour.is_empty():
			_move_state = MoveState.DETOUR
		else:
			global_position = next_pos
		return

	global_position = next_pos


# ── 绕行跟随（DETOUR 和 LURED 共用） ──

func _follow_detour(delta: float) -> void:
	var wp: Vector2 = _detour[_detour_idx]
	var to_wp: Vector2 = wp - global_position
	if to_wp.length() < 4.0:
		_detour_idx += 1
		if _detour_idx < _detour.size():
			return
		# 绕行完成
		_detour.clear()
		_detour_idx = 0
		match _move_state:
			MoveState.LURED:
				global_position = _lure_target
				_try_click()
			MoveState.DETOUR:
				_path_progress = _rejoin_progress
				_move_state = MoveState.PATROL
			_:
				pass
		return
	global_position += to_wp.normalized() * speed * delta


# ═══════════════════════════════════════
# 进入 DETOUR 状态 — 从当前位置找回路径
# ═══════════════════════════════════════

func _enter_off_path(from: Vector2) -> void:
	_move_state = MoveState.DETOUR
	_detour.clear()
	_detour_idx = 0

	if _path_total_length <= 0.0:
		return

	_rejoin_progress = _closest_point_on_path(from)
	var target: Vector2 = _pos_on_path(_rejoin_progress)
	var dist: float = from.distance_to(target)

	# 已在路径附近 → 直接进入 PATROL
	if dist < 4.0:
		_path_progress = _rejoin_progress
		_move_state = MoveState.PATROL
		return

	# 有导航网格 → 尝试 A* 寻路到最近点
	if not _walkable.is_empty():
		_detour = _find_path_astar(from, target)
		if not _detour.is_empty():
			_detour_idx = 0
			return

	# 无导航网格或 A* 失败 → 保持在 DETOUR，_process_detour 将直接向目标平滑移动


# ═══════════════════════════════════════
# Line2D 路径工具方法
# ═══════════════════════════════════════

func _build_segments() -> void:
	_line_segments.clear()
	_path_total_length = 0.0
	var pts: PackedVector2Array = path_line.points
	if pts.size() < 2:
		return
	for i: int in range(pts.size() - 1):
		var seg_start: Vector2 = pts[i]
		var seg_end: Vector2 = pts[i + 1]
		var seg_len: float = seg_start.distance_to(seg_end)
		_line_segments.append({
			start = seg_start,
			end = seg_end,
			length = seg_len,
			accum = _path_total_length,
		})
		_path_total_length += seg_len


func _pos_on_path(dist: float) -> Vector2:
	if _line_segments.is_empty():
		return global_position
	var d: float = clamp(dist, 0.0, _path_total_length)
	for seg: Dictionary in _line_segments:
		var end_accum: float = seg.accum + seg.length
		if d <= end_accum:
			var t: float = (d - seg.accum) / seg.length
			return seg.start.lerp(seg.end, t)
	return _line_segments[-1].end


func _find_rejoin_point(start_progress: float) -> Vector2:
	var step: float = _tile_size.x if _tile_size.x > 0 else 64.0
	var probe: float = start_progress + step
	while probe < _path_total_length:
		var pos: Vector2 = _pos_on_path(probe)
		if _is_walkable_world(pos):
			return pos
		probe += step
	return _pos_on_path(_path_total_length)


func _closest_point_on_path(pos: Vector2) -> float:
	if _path_total_length <= 0.0:
		return 0.0
	var best_dist: float = INF
	var best_progress: float = 0.0
	var step: float = _tile_size.x * 0.25 if _tile_size.x > 0 else 16.0
	var probe: float = 0.0
	while probe <= _path_total_length:
		var p: Vector2 = _pos_on_path(probe)
		var d: float = p.distance_squared_to(pos)
		if d < best_dist:
			best_dist = d
			best_progress = probe
		probe += step
	return best_progress


# ═══════════════════════════════════════
# 导航网格 + A*
# ═══════════════════════════════════════

func _build_walkable() -> void:
	_walkable.clear()
	if not nav_tile_map:
		return
	_tile_size = Vector2(nav_tile_map.tile_set.tile_size)
	for cell: Vector2i in nav_tile_map.get_used_cells():
		_walkable[cell] = true


func _world_to_tile(pos: Vector2) -> Vector2i:
	if not nav_tile_map:
		return Vector2i.ZERO
	return nav_tile_map.local_to_map(nav_tile_map.to_local(pos))


func _tile_to_world(coord: Vector2i) -> Vector2:
	if not nav_tile_map:
		return Vector2.ZERO
	return nav_tile_map.to_global(nav_tile_map.map_to_local(coord))


func _is_walkable_world(pos: Vector2) -> bool:
	if _walkable.is_empty():
		return true
	return _walkable.get(_world_to_tile(pos), false)


func _is_walkable_tile(coord: Vector2i) -> bool:
	if _walkable.is_empty():
		return true
	return _walkable.get(coord, false)


func _find_path_astar(from: Vector2, to: Vector2) -> PackedVector2Array:
	var result: PackedVector2Array = PackedVector2Array()
	if _walkable.is_empty():
		return result
	var start: Vector2i = _world_to_tile(from)
	var goal: Vector2i = _world_to_tile(to)
	if not _is_walkable_tile(start):
		start = _closest_walkable(start)
	if not _is_walkable_tile(goal):
		goal = _closest_walkable(goal)

	var open: Array[Vector2i] = [start]
	var came_from: Dictionary = {}
	var g_score: Dictionary = {}
	g_score[start] = 0

	while not open.is_empty():
		var current: Vector2i = open[0]
		var current_f: float = g_score[current] + _heuristic(current, goal)
		for idx: int in range(1, open.size()):
			var node: Vector2i = open[idx]
			var f: float = g_score[node] + _heuristic(node, goal)
			if f < current_f:
				current = node
				current_f = f
		open.erase(current)

		if current == goal:
			var path: Array[Vector2i] = [current]
			while came_from.has(path[0]):
				path.push_front(came_from[path[0]])
			for tile: Vector2i in path:
				result.append(_tile_to_world(tile))
			return result

		for nb: Vector2i in _neighbors(current):
			var tentative: float = g_score[current] + 1.0
			if not g_score.has(nb) or tentative < g_score[nb]:
				came_from[nb] = current
				g_score[nb] = tentative
				if not open.has(nb):
					open.append(nb)
	return result


func _heuristic(a: Vector2i, b: Vector2i) -> float:
	return abs(a.x - b.x) + abs(a.y - b.y)


func _neighbors(tile: Vector2i) -> Array[Vector2i]:
	var dirs: Array[Vector2i] = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
	var result: Array[Vector2i] = []
	for d: Vector2i in dirs:
		var nb: Vector2i = tile + d
		if _is_walkable_tile(nb):
			result.append(nb)
	return result


func _closest_walkable(from: Vector2i) -> Vector2i:
	var queue: Array[Vector2i] = [from]
	var visited: Dictionary = {from: true}
	while not queue.is_empty():
		var cur: Vector2i = queue.pop_front()
		if _is_walkable_tile(cur):
			return cur
		for nb: Vector2i in _neighbors(cur):
			if not visited.get(nb, false):
				visited[nb] = true
				queue.append(nb)
	return from
