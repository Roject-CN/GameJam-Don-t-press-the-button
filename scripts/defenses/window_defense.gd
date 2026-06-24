extends BaseDefense
class_name PhishingWindowDefense

## 钓鱼窗口 — 双层区域防御
## 外层 Area（继承自 BaseDefense）：敌人进入 → 导航重定向到窗口中心
## 内层 AreaClick：敌人进入 → 秒杀，消耗 lure_count

## 可引诱次数（耗尽后销毁）
@export var lure_count: int = 5

@onready var area_click: Area2D = $AreaClick
@onready var counter_label: Label = $CounterLabel

var _remaining: int = lure_count
var _active: bool = true


func _on_placed() -> void:
	area_node.area_entered.connect(_on_lure)
	area_click.area_entered.connect(_on_kill)
	counter_label.text = "%d" % _remaining


## 外层吸引：重定向敌人导航到窗口位置
func _on_lure(area: Area2D) -> void:
	if not _active:
		return
	var enemy := area.get_parent() as BaseEnemy
	if not enemy:
		return
	enemy._navigate_to(global_position)


## 内层击杀：秒杀敌人，计数耗尽后变灰淡出
func _on_kill(area: Area2D) -> void:
	if not _active:
		return
	var enemy := area.get_parent() as BaseEnemy
	if not enemy:
		return

	enemy.free_self()
	_remaining -= 1
	counter_label.text = "%d" % _remaining

	if _remaining <= 0:
		_active = false
		modulate = Color.GRAY
		var tween := create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 2)
		tween.tween_callback(queue_free)
