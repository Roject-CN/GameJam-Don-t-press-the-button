extends Resource
class_name WaveData

## 波次数据 — 一个关卡的全部 WaveEntry 序列

@export var entries: Array[WaveEntry] = []


## 获取指定波次的条目（按 time_offset 排序）
func get_wave_entries(wave_index: int) -> Array[WaveEntry]:
	var result: Array[WaveEntry] = []
	for e in entries:
		if e.wave_index == wave_index or e.wave_index == 0:
			result.append(e)
	result.sort_custom(func(a, b): return a.time_offset < b.time_offset)
	return result
