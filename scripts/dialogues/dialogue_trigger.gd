extends Node
class_name DialogueTrigger

## 对话触发桥接 — 连接关卡事件到对话序列
## 放置于关卡场景中，在编辑器配置"何时触发、触发什么"

enum TriggerMode {
	AUTO,     # 场景加载后自动触发
	SIGNAL,   # 由外部信号连接触发
	MANUAL,   # 由其他脚本调用 trigger()
}

## 触发模式
@export var trigger_mode: TriggerMode = TriggerMode.AUTO

## 目标 DialogueManager
@export var dialogue_manager: DialogueManager

## 要触发的对话序列
@export var dialogue_sequence: DialogueSequence

## AUTO 模式的延迟时间（秒），等待场景渲染
@export var auto_delay: float = 0.5


func _ready() -> void:
	if trigger_mode == TriggerMode.AUTO:
		# 延迟触发，确保场景加载完成
		if auto_delay > 0:
			await get_tree().create_timer(auto_delay).timeout
		trigger()


## 手动触发对话
func trigger() -> void:
	if not dialogue_manager:
		push_error("DialogueTrigger: dialogue_manager 未设置")
		return
	if not dialogue_sequence:
		push_error("DialogueTrigger: dialogue_sequence 未设置")
		return
	dialogue_manager.trigger_sequence(dialogue_sequence)


## 静态工具方法：根据资源路径加载并触发对话
static func trigger_by_path(manager: DialogueManager, resource_path: String) -> void:
	if not manager:
		return
	var seq: DialogueSequence = load(resource_path) as DialogueSequence
	if seq:
		manager.trigger_sequence(seq)
