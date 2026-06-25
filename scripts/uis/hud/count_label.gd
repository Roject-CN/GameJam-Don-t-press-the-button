extends Control

class_name ConutLabel

@onready var left_label:Label = $GridContainer/CurrentCount
@onready var right_label:Label =$GridContainer/SumCount

@onready var current_wave_label:Label =$GridContainer/CurrentWave
@onready var total_wave_label:Label =$GridContainer/SumWave
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
	left_label.text =str(num)

func set_total(num:int):
	right_label.text =str(num)

func set_total_wave(num:int):
	total_wave_label.text =str(num)
	
func on_wave_changed(num:int):
	current_wave_label.text =str(num)
