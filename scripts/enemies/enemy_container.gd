extends Node2D
class_name EnemyContainer

## 敌人引用容器 — 仅存储当前场上存活的敌人引用，无计数、无信号


## 场上存活的敌人列表
var enemies: Array[BaseEnemy] = []


func add(enemy: BaseEnemy) -> void:
	enemies.append(enemy)


func remove(enemy: BaseEnemy) -> void:
	enemies.erase(enemy)
