extends Node2D
class_name SpawnMarker

## 关卡标记点 — 被 WaveEntry.spawn_point / target_point 按名称匹配
## 放置在关卡场景中，编辑器中显示彩色圆圈

## 编辑器标记颜色
@export var marker_color: Color = Color.RED:
	set(v):
		marker_color = v
		queue_redraw()


## 编辑器预览圆圈
func _draw() -> void:
	if Engine.is_editor_hint():
		draw_circle(Vector2.ZERO, 8.0, marker_color)
		draw_circle(Vector2.ZERO, 4.0, Color.WHITE)
