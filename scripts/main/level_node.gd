extends Control
class_name LevelNode

## 选关地图上的关卡图标，模仿 ThemeButton 的三态 + 贝塞尔虚线连线

@export var next_level_node: LevelNode:
	set(v):
		next_level_node = v
		queue_redraw()
@export var level_info: LevelInfo

signal level_selected(info: LevelInfo)
signal request_open_tooltip(text: String)
signal request_close_tooltip()

@onready var button: TextureRect = $Button
@onready var label: Label = $Button/Label

@onready var self_pos: Control = $self_pos
@onready var next_pos: Control = $next_pos

var tween: Tween
var _current_state: String = "locked"  # locked / available / completed


func _ready() -> void:
	if label and level_info:
		label.text = level_info.level_name

	# 编辑器模式：跳过运行时逻辑
	if Engine.is_editor_hint():
		show()
		queue_redraw()
		return

	# 从存档读取初始状态
	if level_info:
		_current_state = SaveManager.get_level_state(level_info.level_id)

	# 第一个关卡（没有前置）默认至少 available
	if _current_state == "locked" and not _has_previous():
		_current_state = "available"

	_update_anchors()
	_apply_state()
	queue_redraw()
	show()


func _update_anchors() -> void:
	if not button:
		return
	# 连线锚点：next_pos=右中, self_pos=左中
	next_pos.position.x = button.size.x
	next_pos.position.y = button.size.y / 2.0
	self_pos.position.x = 0.0
	self_pos.position.y = button.size.y / 2.0


## 检测是否有前置关卡指向自己
func _has_previous() -> bool:
	var parent_ctrl := get_parent()
	if parent_ctrl == null:
		return false
	for child in parent_ctrl.get_children():
		if child is LevelNode and child.next_level_node == self:
			return true
	return false


func _apply_state() -> void:
	if Engine.is_editor_hint():
		return
	match _current_state:
		"locked":
			set_locked()
		"available":
			set_available()
		"completed":
			set_completed()


func set_locked() -> void:
	cease_animation()
	button.modulate = Color("595959ff")
	button.scale = Vector2(1.0, 1.0)


func set_available() -> void:
	button.modulate = Color("ffffffff")
	cease_animation()
	_start_blink()


func _start_blink() -> void:
	if _current_state != "available":
		return
	var blink_tween := get_tree().create_tween()
	blink_tween.set_ease(Tween.EASE_IN_OUT)
	blink_tween.set_trans(Tween.TRANS_SINE)
	blink_tween.tween_property(button, "modulate:a", 0.7, 0.8)
	blink_tween.parallel().tween_property(button, "scale", Vector2.ONE * 0.95, 0.8)
	blink_tween.tween_property(button, "modulate:a", 1.0, 0.8)
	blink_tween.parallel().tween_property(button, "scale", Vector2.ONE * 1.1, 0.8)
	blink_tween.finished.connect(_start_blink, CONNECT_ONE_SHOT)
	tween = blink_tween


func set_completed() -> void:
	cease_animation()
	button.modulate = Color("d9d9d9ff")
	button.scale = Vector2(1.0, 1.0)


func cease_animation() -> void:
	if tween and tween.is_valid():
		tween.kill()


## 画贝塞尔虚线到下一关
func _draw() -> void:
	if next_level_node == null:
		return

	_update_anchors()

	var start: Vector2 = $next_pos.position if has_node("next_pos") else Vector2.ZERO
	var end_local: Vector2

	if next_level_node.has_node("self_pos"):
		var end_global: Vector2 = next_level_node.self_pos.global_position
		end_local = get_global_transform().affine_inverse() * end_global
	else:
		var btn_size: Vector2 = button.size if button else Vector2(64, 64)
		var end_global: Vector2 = next_level_node.global_position
		end_local = get_global_transform().affine_inverse() * end_global + Vector2(btn_size.x / 2.0, btn_size.y / 2.0)

	draw_dashed_bezier(start, end_local)


func draw_dashed_bezier(start: Vector2, end: Vector2,
						dash_length: float = 8.0, gap_length: float = 4.0,
						color: Color = Color.BLACK, width: float = 2.0) -> void:
	var mid_x := (start.x + end.x) * 0.5
	# Y 偏移：距离的 25%，让水平连线也有弧度
	var bulge: float = abs(end.x - start.x) * 0.25
	var ctrl1 := Vector2(mid_x, start.y - bulge)
	var ctrl2 := Vector2(mid_x, end.y + bulge)

	var segments := 30
	var points: PackedVector2Array = []
	for i in range(segments + 1):
		var t := float(i) / segments
		var p := start * (1-t)*(1-t)*(1-t) + ctrl1 * 3 * (1-t)*(1-t) * t \
				 + ctrl2 * 3 * (1-t) * t * t + end * t*t*t
		points.append(p)

	var remaining := 0.0
	var drawing := true

	for i in range(points.size() - 1):
		var p1 := points[i]
		var p2 := points[i+1]
		var seg_vector := p2 - p1
		var seg_length := seg_vector.length()
		if seg_length == 0:
			continue
		var direction := seg_vector.normalized()
		var pos := p1

		while seg_length > 0:
			if drawing:
				var draw_len := minf(seg_length, dash_length - remaining)
				draw_line(pos, pos + direction * draw_len, color, width)
				pos += direction * draw_len
				seg_length -= draw_len
				remaining += draw_len
				if remaining >= dash_length:
					remaining = 0.0
					drawing = false
			else:
				var skip_len := minf(seg_length, gap_length - remaining)
				pos += direction * skip_len
				seg_length -= skip_len
				remaining += skip_len
				if remaining >= gap_length:
					remaining = 0.0
					drawing = true


func _on_button_gui_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if _current_state == "locked" and level_info:
				_show_locked_dialog()
			elif level_info:
				level_selected.emit(level_info)


func _show_locked_dialog() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "未解锁"
	dialog.dialog_text = "请先完成前置关卡！"
	add_child(dialog)
	dialog.popup_centered()


func _on_button_mouse_entered() -> void:
	if Engine.is_editor_hint():
		return
	if level_info:
		var desc := level_info.description
		if desc != "":
			request_open_tooltip.emit(desc)


func _on_button_mouse_exited() -> void:
	if Engine.is_editor_hint():
		return
	request_close_tooltip.emit()


## 由 LevelSelect 调用来刷新布局
func refresh_state() -> void:
	if level_info:
		_current_state = SaveManager.get_level_state(level_info.level_id)
	if _current_state == "locked" and not _has_previous():
		_current_state = "available"
	_apply_state()
	queue_redraw()
