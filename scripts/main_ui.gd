## 主界面 UI 控制器
class_name MainUI
extends Control

## 状态显示标签
@onready var coins_label: Label = $MainContainer/StatusContainer/CoinsLabel
@onready var level_label: Label = $MainContainer/StatusContainer/LevelLabel
@onready var affection_label: Label = $MainContainer/StatusContainer/AffectionLabel
@onready var energy_label: Label = $MainContainer/EnergyLabel
@onready var energy_bar: ProgressBar = $MainContainer/EnergyBar
@onready var job_label: Label = $MainContainer/JobLabel
@onready var job_progress_bar: ProgressBar = $MainContainer/JobProgressBar

## 按钮
@onready var mine_button: Button = $MainContainer/ButtonContainer/MineButton
@onready var trade_button: Button = $MainContainer/ButtonContainer/TradeButton
@onready var quest_button: Button = $MainContainer/ButtonContainer/QuestButton
@onready var study_button: Button = $MainContainer/ButtonContainer/StudyButton
@onready var shop_button: Button = $MainContainer/ButtonContainer/ShopButton
@onready var restaurant_button: Button = $MainContainer/ButtonContainer/RestaurantButton

## 商店面板
@onready var shop_panel: Panel = $ShopPanel
@onready var shop_item_container: VBoxContainer = $ShopPanel/ScrollContainer/ShopItemContainer
@onready var close_shop_button: Button = $ShopPanel/CloseShopButton

## 餐厅面板
@onready var restaurant_panel: Panel = $RestaurantPanel
@onready var order_label: Label = $RestaurantPanel/OrderLabel
@onready var food_container: HBoxContainer = $RestaurantPanel/FoodContainer
@onready var back_button: Button = $RestaurantPanel/BackButton

var game_manager: GameManager
var restaurant_manager: Node = null
var current_order: String = ""
var restaurant_active: bool = false

func _ready() -> void:
	game_manager = GameManager.instance

	# 设置按钮连接
	mine_button.pressed.connect(_on_mine_pressed)
	trade_button.pressed.connect(_on_trade_pressed)
	quest_button.pressed.connect(_on_quest_pressed)
	study_button.pressed.connect(_on_study_pressed)
	shop_button.pressed.connect(_on_shop_pressed)
	close_shop_button.pressed.connect(_on_close_shop_pressed)
	restaurant_button.pressed.connect(_on_restaurant_pressed)
	back_button.pressed.connect(_on_back_pressed)

	# 隐藏面板
	shop_panel.visible = false

	# 连接信号
	game_manager.looi.coins_changed.connect(_update_coins)
	game_manager.looi.energy_changed.connect(_update_energy)
	game_manager.looi.level_up.connect(_update_level)
	game_manager.looi.affection_changed.connect(_update_affection)

	# 初始更新
	_update_all()

func _process(_delta: float) -> void:
	if game_manager.looi.current_job != LOOI.JobType.IDLE:
		job_progress_bar.value = game_manager.looi.job_progress * 100
		job_progress_bar.visible = true
	else:
		job_progress_bar.visible = false

func _update_all() -> void:
	_update_coins(0)
	_update_energy(0)
	_update_level(1)
	_update_affection(0)

func _update_coins(_amount: float) -> void:
	coins_label.text = "💰 金币: %.0f" % game_manager.looi.coins

func _update_energy(_amount: float) -> void:
	energy_bar.value = game_manager.looi.energy
	energy_bar.max_value = game_manager.looi.max_energy
	energy_label.text = "⚡ 能量: %.0f/%.0f" % [game_manager.looi.energy, game_manager.looi.max_energy]

func _update_level(_new_level: int) -> void:
	level_label.text = "⭐ 等级: %d" % game_manager.looi.level

func _update_affection(_amount: float) -> void:
	affection_label.text = "❤️ 好感: %.0f" % game_manager.looi.affection

# ============ 打工功能 ============

func _on_mine_pressed() -> void:
	if game_manager.looi.start_job(LOOI.JobType.MINE_COIN, 5.0):
		job_label.text = "⛏️ 挖矿中..."

func _on_trade_pressed() -> void:
	if game_manager.looi.start_job(LOOI.JobType.TRADE, 8.0):
		job_label.text = "💰 交易中..."

func _on_quest_pressed() -> void:
	if game_manager.looi.start_job(LOOI.JobType.QUEST, 12.0):
		job_label.text = "📜 任务中..."

func _on_study_pressed() -> void:
	if game_manager.looi.start_job(LOOI.JobType.STUDY, 6.0):
		job_label.text = "📚 学习中..."

# ============ 商店功能 ============

func _on_shop_pressed() -> void:
	shop_panel.visible = not shop_panel.visible
	if shop_panel.visible:
		_update_shop()

func _on_close_shop_pressed() -> void:
	shop_panel.visible = false

func _update_shop() -> void:
	for child in shop_item_container.get_children():
		child.queue_free()

	for i in range(game_manager.shop_items.size()):
		var item = game_manager.shop_items[i]
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 60)
		btn.text = "%s\n💰 %.0f - %s" % [item["name"], item["cost"], item["description"]]
		btn.pressed.connect(_on_shop_item_pressed.bind(i))
		shop_item_container.add_child(btn)

func _on_shop_item_pressed(index: int) -> void:
	if game_manager.purchase_item(index):
		print("购买成功!")
	else:
		print("金币不足!")

# ============ 快餐店功能 ============

func _on_restaurant_pressed() -> void:
	restaurant_panel.visible = true
	restaurant_active = true
	_start_restaurant()

func _on_back_pressed() -> void:
	restaurant_panel.visible = false
	restaurant_active = false
	if restaurant_manager:
		restaurant_manager.queue_free()
		restaurant_manager = null

func _start_restaurant() -> void:
	restaurant_manager = Node.new()
	restaurant_manager.set_script(load("res://scripts/restaurant_manager.gd"))
	restaurant_manager.name = "RestaurantManager"
	add_child(restaurant_manager)

	restaurant_manager.order_received.connect(_on_order_received)

	_create_food_buttons()

func _create_food_buttons() -> void:
	for child in food_container.get_children():
		child.queue_free()

	var foods: Array = ["汉堡", "薯条", "可乐", "披萨", "炸鸡"]
	for food in foods:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(80, 60)
		btn.text = food
		btn.pressed.connect(_on_food_button_pressed.bind(food))
		food_container.add_child(btn)

func _on_food_button_pressed(food_name: String) -> void:
	if restaurant_manager.serve_food(food_name):
		GameManager.looi.add_coins(20.0)
		GameManager.looi.add_experience(5)
		order_label.text = "✅ 送餐成功! +20金币"
		await get_tree().create_timer(1.5).timeout
		if restaurant_active:
			order_label.text = "等待顾客点餐..."
	else:
		order_label.text = "❌ 错误! 顾客想要: " + current_order

func _on_order_received(food_name: String) -> void:
	current_order = food_name
	order_label.text = "顾客要点: " + food_name
