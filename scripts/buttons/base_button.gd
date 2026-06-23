extends Node2D
class_name BaseClickedButton

@onready var button: Button = $Button

@export var text : String

func _ready() -> void:
	button.text = text

func press() -> void:
	button.button_pressed = true

func release() -> void:
	button.button_pressed = false

func _on_button_pressed() -> void:
	pass
