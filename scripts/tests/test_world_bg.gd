extends Node2D
## 测试用世界背景 — 绘制彩色方块和网格，验证相机缩放聚焦效果可见

func _draw() -> void:
	# 彩色方块
	draw_rect(Rect2(100, 80, 160, 160), Color(0.9, 0.2, 0.2, 0.6))
	draw_rect(Rect2(400, 120, 160, 160), Color(0.2, 0.5, 0.9, 0.6))
	draw_rect(Rect2(250, 350, 160, 160), Color(0.2, 0.8, 0.3, 0.6))
	draw_rect(Rect2(700, 200, 160, 160), Color(0.9, 0.8, 0.1, 0.6))
	draw_rect(Rect2(850, 480, 200, 140), Color(0.8, 0.3, 0.8, 0.6))

	# 网格线
	for i in range(0, 1300, 100):
		draw_line(Vector2(i, 0), Vector2(i, 720), Color(0.3, 0.3, 0.3, 0.4), 1.0)
	for i in range(0, 800, 100):
		draw_line(Vector2(0, i), Vector2(1280, i), Color(0.3, 0.3, 0.3, 0.4), 1.0)

	# 十字标记视口中心
	draw_line(Vector2(630, 360), Vector2(650, 360), Color.WHITE, 2.0)
	draw_line(Vector2(640, 350), Vector2(640, 370), Color.WHITE, 2.0)
