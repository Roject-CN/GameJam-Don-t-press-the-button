extends Control

@export var level_controller:LevelController
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
func _on_button_debug_a():
	level_controller.change_level_to("res://scenes/levels/tutorial_level_1.tscn")
func _on_button_debug_b():
	level_controller.change_level_to("res://scenes/levels/tutorial_level_2.tscn")
