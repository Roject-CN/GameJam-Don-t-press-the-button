extends Resource
class_name CardEntry

## 卡组中的单条卡牌配置 — 卡牌场景 + 数量

## 卡牌 PackedScene（需继承 BaseCard）
@export var card_scene: PackedScene

## 该卡牌在卡组中的张数
@export var count: int = 1
