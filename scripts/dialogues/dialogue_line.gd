extends Resource
class_name DialogueLine

## 单条对话数据 — 包含说话人、文本、对话框位置及镜头目标字段
## 作为 SubResource 内联在 DialogueSequence 中使用

## 说话人名称（空字符串 = 旁白，UI 隐藏名字栏）
@export var speaker_name: String = ""

## 对话正文（支持 BBCode 标记）
@export_multiline var text: String = ""

## 打字机每字显示间隔（秒），0 = 立即显示全部文本
@export var text_speed: float = 0.05

## 对话框在屏幕上的位置（CanvasLayer 坐标系）
@export var box_position: Vector2 = Vector2(40, 520)

## 自动推进时间（秒），0 = 等待玩家点击推进
@export var auto_advance: float = 0.0

# ── 镜头预留字段（当前不消费，供未来镜头系统读取）──

## 镜头聚焦目标节点路径（相对于触发对话的关卡根节点）
@export var camera_target: NodePath

## 镜头聚焦目标的偏移量
@export var camera_offset: Vector2 = Vector2.ZERO

## 此条对话时的镜头缩放值
@export var camera_zoom: float = 1.0
