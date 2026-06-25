extends Resource
class_name WaveData

## 波次数据 — 支持手动编辑 WaveEntry[] 或从 CSV 导入

@export var entries: Array[WaveEntry] = []

## CSV 文件路径（.csv），设置后自动解析并填充 entries
@export_file("*.csv") var csv_path: String = "":
	set(v):
		csv_path = v
		if not v.is_empty():
			_parse_csv(v)


## 获取指定波次的条目（按 time_offset 排序）
func get_wave_entries(wave_index: int) -> Array[WaveEntry]:
	var result: Array[WaveEntry] = []
	for e in entries:
		if e.wave_index == wave_index or e.wave_index == 0:
			result.append(e)
	result.sort_custom(func(a, b): return a.time_offset < b.time_offset)
	return result


## 从 CSV 文件解析并填充 entries
func _parse_csv(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("WaveData: cannot open CSV file: " + path)
		return

	entries.clear()
	var line_num := 0

	while not file.eof_reached():
		var line := file.get_csv_line()
		line_num += 1

		# 跳过空行、注释、表头
		if line.size() < 5:
			continue
		if line[0].is_empty() or line[0].begins_with("#"):
			continue
		if line[0] == "time_offset":
			continue

		var entry := WaveEntry.new()
		entry.time_offset = float(line[0])
		entry.wave_index = int(line[1])
		entry.enemy_type = line[2].strip_edges()
		entry.spawn_point = line[3].strip_edges()
		entry.target_point = line[4].strip_edges() if line.size() > 4 else ""

		entries.append(entry)

	file.close()
	print("WaveData: loaded %d entries from %s" % [entries.size(), path])
