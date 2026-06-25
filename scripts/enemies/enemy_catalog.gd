extends Resource
class_name EnemyCatalog

## 敌人目录 — 敌人类型字符串 → PackedScene + EnemyConfig 的映射表

@export var mappings: Array[EnemyTypeMapping] = []


## 根据类型名查找对应场景
func get_scene(type_name: String) -> PackedScene:
	for m in mappings:
		if m.type_name == type_name:
			return m.scene
	return null


## 根据类型名查找对应 EnemyConfig
func get_config(type_name: String) -> EnemyConfig:
	for m in mappings:
		if m.type_name == type_name:
			return m.enemy_config
	return null
