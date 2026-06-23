extends Node2D

class_name level_controller
var levels_loaded:Dictionary
var level_current:level
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

## 切换关卡函数
func change_level_to(level_path: String) -> void:
	var new_level_scene: PackedScene
	
	# 1. 检查缓存：如果之前加载过，直接从字典.
	if levels_loaded.has(level_path):
		new_level_scene = levels_loaded[level_path]
	else:
		# 如果缓存没有，则从硬盘加载并存入缓存
		new_level_scene = load(level_path) as PackedScene
		if new_level_scene == null:
			push_error("关卡路径错误，无法加载资源: " + level_path)
			return
		levels_loaded[level_path] = new_level_scene
	
	# 2. 移除并销毁当前的关卡
	if is_instance_valid(level_current):
		level_current.queue_free() # 在帧末尾释放内存
	
	# 3. 实例化新关卡
	var new_level_instance = new_level_scene.instantiate()
	
	# 4. 将新关卡作为子节点添加到当前控制器下
	add_child(new_level_instance)
	
	# 5. 更新当前关卡的引用指向
	level_current = new_level_instance
