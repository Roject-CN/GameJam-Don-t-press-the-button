extends Control
class_name LevelSelect

## 选关地图控制器 — 对应 ThemeTree 的角色

@onready var info_panel: Panel = $InfoPanel
@onready var level_name_label: Label = $InfoPanel/MarginContainer/VBoxContainer/LevelNameLabel
@onready var level_desc_label: Label = $InfoPanel/MarginContainer/VBoxContainer/LevelDescLabel
@onready var confirm_btn: Button = $InfoPanel/MarginContainer/VBoxContainer/HBoxContainer/ConfirmBtn
@onready var cancel_btn: Button = $InfoPanel/MarginContainer/VBoxContainer/HBoxContainer/CancelBtn

var _selected_info: LevelInfo = null
var _level_nodes: Array[LevelNode] = []


func _ready() -> void:
	info_panel.hide()

	# 收集所有子 LevelNode
	for child in get_children():
		if child is LevelNode:
			_level_nodes.append(child)
			child.level_selected.connect(_on_level_selected)
			child.request_open_tooltip.connect(_on_open_tooltip)
			child.request_close_tooltip.connect(_on_close_tooltip)

	confirm_btn.pressed.connect(_on_confirm)
	cancel_btn.pressed.connect(_on_cancel)


func _on_level_selected(info: LevelInfo) -> void:
	_selected_info = info
	level_name_label.text = info.level_name
	level_desc_label.text = info.description
	info_panel.show()


func _on_open_tooltip(_text: String) -> void:
	pass  # 暂不实现浮动 tooltip，后续可加


func _on_close_tooltip() -> void:
	pass


func _on_confirm() -> void:
	if _selected_info == null:
		return
	get_tree().change_scene_to_file(_selected_info.scene_path)


func _on_cancel() -> void:
	_selected_info = null
	info_panel.hide()


## 刷新所有关卡节点的状态（从存档重新读取）
func refresh_all() -> void:
	for node in _level_nodes:
		node.refresh_state()
