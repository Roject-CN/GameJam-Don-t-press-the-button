extends Node
class_name SaveManager

## 存档管理器 — 使用 ConfigFile 持久化关卡解锁状态到 user://save_data.cfg

const SAVE_PATH := "user://save_data.cfg"
const SECTION_LEVELS := "levels"

## 是否有存档文件
static func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


## 重置存档（删除文件），新游戏时调用
static func reset_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)


## 获取指定关卡状态: "locked" / "available" / "completed"
static func get_level_state(level_id: String) -> String:
	var cfg := _load_cfg()
	if cfg == null:
		return "locked"
	return cfg.get_value(SECTION_LEVELS, level_id, "locked")


## 将关卡标记为已完成
static func complete_level(level_id: String) -> void:
	var cfg := _load_or_create()
	cfg.set_value(SECTION_LEVELS, level_id, "completed")
	_save_cfg(cfg)


## 解锁指定关卡（设为 available）
static func unlock_level(level_id: String) -> void:
	var cfg := _load_or_create()
	cfg.set_value(SECTION_LEVELS, level_id, "available")
	_save_cfg(cfg)


static func _load_cfg() -> ConfigFile:
	if not FileAccess.file_exists(SAVE_PATH):
		return null
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	return cfg


static func _load_or_create() -> ConfigFile:
	var cfg := ConfigFile.new()
	if FileAccess.file_exists(SAVE_PATH):
		cfg.load(SAVE_PATH)
	return cfg


static func _save_cfg(cfg: ConfigFile) -> void:
	cfg.save(SAVE_PATH)
