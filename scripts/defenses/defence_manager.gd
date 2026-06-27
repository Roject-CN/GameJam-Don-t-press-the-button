extends Node2D
class_name DefenceManager

## 防御设施统一管理器 — defence 孵化 / 正式放置 / 移除
##
## 采用组合而非继承 BuffContainer，详见 explains/composition-over-inheritance.md

## 用于接收 DEFENSE 目标 Buff 的内部容器（组合代替继承）
## BuffEmitter 通过 buff_container 路由 DEFENSE 类型的 BuffEffect

var buff_container: BuffContainer

## 当前挂载的关卡场景
@export var level_scene: level

## 已放置的防御列表
var placed_defenses: Array[BaseDefense] = []


func _ready() -> void:
	# 创建内部 BuffContainer
	buff_container = BuffContainer.new()
	buff_container.target_type = BuffEffect.Target.DEFENSE
	buff_container.name = "DefenseBuffContainer"
	add_child(buff_container)

	buff_container.buff_applied.connect(_on_buff_applied)
	buff_container.buff_removed.connect(_on_buff_removed)


## 拖拽开始时调用，将半透明 defence 加入关卡场景
func spawn_defence(defence: BaseDefense) -> void:
	defence.is_placed = false
	if level_scene:
		level_scene.add_child(defence)
	else:
		get_tree().current_scene.add_child(defence)


## 确认放置 — 松手时调用，place() + 加入管理列表
func confirm_placement(defence: BaseDefense) -> void:
	defence.place()
	placed_defenses.append(defence)
	for buff in buff_container.get_active_buffs():
		buff.apply(defence)


## 移除防御设施
func remove_defence(defence: BaseDefense) -> void:
	placed_defenses.erase(defence)
	if is_instance_valid(defence):
		for buff in buff_container.get_active_buffs():
			buff.remove(defence)
		defence.queue_free()


func _on_buff_applied(effect: BuffEffect) -> void:
	for defense in placed_defenses:
		effect.apply(defense)


func _on_buff_removed(effect: BuffEffect) -> void:
	for defense in placed_defenses:
		effect.remove(defense)
