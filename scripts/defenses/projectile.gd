extends Node2D
class_name Projectile

## 炮塔弹丸 — 飞向目标敌人，命中后造成伤害

var target: BaseEnemy
var damage: int = 1
var speed: float = 400


func setup(t: BaseEnemy, dmg: int) -> void:
	target = t
	damage = dmg


func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		queue_free()
		return

	var dir := (target.global_position - global_position).normalized()
	position += dir * speed * delta

	if global_position.distance_to(target.global_position) < 10:
		target.take_damage(damage)
		queue_free()
