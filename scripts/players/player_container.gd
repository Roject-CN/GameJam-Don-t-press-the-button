extends Node2D
class_name PlayerContainer

## 玩家容器 — 血量 + 费用 + PLAYER Buff 路由

## 内部 Buff 容器（组合代替继承）
var buff_container: BuffContainer

# ── 血量 ──
@export var max_lives: int = 8
var current_lives: int

# ── 费用 ──
@export var start_fragments: int = 100
var fragments: int

## 单次扣命（供 HUD/动画）
signal life_lost(amount: int)

## 血量归零 = 游戏失败
signal lives_depleted

## 费用变化（供 HUD）
signal fragments_changed(new_amount: int)


func _ready() -> void:
	current_lives = max_lives
	fragments = start_fragments

	buff_container = BuffContainer.new()
	buff_container.target_type = BuffEffect.Target.PLAYER
	buff_container.name = "PlayerBuffContainer"
	add_child(buff_container)

	buff_container.buff_applied.connect(_on_buff_applied)


func _on_buff_applied(effect: BuffEffect) -> void:
	# PropertyBuffEffect → 走 apply() 策略模式（加法/乘法/覆盖）
	if effect is PropertyBuffEffect and not effect.property_name.is_empty():
		var old_lives := current_lives
		effect.apply(self)
		var delta := old_lives - current_lives
		if delta != 0:
			life_lost.emit(delta)
		if current_lives <= 0:
			lives_depleted.emit()
		return

	# 基类 BuffEffect → prop 视为扣血量（兼容旧逻辑）
	var loss := int(effect.prop)
	if loss <= 0:
		return
	current_lives -= loss
	life_lost.emit(loss)
	if current_lives <= 0:
		lives_depleted.emit()


func add_fragments(amount: int) -> void:
	fragments += amount
	fragments_changed.emit(fragments)


func spend_fragments(amount: int) -> bool:
	if fragments < amount:
		return false
	fragments -= amount
	fragments_changed.emit(fragments)
	return true
