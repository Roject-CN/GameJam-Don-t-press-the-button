extends Control
class_name HUD

## HUD 主控 — 连接 EnemyController / PlayerContainer / GlobalManager 信号驱动 UI

@export var level_controller: LevelController
@export var defense_manager: DefenceManager
@export var logic_grid: TileMapLayer
@export var global_manager: GlobalManager
@export var player_container: PlayerContainer
@export var enemy_controller: EnemyController

@onready var ready_button: Button = $Ready
@onready var game_over_label: Label = $GameOverLabel
@onready var lives_label: Label = $LivesLabel
@onready var count_label: ConutLabel = $CountLabel


func _ready() -> void:
	game_over_label.visible = false

	if global_manager:
		global_manager.game_over.connect(_on_game_over)
		global_manager.ready_button = ready_button
		global_manager._connect_ready()

	if enemy_controller:
		enemy_controller.wave_changed.connect(_on_wave_changed)

	if player_container:
		player_container.life_lost.connect(_on_life_lost)
		player_container.fragments_changed.connect(_on_fragments_changed)
		_on_life_lost(0)
		_on_fragments_changed(player_container.fragments)

	if count_label and enemy_controller:
		enemy_controller.enemies_killed_count_changed.connect(count_label.on_killed_count_changed)
		enemy_controller.wave_changed.connect(count_label.on_wave_changed)
		count_label.set_total(enemy_controller.total_enemy)
		count_label.set_total_wave(enemy_controller.total_waves)


## 波次切换
func _on_wave_changed(_wave: int) -> void:
	ready_button.visible = false


func _on_life_lost(_amount: int) -> void:
	if player_container:
		lives_label.text = "命: %d" % player_container.current_lives


func _on_fragments_changed(_new_amount: int) -> void:
	pass  # TODO: 碎片 UI 显示


func _on_game_over(is_win: bool) -> void:
	game_over_label.text = "you_win" if is_win else "you_lose"
	game_over_label.visible = true
