extends Node2D
class_name GlobalManager

## 全局游戏管理器 — 纯后端信号 hub

@export var enemy_container: EnemyContainer
@export var wave_controller: WaveController
@export var buff_emitter: BuffEmitter
@export var player_container: PlayerContainer

var ready_button: Button

@export var start_fragments: int = 100
@export var max_lives: int = 90

var current_wave: int = 0
var fragments: int
var lives: int
var _started: bool = false
var _settled: bool = false

signal lives_changed(lives_left: int, lost: int)
signal wave_started(wave: int)
signal game_over(is_win: bool)


func _ready() -> void:
	fragments = start_fragments
	lives = max_lives

	enemy_container.battle_over.connect(_on_battle_over)
	player_container.life_lost.connect(_on_life_lost)


func _connect_ready() -> void:
	if ready_button and not ready_button.pressed.is_connected(_on_ready_pressed):
		ready_button.pressed.connect(_on_ready_pressed)


func _on_ready_pressed() -> void:
	if _started:
		return
	_started = true
	# total_waves == 0 表示纯时序模式，从 0 开始
	current_wave = 0 if wave_controller.total_waves == 0 else 1
	_start_wave()


func _start_wave() -> void:
	wave_started.emit(current_wave)
	if wave_controller:
		wave_controller.start_wave(current_wave)


func _on_battle_over() -> void:
	if _settled or not wave_controller:
		return
	if not wave_controller.all_spawned():
		return

	add_fragments(wave_controller.wave_clear_fragments)

	# 纯时序模式（无波次）：全部生成 + 全部死亡 = 胜利
	if wave_controller.total_waves == 0:
		_settle(true)
		return

	# 波次模式：推进下一波或最终结算
	if current_wave >= wave_controller.total_waves:
		_settle(true)
	else:
		current_wave += 1
		_start_wave()


func _on_life_lost(amount: int) -> void:
	if _settled:
		return
	lives -= amount
	lives_changed.emit(lives, amount)
	if lives <= 0:
		_settle(false)


func _settle(is_win: bool) -> void:
	_settled = true
	if buff_emitter:
		buff_emitter.disconnect_all()
	if wave_controller:
		wave_controller.stop_wave()
	game_over.emit(is_win)


func add_fragments(amount: int) -> void:
	fragments += amount


func spend_fragments(amount: int) -> bool:
	if fragments < amount:
		return false
	fragments -= amount
	return true
