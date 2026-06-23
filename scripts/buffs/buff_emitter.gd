extends Node2D
class_name BuffEmitter

@export var enemy_container: BuffContainer
@export var defense_container: BuffContainer
@export var player_container: BuffContainer
@export var terrain_container: BuffContainer

@export var button_container : Node2D

func _ready() -> void:
	# 连接所有按钮的 buff_effect_applied 信号
	connect_all()
	
	if enemy_container and defense_container and player_container \
	and terrain_container and button_container:
		pass
	else:
		push_error()


func connect_all() -> void:
	for btn in button_container.get_children():
		if btn is BaseClickedButton:
			if not btn.buff_effect_applied.is_connected(_on_buff_effect_applied):
				btn.buff_effect_applied.connect(_on_buff_effect_applied)


func disconnect_all() -> void:
	for btn in button_container.get_children():
		if btn is BaseClickedButton:
			if btn.buff_effect_applied.is_connected(_on_buff_effect_applied):
				btn.buff_effect_applied.disconnect(_on_buff_effect_applied)


func _on_buff_effect_applied(effect: BuffEffect) -> void:
	var container := _get_container_for(effect.target)
	if not container:
		push_error("BuffEmitter: no container found for target: " + str(effect.target))
		return

	var instance := effect.duplicate(true) as BuffEffect
	container.apply_buff(instance)


func _get_container_for(target: BuffEffect.Target) -> BuffContainer:
	match target:
		BuffEffect.Target.ENEMY:   return enemy_container
		BuffEffect.Target.DEFENSE:  return defense_container
		BuffEffect.Target.PLAYER:  return player_container
		BuffEffect.Target.TERRAIN: return terrain_container

	return null
