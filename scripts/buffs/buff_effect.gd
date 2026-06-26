extends Resource
class_name BuffEffect

## Buff 效果抽象基类 — 策略模式
## 子类覆写 apply() / remove() 实现具体效果

enum Target {
	ENEMY,    # 影响敌人
	DEFENSE,  # 影响防御工事
	PLAYER,   # 影响玩家
}

## 效果显示名称（UI 横幅用）
@export var buff_name: String

## 效果描述（多行文本，编辑器内显示）
@export_multiline var description: String = ""

## 影响目标类型（决定路由到哪个 BuffContainer）
@export var target: Target = Target.ENEMY

## 持续波次数（0 = 永久/手动移除）
@export var duration_waves: int = 0

## 剩余波次（运行时倒计数）
var _remaining_waves: int = 0


func init() -> void:
	_remaining_waves = duration_waves


func tick_wave() -> bool:
	"""波次结束时调用，返回 true 表示效果已过期"""
	if duration_waves <= 0:
		return false
	_remaining_waves -= 1
	return _remaining_waves <= 0


## 子类覆写 — 对目标实体施加效果
func apply(_target: Object) -> void:
	pass


## 子类覆写 — 从目标实体移除效果（还原修改）
func remove(_target: Object) -> void:
	pass
