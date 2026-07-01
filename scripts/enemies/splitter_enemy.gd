extends BaseEnemy
class_name SplitterEnemy

## 分裂者 — 死后生成小型子体，子体死完才真正 queue_free
## 子体继承父体路径，属性降低，只能点击 1 次，不会再次分裂

# ── 分裂配置 ──
@export var split_count: int = 2
@export var split_mini_scene: PackedScene

# ── 子体追踪 ──
var _alive_children: int = 0


# ═══════════════════════════════════════
# 死亡 — 隐藏本体，生成子体，等子体死完再 free
# ═══════════════════════════════════════

func _die() -> void:
	_dying = true
	_clicking = false
	if _click_btn and is_instance_valid(_click_btn):
		_click_btn.release()
	_click_btn = null

	# 隐藏本体
	visible = false
	if area_2d:
		area_2d.set_deferred("monitoring", false)
		area_2d.set_deferred("monitorable", false)

	# 计算子体属性（在 health/speed 被外部修改前捕获）
	var child_health := maxi(1, health / 2)
	var child_speed := speed * 0.7

	# 生成子体
	for i in range(split_count):
		_spawn_child(i, child_speed, child_health)

	# 若所有子体均生成失败 → 立即自毁，避免卡死 battle_over
	if _alive_children <= 0:
		enemy_died.emit()
		call_deferred("queue_free")
		return

	# 不 emit enemy_died，不 queue_free — _on_child_died 管理


func _spawn_child(_index: int, child_speed: float, child_health: int) -> void:
	if not split_mini_scene:
		push_error("SplitterEnemy: split_mini_scene 未设置")
		return

	var mini := split_mini_scene.instantiate() as BaseEnemy
	if not mini:
		return

	# 位置：父体位置 + 小随机偏移
	mini.global_position = global_position + Vector2(randf_range(-10, 10), randf_range(-10, 10))

	# 手动设置属性（绕过 EnemyConfig，子体独立配置）
	mini.speed = child_speed
	mini.health = child_health
	mini.click_times = 1

	# 继承路径
	if path_line:
		mini.path_line = path_line
		mini._build_segments()
	if nav_tile_map:
		mini.set_nav_grid(nav_tile_map)

	# 从当前位置开始沿路径移动（而非从路径起点开始）
	if path_line and mini._path_total_length > 0.0:
		mini._path_progress = mini._closest_point_on_path(mini.global_position)

	# 标记就绪，启用物理处理
	mini._setup_done = true

	# 挂载到父节点的同一容器下（避免继承 splitter 的 scale）
	var parent_node := get_parent()
	if parent_node:
		parent_node.add_child(mini)
	else:
		add_child(mini)

	# 追踪子体死亡
	mini.enemy_died.connect(_on_child_died.bind(mini))
	_alive_children += 1


func _on_child_died(_which: BaseEnemy) -> void:
	_alive_children -= 1
	if _alive_children <= 0:
		enemy_died.emit()
		call_deferred("queue_free")
