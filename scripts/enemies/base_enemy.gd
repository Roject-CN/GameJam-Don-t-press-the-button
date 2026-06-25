extends Node2D
class_name BaseEnemy

## 敌人基类 — 位置驱动寻路，从生成点 → 目标点，到达后点击附近按钮

# 节点引用
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var area_2d: Area2D = $Area2D
@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D

# 属性（编辑器默认值，可由 EnemyConfig 覆盖）
@export var speed: float = 200.0
@export var health: int = 1
@export var click_times: int = 2:
	set(v):
		click_times = v
		if click_times <= 0:
			free_self()
		elif _setup_done:
			_navigate_to(_target_pos)
@export var taunt_resistance: float = 0.0

## 到达目标后搜索按钮的范围
@export var click_range: float = 50.0

# 外部注入
var buttons_container: Node2D
var config: EnemyConfig = null

# 寻路状态
var _target_pos: Vector2
var _setup_done: bool = false

# 被引诱状态
var taunt_target: BaseClickedButton = null

signal enemy_died()


func _ready() -> void:
	if config:
		_apply_config()
		_navigate_to(_target_pos)
		_setup_done = true


## WaveController 调用：存储配置 + 目标，_ready 中启动寻路
func setup(p_config: EnemyConfig, p_target_pos: Vector2) -> void:
	config = p_config
	_target_pos = p_target_pos
	if is_inside_tree():
		_apply_config()
		_navigate_to(_target_pos)
		_setup_done = true


func _apply_config() -> void:
	if not config:
		return
	speed = config.speed if config.speed > 0 else speed
	health = config.health if config.health > 0 else health
	click_times = config.click_times
	taunt_resistance = config.taunt_resistance


func _navigate_to(pos: Vector2) -> void:
	navigation_agent_2d.target_position = pos


## 钓鱼窗口引诱 — 重定向到按钮位置
func redirect_to(target: BaseClickedButton) -> void:
	taunt_target = target
	_navigate_to(target.global_position)


func clear_taunt_target() -> void:
	taunt_target = null
	_navigate_to(_target_pos)


func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		free_self()


## 到达目标后查找附近按钮并点击（taunt 目标优先）
func _try_click() -> void:
	var btn: BaseClickedButton = null

	# 被引诱时优先点击引诱目标按钮
	if taunt_target and taunt_target.global_position.distance_to(global_position) <= click_range:
		btn = taunt_target
	else:
		btn = _find_nearest_button(global_position)
		if btn and btn.global_position.distance_to(global_position) > click_range:
			btn = null

	if btn:
		_click_button(btn)


func _click_button(btn: BaseClickedButton) -> void:
	animation_player.play("clicked")
	btn.press()
	await animation_player.animation_finished
	btn.release()
	click_times -= 1
	if click_times > 0:
		_navigate_to(_target_pos)


func _find_nearest_button(pos: Vector2) -> BaseClickedButton:
	if not buttons_container:
		return null
	var best: BaseClickedButton = null
	var best_dist := INF
	for child in buttons_container.get_children():
		var btn := child as BaseClickedButton
		if not btn:
			continue
		var d := btn.global_position.distance_squared_to(pos)
		if d < best_dist:
			best_dist = d
			best = btn
	return best


func free_self() -> void:
	animation_player.play("free")
	await animation_player.animation_finished
	enemy_died.emit()
	call_deferred("queue_free")


func _physics_process(delta: float) -> void:
	if not _setup_done:
		return
	if navigation_agent_2d.is_navigation_finished():
		return

	var next_pos := navigation_agent_2d.get_next_path_position() - global_position
	var velocity := next_pos.normalized() * speed
	position += velocity * delta


func _on_navigation_agent_2d_navigation_finished() -> void:
	_try_click()
