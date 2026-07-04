extends Node2D
class_name DebugBuffPanel

## 调试面板 — 实时显示敌人/玩家/防御状态

@export var enemy_controller: EnemyController
@export var player_container: PlayerContainer
@export var defense_container: DefenceContainer

var _debug_label: RichTextLabel


func _ready() -> void:
	_create_debug_overlay()


func _create_debug_overlay() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "DebugCanvas"
	add_child(canvas)

	_debug_label = RichTextLabel.new()
	_debug_label.name = "DebugLabel"
	_debug_label.anchor_left = 0.0
	_debug_label.anchor_top = 0.0
	_debug_label.offset_left = 10.0
	_debug_label.offset_top = 520.0
	_debug_label.offset_right = 1270.0
	_debug_label.offset_bottom = 710.0
	_debug_label.bbcode_enabled = true
	_debug_label.fit_content = false
	_debug_label.scroll_active = false
	_debug_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(_debug_label)


## 合并同类 buff，返回格式化的显示行
func _format_buffs(buffs: Array) -> Array[String]:
	if buffs.is_empty():
		return []

	var grouped: Dictionary = {}
	for b: BuffEffect in buffs:
		var key: String = b.buff_name
		if not key in grouped:
			grouped[key] = {count = 0, duration_text = ""}
		grouped[key].count += 1
		if b.duration_waves <= 0:
			grouped[key].duration_text = "永久"
		elif grouped[key].duration_text != "永久":
			var remain: int = b._remaining_waves
			var prev: String = grouped[key].duration_text
			if prev.is_empty() or (prev.begins_with("剩余") and int(prev.trim_prefix("剩余").trim_suffix("波")) > remain):
				grouped[key].duration_text = "剩余%d波" % remain

	var result: Array[String] = []
	for name in grouped:
		result.append("    %s ×%d (%s)" % [name, grouped[name].count, grouped[name].duration_text])
	return result


func _process(_delta: float) -> void:
	if not _debug_label:
		return

	var lines: Array[String] = []

	# ── 玩家 ──
	if player_container:
		lines.append("[b]玩家[/b]  命=%d  碎片=%d" % [player_container.current_lives, player_container.fragments])
		var pbuffs: Array = _format_buffs(player_container.buff_container.get_active_buffs())
		if pbuffs.size() > 0:
			lines.append("  ↳ 活跃Buff:")
			lines.append_array(pbuffs)

	# ── 敌人 ──
	if enemy_controller:
		lines.append("[b]存活敌人: %d[/b]" % enemy_controller.enemies_alive)
		var ebuffs: Array = _format_buffs(enemy_controller.buff_container.get_active_buffs())
		if ebuffs.size() > 0:
			lines.append("  [color=orange]活跃Buff:[/color]")
			lines.append_array(ebuffs)
		for child in enemy_controller.get_children():
			if not is_instance_valid(child):
				continue
			if child is BaseEnemy:
				lines.append("  [%s] speed=%.0f health=%d clicks=%d taunt=%.2f" % [
					child.name,
					child.speed,
					child.health,
					child.click_times,
					child.taunt_resistance,
				])

	# ── 防御 ──
	if defense_container:
		var dbuffs: Array = _format_buffs(defense_container.buff_container.get_active_buffs())
		if dbuffs.size() > 0:
			lines.append("[b]防御设施: %d[/b]" % defense_container.placed_defenses.size())
			lines.append("  [color=cyan]活跃Buff:[/color]")
			lines.append_array(dbuffs)
		for d: BaseDefense in defense_container.placed_defenses:
			if not is_instance_valid(d):
				continue
			if d is TurretDefense:
				lines.append("  [Turret] fire_rate=%.1f damage=%d" % [d.fire_rate, d.damage])

	_debug_label.text = "\n".join(lines)
