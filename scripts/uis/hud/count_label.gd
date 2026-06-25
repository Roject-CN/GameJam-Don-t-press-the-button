extends Control

class_name ConutLabel

@onready var left_label:Label = $HBoxContainer/CurrentCount
@onready var right_label:Label =$HBoxContainer/SumCount
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func on_left_label_changed(str:String):
	left_label.text =str
	
func on_right_label_changed(str:String):
	right_label.text =str

func on_killed_count_changed(num:int):
	right_label.text =str(num)
