extends Node2D
class_name GlobalManager

## 全局信号路由 — 连接各模块信号，不持有业务状态

@export var enemy_container: EnemyContainer
@export var wave_controller: WaveController
@export var buff_emitter: BuffEmitter
@export var player_container: PlayerContainer

var ready_button: Button

var current_wave: int = 0
var _started: bool = false
var _settled: bool = false

signal wave_started(wave: int)
signal game_over(is_win: bool)

func _ready() -> void:
	enemy_container.all_enemies_defeated.connect(_on_all_enemies_defeated)
	player_container.lives_depleted.connect(_on_lives_depleted)


func _connect_ready() -> void:
	if ready_button and not ready_button.pressed.is_connected(_on_ready_pressed):
		ready_button.pressed.connect(_on_ready_pressed)


func _on_ready_pressed() -> void:
	if _started:
		return
	_started = true
	current_wave = 0 if wave_controller.total_waves == 0 else 1
	_start_wave()


func _start_wave() -> void:
	wave_started.emit(current_wave)
	if wave_controller:
		wave_controller.start_wave(current_wave)


## 全部已生成敌人被击杀
func _on_all_enemies_defeated() -> void:
	if _settled or not wave_controller:
		return
	if not wave_controller.all_spawned():
		return  # 波次未生成完，等后续生成

	player_container.add_fragments(wave_controller.wave_clear_fragments)

	if wave_controller.total_waves == 0:
		_settle(true)
		return

	if current_wave >= wave_controller.total_waves:
		_settle(true)
	else:
		current_wave += 1
		_start_wave()


## 血量归零
func _on_lives_depleted() -> void:
	if _settled:
		return
	_settle(false)


func _settle(is_win: bool) -> void:
	_settled = true
	if buff_emitter:
		buff_emitter.disconnect_all()
	if wave_controller:
		wave_controller.stop_wave()
	game_over.emit(is_win)
