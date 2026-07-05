extends Node2D
class_name BaseEnemy

## 敌人基类 — 沿 Line2D 路径移动，接近按钮时停止并点击

# 节点
@onready var area_2d: Area2D = $Area2D
var nav_agent: NavigationAgent2D = null

# 属性
@export var speed: float = 200.0
@export var health: int = 1
@export var click_times: int = 2
@export var click_range: float = 50.0

#引诱相关
@export var temptable: bool = true
@export var taunt_resistance: float = 0.0
var being_temptied: bool = false
var tempter: Node2D = null

## 引诱内部状态 — request_lure / release_lure 管理
var _lure_source: Node2D = null
var _lure_target: Vector2 = Vector2.ZERO
var _lure_repeated: bool = false
var _original_path_progress: float = 0.0  ## 被引诱前在原始路径上的进度，释放后恢复

## 返回路径状态 — 释放引诱后移动回原路径
var _returning_to_path: bool = false
var _return_target: Vector2 = Vector2.ZERO  ## 原路径上的目标点

# 外部注入
var config: EnemyConfig = null
var path_line: Line2D = null

# 路径状态
var _path_progress: float = 0.0
var _path_total_length: float = 0.0
var _segments: Array[Dictionary] = []

# 导航
var _use_nav_grid: bool = false
var _nav_target: Vector2 = Vector2.ZERO

# 点击状态
var _clicking: bool = false

# 生命状态
var _setup_done: bool = false
var _dying: bool = false

signal enemy_died()


func _ready() -> void:
	if has_node("NavigationAgent2D"):
		nav_agent = $NavigationAgent2D
	if config:
		_apply_config()
		if path_line:
			_path_total_length = _build_segments(path_line.points)
		_setup_done = true


func setup(p_config: EnemyConfig, p_path_line: Line2D) -> void:
	config = p_config
	path_line = p_path_line
	if p_path_line:
		_path_total_length = _build_segments(p_path_line.points)
	if is_inside_tree():
		_apply_config()
		_setup_done = true


func _apply_config() -> void:
	if not config:
		return
	speed = config.speed if config.speed > 0 else speed
	health = config.health if config.health > 0 else health
	click_times = config.click_times
	taunt_resistance = config.taunt_resistance




# ══ 生命 ══

func take_damage(amount: int) -> void:
	if _dying:
		return
	health -= amount
	if health <= 0:
		_die()


## 钓鱼窗口消耗一次点击 → 对敌人造成 1 点伤害
func strike() -> void:
	take_damage(1)


func _die() -> void:
	_dying = true
	_clicking = false
	enemy_died.emit()
	call_deferred("queue_free")


# ══ 点击 ══

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


func _click_button(btn: BaseClickedButton) -> void:
	if _dying or click_times <= 0:
		return
	_clicking = true
	btn.press()
	btn.release()
	click_times -= 1
	_clicking = false
	if click_times <= 0:
		_die()

# ══ 路径 ════ 导航 ══

func _build_segments(pts: PackedVector2Array) -> float:
	_segments.clear()
	var total: float = 0.0
	if pts.size() < 2:
		return 0.0
	# Line2D.points 是本地坐标，需要加上 path_line 的全局位置偏移转为全局坐标
	var offset: Vector2 = path_line.global_position if path_line else Vector2.ZERO
	for i: int in range(pts.size() - 1):
		var p0: Vector2 = pts[i] + offset
		var p1: Vector2 = pts[i + 1] + offset
		var seg_len: float = p0.distance_to(p1)
		_segments.append({start = p0, end = p1, length = seg_len, accum = total})
		total += seg_len
	return total


func _pos_on_path(dist: float) -> Vector2:
	if _segments.is_empty():
		return global_position
	var d: float = clamp(dist, 0.0, _path_total_length)
	for seg: Dictionary in _segments:
		var end_accum: float = seg.accum + seg.length
		if d <= end_accum:
			var t: float = (d - seg.accum) / seg.length
			return seg.start.lerp(seg.end, t)
	return _segments[-1].end


func _closest_point_on_path(pos: Vector2) -> float:
	if _segments.is_empty():
		return 0.0
	var best_dist: float = INF
	var best_progress: float = 0.0
	var step: float = 8.0
	var probe: float = 0.0
	while probe <= _path_total_length:
		var p: Vector2 = _pos_on_path(probe)
		var d: float = p.distance_squared_to(pos)
		if d < best_dist:
			best_dist = d
			best_progress = probe
		probe += step
	return best_progress

func set_nav_grid(nav: TileMapLayer, target_pos: Vector2 = Vector2.ZERO) -> void:
	if nav and nav_agent:
		nav_agent.set_navigation_map(nav.get_world_2d().navigation_map)
		if target_pos != Vector2.ZERO:
			nav_agent.target_position = target_pos
		_use_nav_grid = true
	else:
		_use_nav_grid = false

# ══ 引诱系统 ══

## 被钓鱼窗口引诱 — 保存原始路径进度，开始向引诱目标移动
func request_lure(source: Node2D, target_pos: Vector2, repeated: bool) -> void:
	if not temptable:
		return
	if being_temptied:
		return  # 已经被引诱中，不覆盖
	# 保存原始路径上最近点的进度，释放后从此恢复
	if _path_total_length > 0.0:
		_original_path_progress = _closest_point_on_path(global_position)
	else:
		_original_path_progress = 0.0
	_lure_source = source
	_lure_target = target_pos
	_lure_repeated = repeated
	being_temptied = true
	tempter = source


## 释放引诱 — 触发移动回原路径动画，到达后恢复路径移动
func release_lure(source: Node2D) -> void:
	if not being_temptied:
		return
	if source != null and source != _lure_source:
		return  # 只有引诱源才能释放
	being_temptied = false
	tempter = null
	_lure_source = null
	_lure_repeated = false
	_lure_target = Vector2.ZERO
	# 转入"返回路径"状态：向原路径上的最近点移动，而非闪现
	if _path_total_length > 0.0:
		_path_progress = _closest_point_on_path(global_position)
		_return_target = _pos_on_path(_path_progress)
		_returning_to_path = true


## 通过导航网格移向目标点。用 NavigationServer2D 同步查询路径，导航生效时严格约束在导航网格内。到达时返回 true
func _nav_move_toward(delta: float, target: Vector2) -> bool:
	var dist: float = global_position.distance_to(target)
	if dist <= 5.0:
		global_position = target
		return true

	var next_pos: Vector2 = target
	if _use_nav_grid and nav_agent:
		var map_rid: RID = nav_agent.get_navigation_map()
		if map_rid.is_valid():
			var path: PackedVector2Array = NavigationServer2D.map_get_path(
				map_rid, global_position, target, true
			)
			if path.size() >= 2:
				# path[0] 是起点，path[1] 是导航路径上的下一步
				next_pos = path[1]
			elif path.size() == 1:
				# 起点已在目标附近，直接走向目标
				next_pos = target
			else:
				# 无有效路径，停在原地，不越出导航网格
				return false

	var to_next: Vector2 = next_pos - global_position
	var step: float = min(speed * delta, to_next.length())
	if step > 0.0:
		global_position += to_next.normalized() * step
	return false

func _physics_process(delta: float) -> void:
	if _dying or not _setup_done:
		return

	# 点击进行中 → 暂停移动
	if _clicking:
		return

	# 检测附近按钮 → 停止并点击
	var btn: BaseClickedButton = _find_nearest_button(global_position)
	if btn and btn.global_position.distance_to(global_position) <= click_range:
		_click_button(btn)
		return
	
	if being_temptied:
		if not is_instance_valid(_lure_source):
			release_lure(null)
			return
		_nav_move_toward(delta, _lure_target)
		return

	if _returning_to_path:
		if _nav_move_toward(delta, _return_target):
			_returning_to_path = false
			_return_target = Vector2.ZERO
		return

	# 沿路径移动
	if _path_total_length <= 0.0:
		return

	_path_progress += speed * delta
	if _path_progress >= _path_total_length:
		_path_progress = _path_total_length
		global_position = _pos_on_path(_path_progress)
		return

	global_position = _pos_on_path(_path_progress)
