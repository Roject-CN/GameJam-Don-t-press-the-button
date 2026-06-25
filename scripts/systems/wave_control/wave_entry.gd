extends Resource
class_name WaveEntry

## 单条敌人生成条目 — 定义"何时、哪波、什么敌人、从哪来、到哪去"

## 相对波次开始的时间（秒），在此时间点触发生成
@export var time_offset: float = 0.0

## 所属波次（1-based）。0 表示不受波次控制，由其他系统手动生成
@export var wave_index: int = 1

## 敌人类型字符串，在 EnemyCatalog 中查找对应 PackedScene
@export var enemy_type: String = ""

## 产生点 — 匹配关卡中 SpawnMarker 节点的名称
@export var spawn_point: String = ""

## 目标点 — 匹配关卡中 SpawnMarker 节点的名称（可选，用于 initial redirect）
@export var target_point: String = ""
