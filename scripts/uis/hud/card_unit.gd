extends Control
class_name BaseCard

## 卡牌基类 — 长按拖拽生成防御 ghost，松手放置，右键取消

@export var anim_player: AnimationPlayer

## 本卡牌对应的防御场景（实例化后需为 BaseDefense 子类）
@export var defense_unit_scene: PackedScene

## 长按判定阈值（秒）
@export var long_press_threshold: float = 0.2

var _is_dragging: bool = false
var _is_pressed: bool = false
var _press_timer: float = 0.0

## 拖拽中的 defence ghost 实例
var _defence: BaseDefense = null

## 从 HUD 获取的吸附栅格
var _logic_grid: TileMapLayer = null

## 从 HUD 获取的防御管理器
var _defence_container: DefenceContainer = null


func _ready() -> void:
	var hud := _verify_hud()
	if hud:
		_defence_container = hud.defense_container
		_logic_grid = hud.logic_grid
	_verify_defense_scene()


func _process(delta: float) -> void:
	if _is_pressed and not _is_dragging:
		_press_timer += delta
		if _press_timer >= long_press_threshold:
			_start_drag()

	if _is_dragging and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_end_drag()

	# 拖拽中右键取消
	if _is_dragging and Input.is_action_just_pressed("cancel_action"):
		_cancel_drag()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_on_press()
		else:
			if _is_dragging:
				_end_drag()
			else:
				_reset_press()


func _verify_hud() -> HUD:
	var cards_node := get_parent()
	if not cards_node is CardContainer:
		return null
	var hud_node := cards_node.get_parent()
	if not hud_node is HUD:
		return null
	return hud_node


func _verify_defense_scene() -> void:
	if not _can_use_defense_scene():
		return
	var test_inst := defense_unit_scene.instantiate()
	if not test_inst is BaseDefense:
		push_error("defense_unit_scene (%s) 的实例不是 BaseDefense 类型！" % defense_unit_scene.resource_path)
	test_inst.queue_free()


func _can_use_defense_scene() -> bool:
	return defense_unit_scene != null and defense_unit_scene.can_instantiate()


func _on_press() -> void:
	if not _can_use_defense_scene():
		return
	_is_pressed = true
	_press_timer = 0.0


func _reset_press() -> void:
	_is_pressed = false
	_press_timer = 0.0


func _start_drag() -> void:
	if _is_dragging or not _can_use_defense_scene():
		return
	_is_dragging = true

	_defence = defense_unit_scene.instantiate() as BaseDefense
	if not _defence:
		_is_dragging = false
		return
	_defence.is_placed = false
	_defence.setup_ghost_validator(_logic_grid, _defence_container)
	if _defence_container:
		_defence_container.spawn_defence(_defence)


func _end_drag() -> void:
	_is_dragging = false
	_is_pressed = false
	_press_timer = 0.0

	if not _defence:
		return

	if _logic_grid:
		_defence.global_position = _snap_to_grid(_defence.global_position)

	# 验证放置位置，无效则取消
	if not _defence._is_placement_valid():
		_cancel_drag()
		return

	if _defence_container:
		_defence_container.confirm_placement(_defence)
	_defence = null


## 右键取消：释放 ghost，卡片复位
func _cancel_drag() -> void:
	_is_dragging = false
	_is_pressed = false
	_press_timer = 0.0
	if _defence:
		_defence.queue_free()
		_defence = null


func _snap_to_grid(global_pos: Vector2) -> Vector2:
	var local_pos := _logic_grid.to_local(global_pos)
	var map_pos := _logic_grid.local_to_map(local_pos)
	var snapped_local := _logic_grid.map_to_local(map_pos)
	return _logic_grid.to_global(snapped_local)


func _on_mouse_entered() -> void:
	anim_player.play("card_scale_up")


func _on_mouse_exited() -> void:
	anim_player.play("card_scale_down")
