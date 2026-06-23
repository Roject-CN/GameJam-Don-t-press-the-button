extends Control

@export var card_scene: PackedScene

@export var card_num: int = 0

# 卡间距修正值（如果是负数，代表卡牌重叠的像素值；如果是正数，代表卡牌之间的空隙）
@export var card_spacing_relative: float = -10.0

var card_spacing: float = 0.0

# 用一个数组来管理所有生成的卡牌实例，以便后续进行排序和控制
var spawned_cards: Array[Control] = []

func _ready() -> void:
	if card_scene and card_scene.can_instantiate():
		# 1. 临时实例化一张卡牌来获取尺寸信息
		var temp_card = card_scene.instantiate() as Control
		if temp_card:
			# 计算实际间距：卡牌宽度 - 重叠像素
			card_spacing = temp_card.size.x + card_spacing_relative
			
			# 2. 释放掉这个没有进入场景树的临时节点，防止内存泄漏
			temp_card.queue_free()
			
			# 3. 开始生成并放置所有的卡牌
			_place_cards()

func _place_cards() -> void:
	# 如果没有卡牌，直接返回
	if card_num <= 0:
		return
	for old_card in spawned_cards:
		if is_instance_valid(old_card):
			old_card.queue_free()
	spawned_cards.clear()
	
	# 循环生成指定数量的卡牌
	for i in range(card_num):
		var card_instance = card_scene.instantiate() as Control
		if card_instance:
			# 将卡牌添加为当前容器的子节点，这样它才会显示
			add_child(card_instance)
			spawned_cards.append(card_instance)
			
			# 计算每张卡牌的 X 轴坐标（第一张在 0，第二张在 1 * card_spacing，以此类推）
			var target_x = i * card_spacing
			
			# 设置卡牌的位置
			card_instance.position = Vector2(target_x, 0)
