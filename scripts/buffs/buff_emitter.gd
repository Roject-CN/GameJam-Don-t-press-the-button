extends Node2D
class_name BuffEmitter

## Buff 触发器 — 连接按钮信号，将 BuffEffect 路由到对应 BuffContainer
## 容器按需连接：某路缺失时仅跳过，不报错

@export var enemy_controller: EnemyController
@export var defense_manager: DefenceManager
@export var player_container: PlayerContainer
@export var button_container: Node2D


func _ready() -> void:
	if not button_container:
		push_error("BuffEmitter: button_container is null")
		return
	connect_all()


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
	_route(effect)


func _route(effect: BuffEffect) -> void:
	var container := _resolve(effect.target)
	if not container:
		return
	var instance := effect.duplicate(true) as BuffEffect
	container.apply_buff(instance)


func _resolve(target: BuffEffect.Target) -> BuffContainer:
	match target:
		BuffEffect.Target.ENEMY:
			return enemy_controller.buff_container if enemy_controller else null
		BuffEffect.Target.DEFENSE:
			return defense_manager.buff_container if defense_manager else null
		BuffEffect.Target.PLAYER:
			return player_container.buff_container if player_container else null
		_:
			return null
