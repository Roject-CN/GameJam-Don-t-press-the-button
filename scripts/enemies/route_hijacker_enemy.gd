extends BaseEnemy
class_name RouteHijackerEnemy

## 路由劫持者 — 移动光环塔
## 在失败按钮之间漫游，范围内增强友方敌人，只点击扣命失败按钮
## 复用基类 LURED 状态机进行 A* 寻路，taunt_resistance = 100%

# ── 光环配置 ──
@export var speed_buff_mult: float = 1.3
@export var health_buff_mult: float = 1.5

# ── 节点 ──
@onready var aura_area: Area2D = $AuraArea

# ── 光环追踪 ──
var _buffed: Dictionary = {}  # {BaseEnemy: {orig_speed: float, orig_health: int}}


func _ready() -> void:
	super._ready()
	if aura_area:
		aura_area.area_entered.connect(_on_aura_entered)
		aura_area.area_exited.connect(_on_aura_exited)


func _exit_tree() -> void:
	_cleanup_all_aura()


# ═══════════════════════════════════════
# 移动 — 复用基类 LURED 状态（A* 寻路）
# ═══════════════════════════════════════

func _physics_process(delta: float) -> void:
	if _dying:
		return
	# setup 完成后首次切到 LURED 漫游
	if _setup_done and _move_state != MoveState.LURED:
		_navigate_to_failure_button()
	super._physics_process(delta)


# ═══════════════════════════════════════
# 按钮选择 → 自我引诱到失败按钮
# ═══════════════════════════════════════

func _is_failure_button(btn: BaseClickedButton) -> bool:
	for e in btn.buff_effect:
		if not (e is PropertyBuffEffect):
			continue
		if e.property_name != "current_lives":
			continue
		# 只有减少 current_lives 的才是失败按钮（排除回血按钮）
		match e.operation:
			PropertyBuffEffect.Operation.ADD:
				if e.value < 0.0:
					return true
			PropertyBuffEffect.Operation.MULTIPLY:
				if e.value < 1.0:
					return true
			PropertyBuffEffect.Operation.SET:
				if e.value <= 0.0:
					return true
	return false


func _navigate_to_failure_button() -> void:
	var failure_buttons: Array[BaseClickedButton] = []
	for btn_node in get_tree().get_nodes_in_group("ClickedButtons"):
		var btn := btn_node as BaseClickedButton
		if btn and _is_failure_button(btn):
			failure_buttons.append(btn)

	if failure_buttons.is_empty():
		return

	var btn: BaseClickedButton = failure_buttons[randi() % failure_buttons.size()]
	_move_state = MoveState.LURED
	_lure_target = btn.global_position
	_lure_source = weakref(self)
	_detour = _find_path_astar(global_position, _lure_target)
	_detour_idx = 0


# ═══════════════════════════════════════
# 点击 — 只点失败按钮
# ═══════════════════════════════════════

func _try_click() -> void:
	if _dying or _clicking:
		return

	var best: BaseClickedButton = null
	var best_dist: float = INF
	for btn_node in get_tree().get_nodes_in_group("ClickedButtons"):
		var btn := btn_node as BaseClickedButton
		if not btn or not _is_failure_button(btn):
			continue
		var d := btn.global_position.distance_squared_to(global_position)
		if d < best_dist:
			best_dist = d
			best = btn

	if best and sqrt(best_dist) <= click_range:
		_click_button(best)
	else:
		_navigate_to_failure_button()


func _on_click_anim_done(_anim_name: StringName) -> void:
	if _dying:
		_clicking = false
		_click_btn = null
		return

	var btn := _click_btn
	_click_btn = null
	if is_instance_valid(btn):
		btn.release()

	_consume_click()
	_clicking = false
	_check_depleted()

	# 不 _end_lure() — 直接找下一个失败按钮
	if not _dying and click_times > 0:
		_navigate_to_failure_button()


# ═══════════════════════════════════════
# 光环 — 修改友方敌人属性
# ═══════════════════════════════════════

func _on_aura_entered(area: Area2D) -> void:
	var enemy := area.get_parent() as BaseEnemy
	if not enemy or enemy == self or enemy._dying:
		return
	if _buffed.has(enemy):
		return

	_buffed[enemy] = {orig_speed = enemy.speed, orig_health = enemy.health}
	enemy.speed *= speed_buff_mult
	enemy.health = ceili(enemy.health * health_buff_mult)


func _on_aura_exited(area: Area2D) -> void:
	var enemy := area.get_parent() as BaseEnemy
	if not enemy:
		return
	_remove_aura_from(enemy)


func _remove_aura_from(enemy: BaseEnemy) -> void:
	if not _buffed.has(enemy):
		return
	var orig := _buffed[enemy] as Dictionary
	if is_instance_valid(enemy):
		enemy.speed = orig.orig_speed
		enemy.health = orig.orig_health
	_buffed.erase(enemy)


func _cleanup_all_aura() -> void:
	for enemy in _buffed.keys():
		if is_instance_valid(enemy):
			var orig := _buffed[enemy] as Dictionary
			enemy.speed = orig.orig_speed
			enemy.health = orig.orig_health
	_buffed.clear()


# ═══════════════════════════════════════
# 死亡 — 清理光环
# ═══════════════════════════════════════

func _die() -> void:
	_cleanup_all_aura()
	super._die()
