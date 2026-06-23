extends Control


@onready var enemy_container: EnemyContainer = $StageManager/EnemyContainer

#用于测试产生敌人
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("right_mouse"):
		enemy_container.enemies_spawn(5)
