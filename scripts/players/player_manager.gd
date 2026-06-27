extends Node2D
class_name PlayerManager

## 玩家管理器 — 血量 + 费用 + PLAYER Buff 路由

## 内部 Buff 容器（组合代替继承）
var buff_container: BuffContainer

# ── 血量 ──
@export var max_lives: int = 8
var current_lives: int:
	set(v):
		if v < current_lives:
			life_lost.emit(current_lives - v)
		current_lives = v
		lives_changed.emit(current_lives)
		if current_lives <= 0:
			lives_depleted.emit()

# ── 费用 ──
@export var start_fragments: int = 100
var fragments: int

## 单次扣命（供 HUD/动画）
signal life_lost(amount: int)

## 血量变化（每次 set 都发射，供 HUD 同步）
signal lives_changed(current: int)

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
	buff_container.buff_removed.connect(_on_buff_removed)


func _on_buff_applied(effect: BuffEffect) -> void:
	effect.apply(self)


func _on_buff_removed(effect: BuffEffect) -> void:
	effect.remove(self)


func add_fragments(amount: int) -> void:
	fragments += amount
	fragments_changed.emit(fragments)


func spend_fragments(amount: int) -> bool:
	if fragments < amount:
		return false
	fragments -= amount
	fragments_changed.emit(fragments)
	return true
