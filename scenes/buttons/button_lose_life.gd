extends BaseClickedButton
@onready var sprite := $AnimatedSprite2D

func _on_button_pressed() -> void:
	super._on_button_pressed()
	sprite.stop()
	sprite.play("click")
