extends Resource
class_name EnemyTypeMapping

## 敌人类型名 → PackedScene + EnemyConfig 的单个映射条目

@export var type_name: String = ""
@export var scene: PackedScene
@export var enemy_config: EnemyConfig
