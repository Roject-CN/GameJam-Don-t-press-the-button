extends Resource
class_name LevelInfo

## 关卡元数据，挂载到 LevelNode 上

@export var level_id: String = ""          ## 唯一标识，如 "level_001"
@export var level_name: String = ""        ## 显示名称
@export var scene_path: String = ""        ## 关卡 .tscn 路径
@export_multiline var description: String = ""  ## 关卡描述
