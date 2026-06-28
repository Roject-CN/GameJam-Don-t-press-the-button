extends Node2D
class_name BuffContainer

## Buff 容器 — 存储活跃 Buff，路由信号到管理层
## 组合在各管理器中（非继承），BuffEmitter 直接路由到此

var target_type: BuffEffect.Target

## 当前活跃的 Buff 效果列表
var _active_buffs: Array[BuffEffect] = []

## Buff 被应用到某实体时发射
signal buff_applied(effect: BuffEffect)

## Buff 因过期/手动移除时发射（供管理层还原效果）
signal buff_removed(effect: BuffEffect)


func apply_buff(effect: BuffEffect) -> void:
	effect.init()
	_active_buffs.append(effect)
	buff_applied.emit(effect)


## 波次结束时调用 — 过期 buff 自动移除并发射 buff_removed
func tick_wave() -> void:
	var expired: Array[BuffEffect] = []
	for effect in _active_buffs:
		if effect.tick_wave():
			expired.append(effect)

	for effect in expired:
		_active_buffs.erase(effect)
		buff_removed.emit(effect)


## 只读访问活跃 buff 列表（供管理层在注册新实体时遍历）
func get_active_buffs() -> Array[BuffEffect]:
	return _active_buffs
