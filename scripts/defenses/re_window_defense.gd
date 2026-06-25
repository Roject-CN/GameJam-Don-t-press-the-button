extends WindowDefense
class_name ReWindowDefense

func redirect(enemy : BaseEnemy) -> void:
	enemy.redirect_to(base_button.global_position, true)
