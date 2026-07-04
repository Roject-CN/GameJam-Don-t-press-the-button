extends BaseEnemy
class_name RouteHijackerEnemy

## 路由劫持者 — 沿路径移动，范围内增强友方敌人

@export var speed_buff_mult: float = 1.3
@export var health_buff_mult: float = 1.5

@onready var aura_area: Area2D = $AuraArea

var _buffed: Dictionary = {}


func _ready() -> void:
	super._ready()
	if aura_area:
		aura_area.area_entered.connect(_on_aura_entered)
		aura_area.area_exited.connect(_on_aura_exited)


func _exit_tree() -> void:
	_cleanup_all_aura()


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
	var orig: Dictionary = _buffed[enemy]
	if is_instance_valid(enemy):
		enemy.speed = orig.orig_speed
		enemy.health = orig.orig_health
	_buffed.erase(enemy)


func _cleanup_all_aura() -> void:
	for enemy: BaseEnemy in _buffed.keys():
		if is_instance_valid(enemy):
			var orig: Dictionary = _buffed[enemy]
			enemy.speed = orig.orig_speed
			enemy.health = orig.orig_health
	_buffed.clear()


func _die() -> void:
	_cleanup_all_aura()
	super._die()
