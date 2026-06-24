extends Control
class_name CardContainer

## 卡牌容器 — 从 CardDeck 资源读取配置，实例化多种卡牌并按间距排列

## 卡组配置资源
@export var deck: CardDeck

## 卡间距修正值（负数 = 重叠，正数 = 空隙）
@export var card_spacing_relative: float = 3.0

var _card_spacing: float = 0.0
var spawned_cards: Array[Control] = []


func _ready() -> void:
	if not deck or deck.entries.is_empty():
		return

	# 用第一条卡牌计算间距
	var first_entry: CardEntry = deck.entries[0]
	if first_entry.card_scene and first_entry.card_scene.can_instantiate():
		var temp := first_entry.card_scene.instantiate() as BaseCard
		if temp:
			_card_spacing = temp.size.x + card_spacing_relative
			temp.queue_free()

	_place_cards()


## 遍历卡组条目，按 count 逐一实例化并水平排列
func _place_cards() -> void:
	for old in spawned_cards:
		if is_instance_valid(old):
			old.queue_free()
	spawned_cards.clear()

	var x_offset := 0.0

	for entry: CardEntry in deck.entries:
		if not entry.card_scene or not entry.card_scene.can_instantiate():
			continue
		for _i in range(entry.count):
			var card := entry.card_scene.instantiate() as Control
			if not card:
				continue
			add_child(card)
			card.position = Vector2(x_offset, 0)
			spawned_cards.append(card)
			x_offset += _card_spacing
