extends BaseDefense
class_name WindowDefense

## 钓鱼窗口 — 双层区域防御
## 外层 Area（继承自 BaseDefense）：敌人进入 → 导航重定向到窗口中心
## 内层 AreaClick：敌人进入 → 秒杀，消耗 lure_count

## 可引诱次数（耗尽后销毁）
@export var lure_count: int = 5

@onready var base_button: BaseClickedButton = $BaseButton
@onready var counter_label: Label = $CounterLabel

var _remaining: int
var _active: bool = true

func _ready() -> void:
	_remaining = lure_count
	counter_label.text = "%d" % _remaining

func _on_placed() -> void:
	area_node.area_entered.connect(_on_lure)
	base_button.button_clicked.connect(_on_clicked)
	# 延迟一帧等待物理服务器完成 AABB 更新，再手动收集已重叠的敌人
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
	redirect(enemy)

func redirect(enemy : BaseEnemy) -> void:
	enemy.redirect_to(base_button.global_position)


## 内层击杀：秒杀敌人，计数耗尽后变灰淡出
func _on_clicked() -> void:
	if not _active:
		return

	_remaining -= 1
	counter_label.text = "%d" % _remaining

	if _remaining <= 0:
		_active = false
		modulate = Color.GRAY
		var tween := create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 2)
		tween.tween_callback(queue_free)
