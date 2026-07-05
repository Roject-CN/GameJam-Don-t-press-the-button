extends Control
class_name MainMenu

func _ready() -> void:
	# 无存档时"继续游戏"按钮禁用
	var resume_btn = $VBoxContainer/Resume
	if not SaveManager.has_save():
		resume_btn.disabled = true


func _on_start_pressed() -> void:
	if SaveManager.has_save():
		_show_new_game_confirm()
	else:
		_do_new_game()


func _show_new_game_confirm() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "警告"
	dialog.dialog_text = "开始新游戏将删除旧存档，确定继续吗？"
	dialog.confirmed.connect(_do_new_game)
	add_child(dialog)
	dialog.popup_centered()


func _do_new_game() -> void:
	SaveManager.reset_save()
	get_tree().change_scene_to_file("res://scenes/main/level_select.tscn")


func _on_resume_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main/level_select.tscn")


func _on_exit_pressed() -> void:
	get_tree().quit()
