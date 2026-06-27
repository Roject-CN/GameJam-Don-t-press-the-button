extends Node
class_name DialogueManager

## 对话管理器 — 触发/生命周期控制，懒加载实例化 DialogueBox
## 放置为关卡场景或 GlobalManager 的子节点

## DialogueBox 的场景引用
@export var dialogue_box_scene: PackedScene

var _dialogue_box: DialogueBox = null
var _queue: Array[DialogueSequence] = []    # 对话序列队列
var _is_active: bool = false

## 对话开始
signal dialogue_started(sequence_id: String)

## 对话结束
signal dialogue_ended(sequence_id: String)


## 触发一段对话序列（若当前有对话则排队）
func trigger_sequence(sequence: DialogueSequence) -> void:
	if not sequence or sequence.line_count() == 0:
		push_warning("DialogueManager: 空的对话序列")
		return

	if _is_active:
		_queue.append(sequence)
		return

	_play_sequence(sequence)


## 跳过当前对话（播放下一个排队的序列或结束）
func skip_current() -> void:
	if _dialogue_box:
		_dialogue_box.skip_all()


## 当前是否有对话进行中
func is_active() -> bool:
	return _is_active


## 获取当前对话序列（供外部读取当前行数据，如镜头系统）
func get_current_sequence() -> DialogueSequence:
	if _dialogue_box:
		return _dialogue_box._current_sequence
	return null


## 获取当前行索引
func get_current_line_index() -> int:
	if _dialogue_box:
		return _dialogue_box._current_index
	return -1


func _play_sequence(sequence: DialogueSequence) -> void:
	_ensure_dialogue_box()
	if not _dialogue_box:
		push_error("DialogueManager: DialogueBox 实例化失败")
		return

	_is_active = true
	dialogue_started.emit(sequence.sequence_id)

	# 确保信号连接（不重复连接）
	if not _dialogue_box.dialogue_finished.is_connected(_on_dialogue_finished):
		_dialogue_box.dialogue_finished.connect(_on_dialogue_finished)

	_dialogue_box.start_sequence(sequence)


func _ensure_dialogue_box() -> void:
	if _dialogue_box:
		return
	if not dialogue_box_scene:
		push_error("DialogueManager: dialogue_box_scene 未设置")
		return
	var inst: Node = dialogue_box_scene.instantiate()
	if not inst is DialogueBox:
		push_error("DialogueManager: dialogue_box_scene 实例不是 DialogueBox 类型")
		inst.queue_free()
		return
	_dialogue_box = inst
	add_child(_dialogue_box)


func _on_dialogue_finished(sequence_id: String) -> void:
	_is_active = false
	dialogue_ended.emit(sequence_id)

	# 播放队列中的下一个序列
	if not _queue.is_empty():
		var next_seq: DialogueSequence = _queue.pop_front()
		_play_sequence(next_seq)
