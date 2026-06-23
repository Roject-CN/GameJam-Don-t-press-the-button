extends Node2D
class_name BaseEnemy

#引用部分
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var area_2d: Area2D = $Area2D
@onready var collision_shape_2d: CollisionShape2D = $Area2D/CollisionShape2D
@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D

#属性值部分
@export var health : int = 1 #生命值
@export var click_times : int = 2 : #点击 x 次后触发free_self()
	set(value):
		click_times = value
		if click_times <= 0:
			free_self()
		else:
			navigation()
@export var speed := 200 #移动的基础速度

signal enemy_died()

#当前寻路的按钮
var current_button : BaseClickedButton :
	set(value):
		current_button = value
		navigation_agent_2d.target_position = current_button.global_position

func _ready() -> void:
	navigation()


#寻路机制 从全局组 ClickedButtons 中随机选取一个按钮作为目标
func navigation() -> void:
	var buttons = get_tree().get_nodes_in_group("ClickedButtons").duplicate(true)
	if not buttons:
		assert(false, "Global Group ClickedButtons doesn't exist")

	current_button = buttons[randi_range(0, buttons.size() - 1)]


func click() -> void:
	animation_player.play("clicked")
	current_button.press()
	await animation_player.animation_finished
	current_button.release()
	click_times -= 1


#敌人的删除函数 在点击按钮/被消灭之后触发的函数
func free_self() -> void:
	animation_player.play("free")
	await animation_player.animation_finished
	enemy_died.emit()
	call_deferred("queue_free")


func _physics_process(delta: float) -> void:
	if not current_button or navigation_agent_2d.is_navigation_finished():
		return

	var next_pos = navigation_agent_2d.get_next_path_position() - self.global_position
	var velocity = next_pos.normalized() * speed
	self.position += velocity * delta


func _on_navigation_agent_2d_navigation_finished() -> void:
	click()
