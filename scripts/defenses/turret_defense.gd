extends BaseDefense
class_name TurretDefense

## 射击炮塔 — 自动索敌，发射弹丸造成伤害

## 射击间隔（秒）
@export var fire_rate: float = 1.5

## 每发弹丸伤害
@export var damage: int = 1

var _fire_cooldown: float = 0.0
var _enemies_in_range: Array[BaseEnemy] = []
var _current_target: BaseEnemy = null

const projectile_scene := preload("res://scenes/defenses/projectile.tscn")


func _on_placed() -> void:
	area_node.area_entered.connect(_on_area_entered)
	area_node.area_exited.connect(_on_area_exited)
	# 延迟一帧等待物理服务器完成 AABB 更新，再手动收集已重叠的敌人
	await get_tree().physics_frame
	for area in area_node.get_overlapping_areas():
		_on_area_entered(area)


func _process(delta: float) -> void:
	if not is_placed:
		_ghost()
		return

	_acquire_target()
	if _current_target:
		_fire_cooldown -= delta
		if _fire_cooldown <= 0.0:
			_fire()
	else:
		# 无目标时重置冷却，防止空转导致敌人进入射程瞬间开火
		_fire_cooldown = 0.0


## 选最近有效敌人（按距离升序排列，取最近）
func _acquire_target() -> void:
	_enemies_in_range = _enemies_in_range.filter(func(e: BaseEnemy): return is_instance_valid(e))
	if _enemies_in_range.size() > 0:
		_enemies_in_range.sort_custom(func(a: BaseEnemy, b: BaseEnemy): return a.global_position.distance_squared_to(global_position) < b.global_position.distance_squared_to(global_position))
		_current_target = _enemies_in_range[0]
	else:
		_current_target = null


## 发射弹丸
func _fire() -> void:
	var p := projectile_scene.instantiate() as Projectile
	p.global_position = global_position
	p.setup(_current_target, damage)
	get_tree().current_scene.add_child(p)
	_fire_cooldown = fire_rate


func _on_area_entered(area: Area2D) -> void:
	var enemy := area.get_parent() as BaseEnemy
	if enemy and not _enemies_in_range.has(enemy):
		_enemies_in_range.append(enemy)


func _on_area_exited(area: Area2D) -> void:
	var enemy := area.get_parent() as BaseEnemy
	if enemy:
		_enemies_in_range.erase(enemy)
