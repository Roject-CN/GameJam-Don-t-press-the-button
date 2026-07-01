extends WindowDefense
class_name WindowWeakDefense

## 弱钓鱼窗口 — 每个敌人只引诱一次，消耗一次点击后释放


## 已被引诱过的敌人集合
var _lured_set: Array[BaseEnemy] = []


func _redirect(enemy: BaseEnemy) -> void:
	if enemy in _lured_set:
		return
	_lured_set.append(enemy)
	enemy.request_lure(self, global_position, false)


## 消耗一次后立刻释放敌人，回到原路径
func _on_consumed(enemy: BaseEnemy) -> void:
	enemy.release_lure(self)


## 清理已死亡敌人的记录
func _process(delta: float) -> void:
	super(delta)
	var i: int = _lured_set.size() - 1
	while i >= 0:
		if not is_instance_valid(_lured_set[i]) or _lured_set[i]._dying:
			_lured_set.remove_at(i)
		i -= 1
