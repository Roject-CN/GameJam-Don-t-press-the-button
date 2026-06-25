extends Node2D
class_name LevelController

## 关卡控制器 — 加载 / 缓存 / 切换关卡场景

## 已加载关卡的缓存（路径 → PackedScene）
var levels_loaded: Dictionary

## 当前活跃的关卡实例
var level_current: level


## 切换到指定路径的关卡，自动缓存已加载场景
func change_level_to(level_path: String) -> void:
	var new_level_scene: PackedScene

	if levels_loaded.has(level_path):
		new_level_scene = levels_loaded[level_path]
	else:
		new_level_scene = load(level_path) as PackedScene
		if new_level_scene == null:
			push_error("关卡路径错误，无法加载资源: " + level_path)
			return
		levels_loaded[level_path] = new_level_scene

	if is_instance_valid(level_current):
		level_current.queue_free()

	var new_level_instance := new_level_scene.instantiate()
	add_child(new_level_instance)
	level_current = new_level_instance
