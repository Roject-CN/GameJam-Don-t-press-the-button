extends Control
class_name HUD

## HUD 主控 — 监听 GlobalManager 信号驱动 UI 显示
## 持有所有 HUD 子节点的引用，负责 Ready 按钮 / 命数 / 结算显示

@export var level_controller: LevelController
@export var defense_manager: DefenceManager
@export var logic_grid: TileMapLayer
@export var global_manager: GlobalManager

@onready var ready_button: Button = $Ready
@onready var game_over_label: Label = $GameOverLabel
@onready var lives_label: Label = $LivesLabel


func _ready() -> void:
	game_over_label.visible = false

	if global_manager:
		global_manager.lives_changed.connect(_on_lives_changed)
		global_manager.wave_started.connect(_on_wave_started)
		global_manager.game_over.connect(_on_game_over)
		global_manager.ready_button = ready_button
		global_manager._connect_ready()
		_on_lives_changed(global_manager.lives, 0)


## 首波开始后隐藏 Ready 按钮
func _on_wave_started(_wave: int) -> void:
	ready_button.visible = false


func _on_lives_changed(lives_left: int, _lost: int) -> void:
	lives_label.text = "命: %d" % lives_left


## 胜 / 负结算显示
func _on_game_over(is_win: bool) -> void:
	game_over_label.text = "you_win" if is_win else "you_lose"
	game_over_label.visible = true
