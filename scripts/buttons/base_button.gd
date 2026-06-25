extends Node2D
class_name BaseClickedButton

## 桌面按钮 — 敌人寻路目标，点击后发射搭载的 BuffEffect

@onready var button: Button = $Button

## 按钮显示文本
@export var text: String

## 搭载的 BuffEffect 列表，点击时逐一发射
@export var buff_effect: Array[BuffEffect]

## 点击后发射，携带一条 BuffEffect（每条逐一发射）
signal buff_effect_applied(effect: BuffEffect)

## 按钮被点击时发射（先于 buff_effect_applied）
signal button_clicked


func _ready() -> void:
	button.text = text


## 模拟按下（由敌人 click 调用）
func press() -> void:
	button.button_pressed = true
	button.pressed.emit()


## 模拟释放
func release() -> void:
	button.button_pressed = false


func _on_button_pressed() -> void:
	button_clicked.emit()
	for effect in buff_effect:
		buff_effect_applied.emit(effect)
