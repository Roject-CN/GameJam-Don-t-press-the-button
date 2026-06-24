extends BaseDefense
class_name PhishingWindowDefense

## 钓鱼窗口 — 引诱范围内敌人改向，承受点击后销毁

@export var live_count: int = 10

@export var taunt_radius: float = 150.0

@onready var base_button: BaseClickedButton = $BaseButton
@onready var counter_label: Label = $CounterLabel

var _life: int = live_count
var _taunt_active: bool = true
var _enemies : Array[BaseEnemy] = [null]
#signal defense_destroyed()

func _on_placed() -> void:
	area_node.area_entered.connect(_on_enemy_entered)
	base_button.button_clicked.connect(on_enemy_click)
	counter_label.text = "%d" % _life

func _on_enemy_entered(area: Area2D) -> void:
	if not _taunt_active:
		return

	var enemy := area.get_parent() as BaseEnemy
	if not enemy:
		return

	live_count -= enemy.click_times
	enemy.redirect_to(base_button)
	_enemies.append(enemy)
	if live_count <= 0:
		modulate = Color.GRAY


## 敌人到达窗口后调用 — 敌人自己的 click_times 在 BaseEnemy 里处理
func on_enemy_click() -> void:
	_life -= 1
	counter_label.text = "%d" % _life
	if _life <= 0:
		_taunt_active = false
		for i in _enemies:
			if i :
				i.clear_taunt_target()
			
		var tween := create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 2)
		tween.tween_callback(queue_free)
