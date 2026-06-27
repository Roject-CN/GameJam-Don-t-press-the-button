extends Node2D
class_name EnemyManager

## 敌人引用容器 — 仅存储当前场上存活的敌人引用，无计数、无信号


## 场上存活的敌人列表
var enemies: Array[BaseEnemy] = []


func add(enemy: BaseEnemy) -> void:
	enemies.append(enemy)


## 当前存活数（仅用于展示/调试）
var enemies_alive: int = 0

## 所有已生成敌人全部被击杀时发射
signal all_enemies_defeated


func _ready() -> void:
	buff_container = BuffContainer.new()
	buff_container.target_type = BuffEffect.Target.ENEMY
	buff_container.name = "EnemyBuffContainer"
	add_child(buff_container)

	buff_container.buff_applied.connect(_on_buff_applied)
	buff_container.buff_removed.connect(_on_buff_removed)


## 调试生成 — 鼠标附近一次性生成指定数量
func enemies_spawn(amount: int) -> void:
	if amount <= 0 or amount >= 100:
		amount = 5

	for i in amount:
		var enemy := base_enemy.instantiate() as BaseEnemy
		var pos := get_global_mouse_position() + Vector2(randi_range(1, 50), randi_range(1, 50))
		enemy.global_position = pos
		enemy.buttons_container = button_container
		enemy.enemy_died.connect(_on_enemy_died)
		add_child(enemy)
		for buff in buff_container.get_active_buffs():
			buff.apply(enemy)
		total_spawned += 1
		enemies_alive += 1


## WaveController 注册已预配置的敌人
func register_enemy(enemy: BaseEnemy) -> void:
	enemy.enemy_died.connect(_on_enemy_died)
	add_child(enemy)
	for buff in buff_container.get_active_buffs():
		buff.apply(enemy)
	total_spawned += 1
	enemies_alive += 1


func _on_buff_applied(effect: BuffEffect) -> void:
	for child in get_children():
		if child is BaseEnemy:
			effect.apply(child)


func _on_buff_removed(effect: BuffEffect) -> void:
	for child in get_children():
		if child is BaseEnemy:
			effect.remove(child)


func _on_enemy_died() -> void:
	enemies_killed += 1
	enemies_alive -= 1
