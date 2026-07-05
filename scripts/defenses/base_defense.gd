extends Node2D
class_name BaseDefense

## 防御工事基类 — ghost 半透明跟随鼠标 + 网格吸附 + 放置验证 + 右键拆除 + 子类覆写 _on_placed

## 放置消耗碎片
@export var cost: int = 0

## 防御名称（UI 显示）
@export var defense_name: String = ""

## 允许放置的 tile atlas 坐标（Vector2i(-1,-1) 表示空地）
@export var allowed_tiles: Array[Vector2i] = [Vector2i(0, 0)]

## 是否已正式放置（false 时 _process 持续跟随鼠标）
var is_placed: bool = false

## 拆除请求信号
signal defence_remove_requested(defence: BaseDefense)

@onready var area_node: Area2D = $Area
@onready var _destroy_btn: Button = $destroy

## 放置验证用引用
var _logic_grid: TileMapLayer = null
var _defence_container_ref: DefenceContainer = null

## 放置最小间距
const MIN_DISTANCE: float = 64.0


func _process(_delta: float) -> void:
	if not is_placed:
		_ghost()
		return


## 注入放置验证所需的引用
func setup_ghost_validator(tilemap: TileMapLayer, container: DefenceContainer) -> void:
	_logic_grid = tilemap
	_defence_container_ref = container


## 半透明跟随鼠标 + 网格吸附 + 放置验证
func _ghost() -> void:
	var mouse_pos := get_global_mouse_position()

	# 网格吸附
	if _logic_grid:
		var local_pos := _logic_grid.to_local(mouse_pos)
		var map_pos := _logic_grid.local_to_map(local_pos)
		global_position = _logic_grid.to_global(_logic_grid.map_to_local(map_pos))
	else:
		global_position = mouse_pos

	# 放置验证
	if _is_placement_valid():
		modulate = Color(0.208, 0.612, 0.204, 0.5)
	else:
		modulate = Color.RED
		modulate.a = 0.5


## 检查当前位置是否可以放置
func _is_placement_valid() -> bool:
	# 检查 tile
	if _logic_grid:
		var local_pos := _logic_grid.to_local(global_position)
		var map_pos := _logic_grid.local_to_map(local_pos)
		var atlas := _logic_grid.get_cell_atlas_coords(map_pos)
		if atlas not in allowed_tiles:
			return false

	# 检查与其他防御重叠
	if _defence_container_ref:
		for placed in _defence_container_ref.placed_defenses:
			if not is_instance_valid(placed):
				continue
			if global_position.distance_to(placed.global_position) < MIN_DISTANCE:
				return false

	return true


## 正式放置：恢复不透明，触发子类钩子
func place() -> void:
	is_placed = true
	modulate = Color.WHITE
	_destroy_btn.pressed.connect(_on_destroy_pressed)
	_destroy_btn.mouse_entered.connect(_show_destroy_btn)
	_destroy_btn.mouse_exited.connect(_hide_destroy_btn)
	_on_placed()


	
func _show_destroy_btn() -> void:
	if _destroy_btn:
		_destroy_btn.self_modulate = Color(1.0, 1.0, 1.0, 1.0)

func _hide_destroy_btn() -> void:
	if _destroy_btn:
		_destroy_btn.self_modulate = Color(1.0, 1.0, 1.0, 0.0)

func _on_destroy_pressed() -> void:
	defence_remove_requested.emit(self)


## 子类覆写点 — 放置后初始化（连接信号等）
func _on_placed() -> void:
	pass
