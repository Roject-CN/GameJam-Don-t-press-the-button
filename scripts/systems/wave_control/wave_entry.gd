extends Resource
class_name WaveEntry

## 单条敌人生成条目

## 相对波次开始的时间（秒）
@export var time_offset: float = 0.0

## 所属波次（1-based）。0 表示不受波次控制
@export var wave_index: int = 1

## 敌人类型字符串，在 EnemyCatalog 中查找对应 PackedScene
@export var enemy_type: String = ""

## 路径线 — 匹配关卡中 Line2D 节点的名称（出生点 = Line2D.points[0]）
@export var path_line: String = ""
