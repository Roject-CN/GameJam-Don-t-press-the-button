extends BuffContainer
class_name EnemyContainer

const base_enemy := preload("res://scenes/enemies/base_enemy.tscn")

var _current_wave_enemy_amount := 0 :
	set(value):
		_current_wave_enemy_amount = value
		if _current_wave_enemy_amount <= 0:
			battle_overd.emit()
			
signal battle_overd()			

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
		enemy.enemy_died.connect(func() : _current_wave_enemy_amount -= 1)
		self.add_child(enemy)
