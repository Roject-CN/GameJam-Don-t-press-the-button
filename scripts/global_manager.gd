extends Node2D
class_name GlobalManager

## 全局信号路由 — 连接 EnemyController / PlayerContainer 信号，驱动游戏流程

@export var enemy_manager: EnemyManager
@export var wave_controller: WaveController
@export var buff_emitter: BuffEmitter
@export var player_manager: PlayerManager

var ready_button: Button

var _started: bool = false
var _settled: bool = false

signal game_over(is_win: bool)


func _ready() -> void:
	enemy_manager.all_enemies_defeated.connect(_on_all_enemies_defeated)
	player_manager.lives_depleted.connect(_on_lives_depleted)


func _connect_ready() -> void:
	if ready_button and not ready_button.pressed.is_connected(_on_ready_pressed):
		ready_button.pressed.connect(_on_ready_pressed)


func _on_ready_pressed() -> void:
	if _started:
		return
	_started = true
	var wave := 0 if enemy_controller.total_waves == 0 else 1
	enemy_controller.start_wave(wave)


## 全部已生成敌人被击杀
func _on_all_enemies_defeated() -> void:
	if _settled:
		return
	if not enemy_controller.all_spawned():
		return

	player_manager.add_fragments(wave_controller.wave_clear_fragments)

	# Buff 波次过期 — 每波结束时 tick 所有容器的 buff
	if buff_emitter:
		buff_emitter.tick_all_waves()

	if enemy_controller.total_waves == 0:
		_settle(true)
		return

	if enemy_controller.current_wave >= enemy_controller.total_waves:
		_settle(true)
	else:
		enemy_controller.start_wave(enemy_controller.current_wave + 1)


## 血量归零
func _on_lives_depleted() -> void:
	if _settled:
		return
	_settle(false)


func _settle(is_win: bool) -> void:
	_settled = true
	if buff_emitter:
		buff_emitter.disconnect_all()
	enemy_controller.stop_wave()
	game_over.emit(is_win)
