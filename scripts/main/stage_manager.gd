extends Node2D
class_name StageManager

"""获取各个模块的引用然后直接在我们这个状态机里面调用，
各个模块只是提供相应的接口"""
# 游戏阶段
enum Stage { BUILD, BATTLE, SETTLE }

@onready var ready_botton: Button = $"../Ui/Ready"
@onready var timer: Timer = $"../Timer"


# 模块引用 — 编辑器中手动拖入
@export var enemy_container: EnemyContainer
@export var buff_emitter : BuffEmitter


# 可配置参数
@export var total_waves: int = 5
@export var start_fragments: int = 100
@export var wave_clear_fragments: int = 50
@export var early_ready_bonus: int = 20
@export var max_lives: int = 3

# 运行时状态
var current_stage: Stage = Stage.BUILD
var current_wave: int = 0
var fragments: int
var lives: int

# 信号
signal fragments_changed(new_amount: int)
signal lives_changed(lives_left: int, lost: int)
signal game_won
signal game_lost



func _ready() -> void:
	fragments = start_fragments
	lives = max_lives
	_enter_stage(current_stage)


# 阶段切换中枢

func change_stage(new_stage: Stage) -> void:
	if new_stage == current_stage:
		return
	var old := current_stage
	_exit_stage(old)
	current_stage = new_stage
	_enter_stage(new_stage)

#我们利用一些条件的触发，去执行切换状态函数，比如准备开始的按钮/倒计时结束

# BUILD — 进入时激活按钮 / 退出时不做特殊处理
func _enter_build() -> void:
	ready_botton.visible = true
	if not ready_botton.pressed.is_connected(start_battle):
		ready_botton.pressed.connect(start_battle)
	if not timer.timeout.is_connected(start_battle):
		timer.timeout.connect(start_battle)
	timer.start()

func _exit_build() -> void:
	ready_botton.visible = false
	timer.timeout.disconnect(start_battle)
	enemy_container.enemies_spawn(5)

# BATTLE — 进入时开始出怪 / 退出时停止出怪 + Buff 倒计数
func _enter_battle() -> void:
	enemy_container.battle_overd.connect(end_battle)
func _exit_battle() -> void:
	print("exit battle")

# SETTLE
func _enter_settle() -> void:
	if buff_emitter:
		buff_emitter.disconnect_all()
	print("game over")

func _exit_settle() -> void:
	pass

# 阶段路由（match 分发）
func _enter_stage(stage: Stage) -> void:
	match stage:
		Stage.BUILD:  _enter_build()
		Stage.BATTLE: _enter_battle()
		Stage.SETTLE: _enter_settle()


func _exit_stage(stage: Stage) -> void:
	match stage:
		Stage.BUILD:  _exit_build()
		Stage.BATTLE: _exit_battle()
		Stage.SETTLE: _exit_settle()



func start_battle() -> void:
	if current_stage != Stage.BUILD:
		return
	current_wave += 1
	change_stage(Stage.BATTLE)


func end_battle() -> void:
	if current_stage != Stage.BATTLE:
		return
	add_fragments(wave_clear_fragments)
	if current_wave >= total_waves:
		_settle(true)
	else:
		change_stage(Stage.BUILD)


func lose_life(amount: int = 1) -> void:
	lives -= amount
	lives_changed.emit(lives, amount)
	if lives <= 0:
		_settle(false)


func _settle(is_win: bool) -> void:
	change_stage(Stage.SETTLE)
	if is_win:
		game_won.emit()
	else:
		game_lost.emit()


func add_fragments(amount: int) -> void:
	fragments += amount
	fragments_changed.emit(fragments)
