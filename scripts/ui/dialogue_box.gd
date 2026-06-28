extends CanvasLayer
class_name DialogueBox

## 对话框 UI — CanvasLayer 覆盖层，打字机效果 + 点击推进
## 由 DialogueManager 实例化并驱动

# ── 外观自定义 ──
@export var panel_bg_color: Color = Color(0.08, 0.08, 0.12, 0.9)
@export var speaker_color: Color = Color(1.0, 0.76, 0.03)
@export var text_color: Color = Color.WHITE
@export var next_indicator_blink_interval: float = 0.5

# ── 节点引用 ──
@onready var _panel: Panel = $Panel
@onready var _top_bar: HBoxContainer = $Panel/VBoxContainer/TopBar
@onready var _speaker_label: Label = $Panel/VBoxContainer/TopBar/SpeakerLabel
@onready var _separator: HSeparator = $Panel/VBoxContainer/HSeparator
@onready var _text_label: RichTextLabel = $Panel/VBoxContainer/MarginSpacer/TextLabel
@onready var _next_indicator: Label = $Panel/NextIndicator

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
	# 阻止鼠标事件穿透到游戏层
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	# 应用导出颜色
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
	# Panel 背景色
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

	# 启动打字机 — 使用 visible_characters 避免切断 BBCode 标签
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


func _process(delta: float) -> void:
	if not visible or not _current_sequence:
		return

	# 打字机效果
	if _is_typing:
		_typewriter_process(delta)

	# 自动推进计时
	if _waiting_for_advance and _current_line and _current_line.auto_advance > 0:
		_auto_timer += delta
		_blink_process(delta)
		if _auto_timer >= _current_line.auto_advance:
			_advance()

	# 继续提示闪烁
	if _waiting_for_advance and _current_line and _current_line.auto_advance <= 0:
		_blink_process(delta)


## 打字机逐字显示 — 使用 visible_characters 属性，BBCode 安全
func _typewriter_process(delta: float) -> void:
	if not _current_line:
		return
	var speed: float = _current_line.text_speed
	# speed == 0 直接显示全部
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


## 输入处理 — 左键点击推进对话
func _input(event: InputEvent) -> void:
	if not visible or not _current_sequence:
		return
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return

	# 如果正在打字 → 直接显示全部
	if _is_typing:
		_text_label.visible_characters = -1
		_visible_chars = _full_text.length()
		_is_typing = false
		_on_typing_finished()
		get_viewport().set_input_as_handled()
		return

	# 如果等待推进 → 推进到下一条
	if _waiting_for_advance:
		get_viewport().set_input_as_handled()
		_advance()


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
