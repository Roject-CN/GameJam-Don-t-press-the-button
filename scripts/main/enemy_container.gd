extends BuffContainer
class_name EnemyContainer

const base_enemy := preload("res://scenes/enemies/base_enemy.tscn")

@export var button_container : Node2D

var _current_wave_enemy_amount := 0 :
	set(value):
		_current_wave_enemy_amount = value
		if _current_wave_enemy_amount <= 0:
			battle_over.emit()

signal battle_over			

func _ready() -> void:
	if not button_container:
		push_error("enemy_container's button_container is null")
	#要记得规定好自己的target_type
	target_type = BuffEffect.Target.ENEMY
	
func apply_buff(effect: BuffEffect) -> void:
	super(effect)

func remove_buff(effect: BuffEffect) -> void:
	super(effect)

func enemies_spawn(amount : int) -> void:
	if amount <= 0 or amount >= 100:
		amount = 5
	
	_current_wave_enemy_amount = amount
	for i in amount:
		var enemy := base_enemy.instantiate() as BaseEnemy
		var pos := get_global_mouse_position() + Vector2(randi_range(1, 50), randi_range(1, 50))
		enemy.global_position = pos
		enemy.buttons_container = button_container
		enemy.enemy_died.connect(func() : _current_wave_enemy_amount -= 1)
		self.add_child(enemy)
