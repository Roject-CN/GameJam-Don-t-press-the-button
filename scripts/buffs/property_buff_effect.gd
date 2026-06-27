extends BuffEffect
class_name PropertyBuffEffect

## 属性修改 Buff — 通过 get()/set() 修改目标节点的导出属性
## 覆盖 90% 的 buff 场景（加减速、加减血、增减伤等）

enum Operation {
	ADD,       # 加法: target.set(prop, current + value)
	MULTIPLY,  # 乘法: target.set(prop, current * value)
	SET,       # 覆盖: target.set(prop, value)
}

@export_enum(
	"BaseEnemy_speed:speed",
	"BaseEnemy_health:health",
	"BaseEnemy_click_times:click_times",
	"BaseEnemy_taunt_resistance:taunt_resistance",
	"TurretDefense_fire_rate:fire_rate",
	"TurretDefense_damage:damage",
	"WindowDefense_lure_count:lure_count",
	"PlayerManager_current_lives:current_lives",
	"PlayerManager_max_lives:max_lives",
	"PlayerManager_fragments:fragments",
)
var property_name: String = ""

## 运算类型
@export var operation: Operation = Operation.ADD

## 操作数值
@export var value: float = 0.0

## 存储每个受影响节点的原始值，用于 remove() 时还原
var _modified: Dictionary = {}


func apply(target: Object) -> void:
	if property_name.is_empty():
		push_error("PropertyBuffEffect: property_name 为空")
		return
		
	if not property_name in target:
		push_error("PropertyBuffEffect: %s 没有属性 %s" % [target.name, property_name])
		return

	var current = target.get(property_name)
	_modified[target] = current

	match operation:
		Operation.ADD:
			target.set(property_name, current + value)
		Operation.MULTIPLY:
			target.set(property_name, current * value)
		Operation.SET:
			target.set(property_name, value)


func remove(target: Object) -> void:
	if not target in _modified:
		return
	if is_instance_valid(target) and property_name in target:
		target.set(property_name, _modified[target])
	_modified.erase(target)
