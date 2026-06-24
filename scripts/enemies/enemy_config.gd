extends Resource
class_name EnemyConfig

## 敌人配置数据 — 驱动 BaseEnemy 属性和行为

## 移动速度
@export var speed: float = 200.0

## 生命值
@export var health: int = 1

## 点击次数（耗尽后自毁）
@export var click_times: int = 2

## 钓鱼抵抗概率 0.0-1.0
@export var taunt_resistance: float = 0.0

## 到达目标后搜索按钮的点击范围
@export var click_range: float = 50.0
