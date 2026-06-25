extends Node2D
class_name EnemyContainer

## 敌人容器 — 纯计数：追踪总数 / 击杀，不关心波次

const base_enemy := preload("res://scenes/enemies/base_enemy.tscn")

## 内部 Buff 容器（组合代替继承）
var buff_container: BuffContainer

## 累计生成总数
var total_spawned: int = 0

## 累计击杀数
var enemies_killed: int = 0:
	set(v):
		enemies_killed = v
		enemies_killed_count_changed.emit(enemies_killed)
		if total_spawned > 0 and enemies_killed >= total_spawned:
			all_enemies_defeated.emit()

## 当前存活数（仅用于展示/调试）
var enemies_alive: int = 0

## 所有已生成敌人全部被击杀时发射
signal all_enemies_defeated

## 击杀数变化时发射（供 HUD 等监听）
signal enemies_killed_count_changed(count: int)


func _ready() -> void:
	buff_container = BuffContainer.new()
	buff_container.target_type = BuffEffect.Target.ENEMY
	buff_container.name = "EnemyBuffContainer"
	add_child(buff_container)


## 调试生成 — 鼠标附近一次性生成指定数量
func enemies_spawn(amount: int) -> void:
	if amount <= 0 or amount >= 100:
		amount = 5

	for i in amount:
		var enemy := base_enemy.instantiate() as BaseEnemy
		var pos := get_global_mouse_position() + Vector2(randi_range(1, 50), randi_range(1, 50))
		enemy.global_position = pos
		enemy.enemy_died.connect(_on_enemy_died)
		add_child(enemy)
		total_spawned += 1
		enemies_alive += 1


## WaveController 注册已预配置的敌人
func register_enemy(enemy: BaseEnemy) -> void:
	enemy.enemy_died.connect(_on_enemy_died)
	add_child(enemy)
	total_spawned += 1
	enemies_alive += 1


func _on_enemy_died() -> void:
	enemies_killed += 1
	enemies_alive -= 1
