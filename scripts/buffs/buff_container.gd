extends Node2D
class_name BuffContainer
#用于和BuffEmitter对接的容器
#届时比如说敌人都放置在这个容器下，然后buff利用BuffContainer 和 BuffEmitter
#作用于目标角色

#这里规定一些基本的方法，具体的还需要针对各个模块的需求重写

@export var target_type: BuffEffect.Target

var active_buffs: Array[BuffEffect] = []

signal buff_applied(effect: BuffEffect)
signal buff_expired(effect: BuffEffect)
signal buffs_changed


func apply_buff(effect: BuffEffect) -> void:
	active_buffs.append(effect)
	buff_applied.emit(effect)
	buffs_changed.emit()


func remove_buff(effect: BuffEffect) -> void:
	active_buffs.erase(effect)
	buff_expired.emit(effect)
	buffs_changed.emit()
