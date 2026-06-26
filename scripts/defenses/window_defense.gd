extends BaseDefense
class_name WindowDefense

## 钓鱼窗口 — 双层区域防御
## 外层 Area（继承自 BaseDefense）：敌人进入 → 导航重定向到窗口中心
## 内层 AreaClick：敌人进入 → 秒杀，消耗 lure_count

## 可引诱次数（耗尽后销毁）
@export var lure_count: int = 5

@onready var base_button: BaseClickedButton = $BaseButton
@onready var counter_label: Label = $CounterLabel

var _used: int = 0
var _active: bool = true

func _ready() -> void:
	counter_label.text = "%d" % lure_count

func _on_placed() -> void:
	area_node.area_entered.connect(_on_lure)
	base_button.button_clicked.connect(_on_clicked)
	await get_tree().physics_frame
	for area in area_node.get_overlapping_areas():
		_on_lure(area)


## 外层吸引：重定向敌人导航到窗口位置
func _on_lure(area: Area2D) -> void:
	if not _active:
		return
	var enemy := area.get_parent() as BaseEnemy
	if not enemy:
		return
	# 挑衅抵抗判定：randf() < taunt_resistance 则抵抗成功，不引诱
	if randf() < enemy.taunt_resistance:
		return
	redirect(enemy)

func redirect(enemy : BaseEnemy) -> void:
	enemy.redirect_to(base_button.global_position)


## 内层击杀：秒杀敌人，计数耗尽后变灰淡出
func _on_clicked() -> void:
	if not _active:
		return

	_used += 1
	var remaining := lure_count - _used
	counter_label.text = "%d" % remaining

	if remaining <= 0:
		_active = false
		modulate = Color.GRAY
		var tween := create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 2)
		tween.tween_callback(queue_free)
