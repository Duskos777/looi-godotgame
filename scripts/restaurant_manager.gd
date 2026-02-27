## 快餐店管理器 - 简化版
extends Node

var spawn_timer: float = 0.0
var spawn_interval: float = 5.0  # 每5秒一个顾客
var current_order: String = ""
var order_pending: bool = false

# 食物列表
var food_types: Array = ["汉堡", "薯条", "可乐", "披萨", "炸鸡"]

signal order_received(food_name: String)
signal customer_left()

func _ready() -> void:
	# 2秒后开始生成顾客
	await get_tree().create_timer(2.0).timeout
	_spawn_customer()

func _process(delta: float) -> void:
	spawn_timer += delta
	if spawn_timer >= spawn_interval and not order_pending:
		spawn_timer = 0.0
		_spawn_customer()

func _spawn_customer() -> void:
	if order_pending:
		return

	# 随机选择食物
	current_order = food_types[randi() % food_types.size()]
	order_pending = true
	order_received.emit(current_order)

func serve_food(food_name: String) -> bool:
	if not order_pending:
		return false

	if food_name == current_order:
		# 正确
		order_pending = false
		current_order = ""
		spawn_timer = 0.0
		return true
	else:
		# 错误
		return false
