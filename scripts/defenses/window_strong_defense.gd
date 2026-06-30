extends WindowDefense
class_name WindowStrongDefense

## 强钓鱼窗口 — 持续引诱敌人，反复消耗点击直到次数耗尽


func _redirect(enemy: BaseEnemy) -> void:
	enemy.request_lure(self, global_position, true)
