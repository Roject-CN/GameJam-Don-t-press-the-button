extends Resource
class_name CardDeck

## 卡组 — 一组 CardEntry 的集合，由 CardContainer 读取并实例化

## 卡牌配置列表
@export var entries: Array[CardEntry] = []


## 返回卡组中的总卡牌张数
func total_count() -> int:
	var n := 0
	for e in entries:
		n += e.count
	return n
