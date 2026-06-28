extends CanvasLayer
class_name DialogueBox

## 对话框 UI — CanvasLayer 覆盖层，打字机效果 + 点击推进 + 内置指示框与相机聚焦
## 由 DialogueManager 实例化并驱动

# ── 外观自定义 ──
@export var panel_bg_color: Color = Color(0.08, 0.08, 0.12, 0.9)
@export var speaker_color: Color = Color(1.0, 0.76, 0.03)
@export var text_color: Color = Color.WHITE
@export var next_indicator_blink_interval: float = 0.5

## 指示框颜色（TODO: 占位符，后续替换为美工素材）
@export var indicator_color: Color = Color(1.0, 0.0, 0.0, 0.5)

## 动态指示框滑动时长（秒）
@export var indicator_move_duration: float = 1.5

## 动态指示框起止停顿时长（秒）
@export var indicator_pause_duration: float = 0.3

# ── 相机聚焦 ──
@export var enable_camera_focus: bool = true
@export var camera_target_zoom: Vector2 = Vector2(2.0, 2.0)
@export var zoom_in_duration: float = 0.4
@export var zoom_out_duration: float = 0.3

# ── 节点引用 ──
@onready var _panel: Panel = $Panel
@onready var _top_bar: HBoxContainer = $Panel/VBoxContainer/TopBar
@onready var _speaker_label: Label = $Panel/VBoxContainer/TopBar/SpeakerLabel
@onready var _separator: HSeparator = $Panel/VBoxContainer/HSeparator
@onready var _text_label: RichTextLabel = $Panel/VBoxContainer/MarginSpacer/TextLabel
@onready var _next_indicator: Label = $Panel/NextIndicator
@onready var _indicator: ColorRect = $TooltipIndicator	# 内置指示框

# ── 运行时状态 ──
var _current_sequence: DialogueSequence = null
var _current_index: int = 0
var _current_line: DialogueLine = null

# 打字机状态
var _full_text: String = ""
var _visible_chars: int = 0
var _typewriter_accum: float = 0.0
var _is_typing: bool = false

# 自动推进计时
var _auto_timer: float = 0.0
var _waiting_for_advance: bool = false

# 闪烁计时
var _blink_accum: float = 0.0
var _blink_visible: bool = true

# 指示框 + 相机状态
var _indicator_active: bool = false
var _focus_camera: Camera2D = null
var _original_camera: Camera2D = null
var _camera_tween: Tween = null

# 动态指示框动画状态
enum AnimPhase { PAUSE_START, MOVING, PAUSE_END, RESET }
var _indicator_animating: bool = false
var _indicator_start_pos: Vector2
var _indicator_end_pos: Vector2
var _indicator_phase: AnimPhase
var _indicator_phase_time: float = 0.0
var _indicator_size: Vector2

# 滑动手势状态（动态指示框）— 起点按下 → 拖到终点 → 松手关闭
var _swipe_active: bool = false

# ── 信号 ──

## 对话序列开始
signal dialogue_started(sequence_id: String)

## 新一行对话显示完毕（打字机完成），携带当前行号
signal line_displayed(line_index: int)

## 对话推进（from_line → to_line）
signal dialogue_advanced(from_line: int, to_line: int)

## 整段对话结束
signal dialogue_finished(sequence_id: String)


func _ready() -> void:
	visible = false
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_indicator.color = indicator_color
	_apply_style()


## 启动对话序列
func start_sequence(sequence: DialogueSequence) -> void:
	if not sequence or sequence.line_count() == 0:
		push_error("DialogueBox: 对话序列为空")
		return

	_current_sequence = sequence
	_current_index = 0
	visible = true
	dialogue_started.emit(sequence.sequence_id)
	_show_line(0)


func _apply_style() -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = panel_bg_color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	_panel.add_theme_stylebox_override("panel", style)

	_speaker_label.add_theme_color_override("font_color", speaker_color)
	_text_label.add_theme_color_override("default_color", text_color)


func _show_line(index: int) -> void:
	# 即时关闭上一行遗留的指示框
	_dismiss_indicator_immediate()

	var line: DialogueLine = _current_sequence.get_line(index)
	if not line:
		_finish()
		return

	_current_line = line

	# 更新说话人：无名字时隐藏顶栏和分隔线（旁白模式）
	if line.speaker_name.is_empty():
		_top_bar.visible = false
		_separator.visible = false
	else:
		_top_bar.visible = true
		_separator.visible = true
		_speaker_label.text = line.speaker_name

	# 更新对话框位置
	_panel.position = line.box_position

	# 启动打字机
	_full_text = line.text
	_visible_chars = 0
	_typewriter_accum = 0.0
	_text_label.text = _full_text
	_text_label.visible_characters = 0
	_is_typing = true
	_waiting_for_advance = false
	_auto_timer = 0.0

	# 隐藏继续提示
	_next_indicator.visible = false

	# 该行配置了指示框 → 显示小方块（静态或动态滑动）
	if line.tooltip_size != Vector2.ZERO:
		_show_indicator(line.tooltip_position, line.tooltip_size, line.tooltip_end_position)


func _process(_delta: float) -> void:
	# 指示框循环滑动动画（起停停顿 → 移动 → 终停停顿 → 消失复位）
	if _indicator_animating:
		_indicator_phase_time += _delta

		match _indicator_phase:
			AnimPhase.PAUSE_START:
				if _indicator_phase_time >= indicator_pause_duration:
					_indicator_phase = AnimPhase.MOVING
					_indicator_phase_time = 0.0

			AnimPhase.MOVING:
				_indicator.visible = true
				var t := minf(_indicator_phase_time / indicator_move_duration, 1.0)
				t = ease(t, -1.0)
				var cur := _indicator_start_pos.lerp(_indicator_end_pos, t)
				_indicator.offset_left = cur.x
				_indicator.offset_top = cur.y
				_indicator.offset_right = cur.x + _indicator_size.x
				_indicator.offset_bottom = cur.y + _indicator_size.y
				if t >= 1.0:
					_indicator_phase = AnimPhase.PAUSE_END
					_indicator_phase_time = 0.0

			AnimPhase.PAUSE_END:
				if _indicator_phase_time >= indicator_pause_duration:
					_indicator_phase = AnimPhase.RESET
					_indicator_phase_time = 0.0

			AnimPhase.RESET:
				_indicator.visible = false
				if _indicator_phase_time >= 0.15:
					_indicator.visible = true
					_indicator.offset_left = _indicator_start_pos.x
					_indicator.offset_top = _indicator_start_pos.y
					_indicator.offset_right = _indicator_start_pos.x + _indicator_size.x
					_indicator.offset_bottom = _indicator_start_pos.y + _indicator_size.y
					_indicator_phase = AnimPhase.PAUSE_START
					_indicator_phase_time = 0.0

	if not visible or not _current_sequence:
		return

	# 打字机效果
	if _is_typing:
		_typewriter_process(_delta)

	# 自动推进计时
	if _waiting_for_advance and _current_line and _current_line.auto_advance > 0:
		_auto_timer += _delta
		_blink_process(_delta)
		if _auto_timer >= _current_line.auto_advance:
			_advance()

	# 继续提示闪烁
	if _waiting_for_advance and _current_line and _current_line.auto_advance <= 0:
		_blink_process(_delta)


## 打字机逐字显示
func _typewriter_process(delta: float) -> void:
	if not _current_line:
		return
	var speed: float = _current_line.text_speed
	if speed <= 0.0:
		_text_label.visible_characters = -1
		_is_typing = false
		_on_typing_finished()
		return

	_typewriter_accum += delta
	while _typewriter_accum >= speed and _visible_chars < _full_text.length():
		_typewriter_accum -= speed
		_visible_chars += 1

	_text_label.visible_characters = _visible_chars

	if _visible_chars >= _full_text.length():
		_is_typing = false
		_on_typing_finished()


func _on_typing_finished() -> void:
	_waiting_for_advance = true
	_next_indicator.visible = true
	_blink_accum = 0.0
	_blink_visible = true
	line_displayed.emit(_current_index)


## "继续"箭头闪烁
func _blink_process(delta: float) -> void:
	_blink_accum += delta
	if _blink_accum >= next_indicator_blink_interval:
		_blink_accum -= next_indicator_blink_interval
		_blink_visible = not _blink_visible
		_next_indicator.visible = _blink_visible


## 输入处理 — 指示框活跃时封锁外部点击，必须与之交互才能继续
func _input(event: InputEvent) -> void:
	if not visible or not _current_sequence:
		return
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		return

	if event.pressed:
		# 动态指示框 → 检查是否在起点按下（启动滑动手势）
		if _indicator_active and _indicator_animating:
			var mouse := get_viewport().get_mouse_position()
			var tol := maxf(_indicator_size.x, _indicator_size.y)
			if mouse.distance_to(_indicator_start_pos) < tol:
				_swipe_active = true
			get_viewport().set_input_as_handled()
			return

		# 静态指示框 → 仅点击框内有效：关闭指示框 + 推进对话
		if _indicator_active and not _indicator_animating:
			if _is_mouse_on_indicator():
				_dismiss_indicator()
				if _is_typing:
					_text_label.visible_characters = -1
					_visible_chars = _full_text.length()
					_is_typing = false
					_on_typing_finished()
				elif _waiting_for_advance:
					_advance()
			get_viewport().set_input_as_handled()
			return

		# 无指示框 → 正常对话逻辑
		if _is_typing:
			_text_label.visible_characters = -1
			_visible_chars = _full_text.length()
			_is_typing = false
			_on_typing_finished()
			get_viewport().set_input_as_handled()
			return

		if _waiting_for_advance:
			get_viewport().set_input_as_handled()
			_advance()
	else:
		# 松开 — 滑动手势结束
		if _swipe_active:
			_swipe_active = false
			var mouse := get_viewport().get_mouse_position()
			var tol := maxf(_indicator_size.x, _indicator_size.y)
			if mouse.distance_to(_indicator_end_pos) < tol:
				_dismiss_indicator()
			get_viewport().set_input_as_handled()


func _is_mouse_on_indicator() -> bool:
	var mouse := get_viewport().get_mouse_position()
	return Rect2(_indicator.offset_left, _indicator.offset_top,
		_indicator.size.x, _indicator.size.y).has_point(mouse)


## 推进到下一条对话
func _advance() -> void:
	var prev_index: int = _current_index
	var next_index: int = _current_index + 1

	if next_index >= _current_sequence.line_count():
		_finish()
		return

	_current_index = next_index
	dialogue_advanced.emit(prev_index, next_index)
	_show_line(next_index)


## 结束对话序列
func _finish() -> void:
	_dismiss_indicator_immediate()

	var seq_id: String = _current_sequence.sequence_id if _current_sequence else ""
	_current_sequence = null
	_current_line = null
	_current_index = 0
	_is_typing = false
	_waiting_for_advance = false
	visible = false
	dialogue_finished.emit(seq_id)


## 跳过整段对话
func skip_all() -> void:
	_finish()


# ── 内置指示框 ──

func _show_indicator(pos: Vector2, size: Vector2, end_pos: Vector2 = Vector2.ZERO) -> void:
	_indicator_size = size
	_indicator.offset_left = pos.x
	_indicator.offset_top = pos.y
	_indicator.offset_right = pos.x + size.x
	_indicator.offset_bottom = pos.y + size.y
	_indicator.visible = true
	_indicator_active = true

	if end_pos != Vector2.ZERO:
		_indicator_animating = true
		_indicator_start_pos = pos
		_indicator_end_pos = end_pos
		_indicator_phase = AnimPhase.PAUSE_START
		_indicator_phase_time = 0.0

	if enable_camera_focus:
		_start_camera_focus(pos + size / 2.0)


func _dismiss_indicator() -> void:
	if not _indicator_active:
		return
	_indicator_active = false
	_indicator_animating = false
	_swipe_active = false
	if _focus_camera:
		_restore_camera()
	else:
		_indicator.visible = false


func _dismiss_indicator_immediate() -> void:
	if not _indicator_active:
		return
	_indicator_active = false
	_indicator_animating = false
	_swipe_active = false
	_indicator.visible = false
	_cleanup_camera()


# ── 相机聚焦 ──

func _start_camera_focus(target_world_pos: Vector2) -> void:
	if _focus_camera:
		_cleanup_camera()

	var viewport := get_viewport()
	_original_camera = viewport.get_camera_2d()

	var world_root := get_tree().current_scene
	if not world_root:
		return

	_focus_camera = Camera2D.new()
	_focus_camera.name = "FocusCamera"
	_focus_camera.anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	world_root.add_child(_focus_camera)

	if _original_camera:
		_focus_camera.global_position = _original_camera.global_position
	else:
		_focus_camera.global_position = viewport.get_visible_rect().size / 2.0
	_focus_camera.zoom = Vector2.ONE

	_focus_camera.make_current()
	if _original_camera:
		_original_camera.enabled = false

	_camera_tween = create_tween()
	_camera_tween.set_parallel(true)
	_camera_tween.tween_property(_focus_camera, "global_position", target_world_pos, zoom_in_duration) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_camera_tween.tween_property(_focus_camera, "zoom", camera_target_zoom, zoom_in_duration) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


func _restore_camera() -> void:
	if not _focus_camera or not is_instance_valid(_focus_camera):
		_cleanup_camera()
		_indicator.visible = false
		return

	var viewport := get_viewport()
	var restore_pos: Vector2
	if _original_camera and is_instance_valid(_original_camera):
		restore_pos = _original_camera.global_position
	else:
		restore_pos = viewport.get_visible_rect().size / 2.0

	_camera_tween = create_tween()
	_camera_tween.set_parallel(true)
	_camera_tween.tween_property(_focus_camera, "global_position", restore_pos, zoom_out_duration) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	_camera_tween.tween_property(_focus_camera, "zoom", Vector2.ONE, zoom_out_duration) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	_camera_tween.finished.connect(_on_camera_restored, CONNECT_ONE_SHOT)


func _on_camera_restored() -> void:
	_cleanup_camera()
	_indicator.visible = false


func _cleanup_camera() -> void:
	if _camera_tween and _camera_tween.is_valid():
		_camera_tween.kill()
		_camera_tween = null
	if _focus_camera and is_instance_valid(_focus_camera):
		_focus_camera.enabled = false
		_focus_camera.queue_free()
		_focus_camera = null
	if _original_camera and is_instance_valid(_original_camera):
		_original_camera.enabled = true
		_original_camera = null
