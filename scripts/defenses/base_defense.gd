extends Node2D
class_name BaseDefense

## 防御工事基类 — ghost 半透明跟随鼠标 + 点击放置 + 子类覆写 _on_placed

## 放置消耗碎片
@export var cost: int = 0

## 防御名称（UI 显示）
@export var defense_name: String = ""

## 是否已正式放置（false 时 _process 持续跟随鼠标）
var is_placed: bool = false

@onready var area_node: Area2D = $Area


func _process(_delta: float) -> void:
	if not is_placed:
		_ghost()


## 半透明跟随鼠标
func _ghost() -> void:
	global_position = get_global_mouse_position()
	modulate.a = 0.5


## 正式放置：恢复不透明，触发子类钩子
func place() -> void:
	is_placed = true
	modulate.a = 1.0
	_on_placed()

#用于更新自身的UI，比如说钓鱼窗口加buff之后需要第一时间更新自己的点击数
func fresh() -> void:
	pass

## 子类覆写点 — 放置后初始化（连接信号等）
func _on_placed() -> void:
	pass
