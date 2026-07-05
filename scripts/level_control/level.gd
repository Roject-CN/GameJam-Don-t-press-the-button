extends Node2D
class_name level

## 关卡场景基类 — 每个 .tscn 关卡文件的根节点

## 可选：接受的子场景（预留）
@export var level_scene: Node2D

## 关卡存档标识
@export var level_id: String = ""           ## 对应 LevelInfo.level_id，如 "level_001"
@export var next_level_id: String = ""      ## 完成本关后解锁的下一关 id
