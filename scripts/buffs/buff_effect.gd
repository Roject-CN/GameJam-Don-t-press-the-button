extends Resource
class_name BuffEffect

enum Target {
	ENEMY,    # 影响敌人
	DEFENSE,   # 影响防御工事
	PLAYER,   # 影响玩家
	TERRAIN,  # 影响地图/地形
}

## 效果显示名称（UI 横幅用）
@export var buff_name : String

## 影响目标类型
@export var target : Target = Target.ENEMY

## 属性修改 — 暂时为测试 后面再考虑怎么搞
@export var prop : float = 1.0

## 持续波次数（0 = 永久/手动移除）
@export var duration_waves : int = 0

## 剩余波次（运行时倒计数）
var _remaining_waves : int = 0


func init() -> void:
	_remaining_waves = duration_waves


func tick_wave() -> bool:
	"""波次结束时调用，返回 true 表示效果已过期"""
	if duration_waves <= 0:
		return false
	_remaining_waves -= 1
	return _remaining_waves <= 0
