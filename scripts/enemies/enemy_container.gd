extends Node2D
class_name EnemyContainer

## 敌人管理器 — 生成 / 存活计数 / ENEMY Buff 路由
## 采用组合持有 BuffContainer，详见 explains/composition-over-inheritance.md

const base_enemy := preload("res://scenes/enemies/base_enemy.tscn")

@export var button_container: Node2D

## 内部 Buff 容器
var buff_container: BuffContainer

var _current_wave_enemy_amount := 0:
	set(value):
		_current_wave_enemy_amount = value
		if _current_wave_enemy_amount <= 0:
			battle_over.emit()

signal battle_over


func _ready() -> void:
	if not button_container:
		push_error("enemy_container's button_container is null")

	buff_container = BuffContainer.new()
	buff_container.target_type = BuffEffect.Target.ENEMY
	buff_container.name = "EnemyBuffContainer"
	add_child(buff_container)


func enemies_spawn(amount: int) -> void:
	if amount <= 0 or amount >= 100:
		amount = 5

	_current_wave_enemy_amount = amount
	for i in amount:
		var enemy := base_enemy.instantiate() as BaseEnemy
		var pos := get_global_mouse_position() + Vector2(randi_range(1, 50), randi_range(1, 50))
		enemy.global_position = pos
		enemy.buttons_container = button_container
		enemy.enemy_died.connect(func(): _current_wave_enemy_amount -= 1)
		self.add_child(enemy)


## WaveController 注册已预配置的敌人（实例化+定位已完成）
func register_enemy(enemy: BaseEnemy) -> void:
	enemy.enemy_died.connect(_on_registered_enemy_died)
	_current_wave_enemy_amount += 1
	add_child(enemy)


func _on_registered_enemy_died() -> void:
	_current_wave_enemy_amount -= 1
