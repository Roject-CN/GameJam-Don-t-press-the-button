extends Node2D
class_name BaseClickedButton

@onready var button: Button = $Button

@export var text : String
@export var buff_effect : Array[BuffEffect]

signal buff_effect_applied(effect: BuffEffect)


func _ready() -> void:
	button.text = text

func press() -> void:
	button.button_pressed = true
	button.pressed.emit()

func release() -> void:
	button.button_pressed = false

func _on_button_pressed() -> void:
	for effect in buff_effect:
		buff_effect_applied.emit(effect)
