## 顾客类 - 快餐店顾客
extends Area2D

var order_position: Vector2
var move_speed: float = 150.0
var favorite_food: String = ""
var state: String = "walking"  # walking, waiting, eating, leaving

signal order_placed(food_name: String)
signal customer_left(satisfaction: float)

# 食物类型
var food_types: Array = ["汉堡", "薯条", "可乐", "披萨", "炸鸡"]

func _ready() -> void:
	# 随机选择喜欢的食物
	favorite_food = food_types[randi() % food_types.size()]

func initialize(start_pos: Vector2, end_pos: Vector2) -> void:
	position = start_pos
	order_position = end_pos

func _process(delta: float) -> void:
	if state == "walking":
		position = position.move_toward(order_position, move_speed * delta)
		if position.distance_to(order_position) < 5:
			state = "waiting"
			order_placed.emit(favorite_food)

func serve_food(food_name: String) -> bool:
	if food_name == favorite_food:
		state = "eating"
		# 给予奖励
		GameManager.looi.add_coins(20.0 + randf() * 10)
		GameManager.looi.add_experience(5)
		GameManager.looi.change_affection(2.0)
		customer_left.emit(1.0)  # 满意
		return true
	else:
		# 错误的食物，好感度下降
		GameManager.looi.change_affection(-1.0)
		customer_left.emit(-1.0)  # 不满意
		return false

func _exit_tree() -> void:
	queue_free()
