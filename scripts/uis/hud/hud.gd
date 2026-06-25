extends Control
class_name HUD

## HUD 主控 — 连接 PlayerContainer / GlobalManager 信号驱动 UI

@export var level_controller: LevelController
@export var defense_manager: DefenceManager
@export var logic_grid: TileMapLayer
@export var global_manager: GlobalManager
@export var player_container: PlayerContainer

@onready var ready_button: Button = $Ready
@onready var game_over_label: Label = $GameOverLabel
@onready var lives_label: Label = $LivesLabel
@onready var count_label:ConutLabel =$CountLabel

func _ready() -> void:
	game_over_label.visible = false

	if global_manager:
		global_manager.wave_started.connect(_on_wave_started)
		global_manager.game_over.connect(_on_game_over)
		global_manager.ready_button = ready_button
		global_manager._connect_ready()

	if player_container:
		player_container.life_lost.connect(_on_life_lost)
		player_container.fragments_changed.connect(_on_fragments_changed)
		# 初始显示
		_on_life_lost(0)  # 用 0 loss 触发首次刷新
		_on_fragments_changed(player_container.fragments)
	if count_label:
		global_manager.enemy_container.enemies_killed_count_changed.connect(
			count_label.on_killed_count_changed)
## 首波开始后隐藏 Ready 按钮
func _on_wave_started(_wave: int) -> void:
	ready_button.visible = false


func _on_life_lost(_amount: int) -> void:
	if player_container:
		lives_label.text = "命: %d" % player_container.current_lives


func _on_fragments_changed(new_amount: int) -> void:
	pass  # TODO: 碎片 UI 显示


## 胜 / 负结算显示
func _on_game_over(is_win: bool) -> void:
	game_over_label.text = "you_win" if is_win else "you_lose"
	game_over_label.visible = true
