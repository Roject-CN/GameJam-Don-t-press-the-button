extends Resource
class_name DialogueSequence

## 对话序列 — 有序 DialogueLine 列表，由 DialogueManager 驱动播放
## 使用方式：创建 .tres 文件，在编辑器中填写 lines 数组

## 序列标识（调试用）
@export var sequence_id: String = ""

## 有序对话行列表
@export var lines: Array[DialogueLine] = []

## 是否允许玩家跳过整段对话
@export var can_skip: bool = true


## 安全获取指定索引的行，越界返回 null
func get_line(index: int) -> DialogueLine:
	if index < 0 or index >= lines.size():
		return null
	return lines[index]


## 返回对话行总数
func line_count() -> int:
	return lines.size()
