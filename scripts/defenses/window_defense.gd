extends BaseDefense
class_name WindowDefense

## 钓鱼窗口基类 — 双层 Area 防御
##   Area（基类 area_node）：引诱范围，敌人进入 → 重定向到窗口中心
##   Area2（子类场景添加）：作用范围，敌人靠近 → 消耗 click_times
##
##  子类覆写 _redirect() 决定引诱模式（单次/持续）

## 可引诱次数（耗尽后关闭）
@export var lure_count: int = 5

## 作用范围触发距离（Area2 内补检）
@export var strike_range: float = 48.0

@onready var area2_node: Area2D = $Area2
@onready var counter_label: Label = $CounterLabel

var _remaining: int
var _active: bool = true
var _strike_cd: Dictionary = {}  # BaseEnemy → float
var _lured_enemies: Array[BaseEnemy] = []  # 被本窗口引诱的敌人，停用时释放


func _ready() -> void:
	_remaining = lure_count
	if counter_label:
		counter_label.text = str(_remaining)


func _process(delta: float) -> void:
	if not is_placed:
		super(delta)
		return
	if not _active:
		return

	# 冷却递减 + 清理死敌
	for e in _strike_cd.keys():
		if is_instance_valid(e) and not e._dying:
			_strike_cd[e] -= delta
		else:
			_strike_cd.erase(e)
	# 清理已死亡的被引诱敌人
	var i: int = _lured_enemies.size() - 1
	while i >= 0:
		if not is_instance_valid(_lured_enemies[i]) or _lured_enemies[i]._dying:
			_lured_enemies.remove_at(i)
		i -= 1

	# 检测 Area2 重叠敌人 → 消耗点击
	if not area2_node:
		return
	for area: Area2D in area2_node.get_overlapping_areas():
		var enemy: BaseEnemy = area.get_parent() as BaseEnemy
		if not enemy or enemy._dying:
			continue
		if enemy.global_position.distance_to(global_position) > strike_range:
			continue
		if _strike_cd.get(enemy, 0.0) > 0.0:
			continue
		_consume(enemy)
		_strike_cd[enemy] = 0.5


func _consume(enemy: BaseEnemy) -> void:
	_remaining -= 1
	if counter_label:
		counter_label.text = str(_remaining)

	enemy.strike()

	_on_consumed(enemy)

	if _remaining <= 0:
		_deactivate()


## 子类覆写：点击消耗后的行为
func _on_consumed(_enemy: BaseEnemy) -> void:
	pass


func _on_placed() -> void:
	area_node.area_entered.connect(_on_lure_entered)
	if area2_node:
		area2_node.area_entered.connect(_on_lure_entered)
	_pickup_all()


func _pickup_all() -> void:
	for area: Area2D in area_node.get_overlapping_areas():
		_on_lure_entered(area)


## 敌人进入引诱/作用范围 → 重定向
func _on_lure_entered(area: Area2D) -> void:
	if not _active:
		return
	var enemy: BaseEnemy = area.get_parent() as BaseEnemy
	if not enemy or enemy._dying:
		return
	if enemy.taunt_resistance > 0.0 and randf() < enemy.taunt_resistance:
		return
	_redirect(enemy)
	if not enemy in _lured_enemies:
		_lured_enemies.append(enemy)


## 子类覆写：决定引诱类型
func _redirect(enemy: BaseEnemy) -> void:
	enemy.request_lure(self, global_position, false)


func _deactivate() -> void:
	_active = false
	area_node.area_entered.disconnect(_on_lure_entered)
	area_node.monitoring = false
	if area2_node:
		if area2_node.area_entered.is_connected(_on_lure_entered):
			area2_node.area_entered.disconnect(_on_lure_entered)
		area2_node.monitoring = false

	# 释放所有被本窗口引诱的敌人，使其回归路径（release_lure 幂等）
	for enemy: BaseEnemy in _lured_enemies:
		if is_instance_valid(enemy) and not enemy._dying:
			enemy.release_lure(self)
	_lured_enemies.clear()

	modulate = Color.GRAY
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 2.0)
	tween.tween_callback(queue_free)
