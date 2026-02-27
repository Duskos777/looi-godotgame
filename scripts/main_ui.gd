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

## 新增按钮
@onready var inventory_button: Button = $MainContainer/ButtonContainer/InventoryButton
@onready var farm_button: Button = $MainContainer/ButtonContainer/FarmButton
@onready var pet_button: Button = $MainContainer/ButtonContainer/PetButton
@onready var minigame_button: Button = $MainContainer/ButtonContainer/MinigameButton

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

	# 新增按钮连接
	inventory_button.pressed.connect(_on_inventory_pressed)
	farm_button.pressed.connect(_on_farm_pressed)
	pet_button.pressed.connect(_on_pet_pressed)
	minigame_button.pressed.connect(_on_minigame_pressed)

	# 关闭农场面板
	var close_farm_btn = $FarmPanel.get_node_or_null("CloseFarmButton")
	if close_farm_btn:
		close_farm_btn.pressed.connect(_on_close_farm_pressed)

	# 关闭宠物面板
	var close_pet_btn = $PetPanel.get_node_or_null("ClosePetButton")
	if close_pet_btn:
		close_pet_btn.pressed.connect(_on_close_pet_pressed)

	# 宠物喂养和抚摸按钮
	var feed_btn = $PetPanel/PetActionsContainer.get_node_or_null("FeedButton")
	var pet_btn = $PetPanel/PetActionsContainer.get_node_or_null("PetButton")
	if feed_btn:
		feed_btn.pressed.connect(_on_feed_pet_pressed)
	if pet_btn:
		pet_btn.pressed.connect(_on_pet_animal_pressed)

	# 农场土地按钮连接
	var farm_grid = $FarmPanel/FarmGrid
	for i in range(6):
		var plot_btn = farm_grid.get_child(i)
		if plot_btn:
			plot_btn.pressed.connect(_on_farm_plot_pressed.bind(i))

	# 关闭背包面板
	var close_inv_btn = $InventoryPanel.get_node_or_null("CloseInventoryButton")
	if close_inv_btn:
		close_inv_btn.pressed.connect(_on_inventory_pressed)

	# 初始给予一些种子方便测试
	game_manager.looi.add_item("胡萝卜种子", 3)
	game_manager.looi.add_item("番茄种子", 2)
	game_manager.looi.add_item("食物", 2)

	# 隐藏面板
	shop_panel.visible = false

	# 连接信号
	game_manager.looi.coins_changed.connect(_update_coins)
	game_manager.looi.energy_changed.connect(_update_energy)
	game_manager.looi.level_up.connect(_update_level)
	game_manager.looi.affection_changed.connect(_update_affection)
	game_manager.looi.inventory_changed.connect(_on_inventory_changed)
	game_manager.looi.farm_changed.connect(_on_farm_changed)

	# 初始更新
	_update_all()

func _process(_delta: float) -> void:
	if game_manager.looi.current_job != LOOI.JobType.IDLE:
		job_progress_bar.value = game_manager.looi.job_progress * 100
		job_progress_bar.visible = true
	else:
		job_progress_bar.visible = false

	# 更新小游戏UI
	_process_mini_game(_delta)

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

# 打工功能

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

# 商店功能

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
		job_label.text = "✅ 购买成功!"
		await get_tree().create_timer(1.5).timeout
		job_label.text = "📋 状态: 空闲"
	else:
		job_label.text = "❌ 金币不足!"
		await get_tree().create_timer(1.5).timeout
		job_label.text = "📋 状态: 空闲"

# 快餐店功能

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

# 背包功能

func _on_inventory_pressed() -> void:
	var inventory_panel = $InventoryPanel
	inventory_panel.visible = not inventory_panel.visible
	if inventory_panel.visible:
		_update_inventory()

func _on_inventory_changed() -> void:
	var inventory_panel = $InventoryPanel
	if inventory_panel.visible:
		_update_inventory()

func _on_farm_changed() -> void:
	var farm_panel = $FarmPanel
	if farm_panel.visible:
		_update_farm()

func _update_inventory() -> void:
	var container = $InventoryPanel/ScrollContainer/InventoryContainer
	for child in container.get_children():
		child.queue_free()

	var looi = game_manager.looi
	if looi.inventory.size() == 0:
		var empty_label = Label.new()
		empty_label.text = "背包是空的"
		container.add_child(empty_label)
		return

	for item_name in looi.inventory:
		var count = looi.inventory[item_name]
		var item_container = HBoxContainer.new()
		container.add_child(item_container)

		var item_label = Label.new()
		item_label.text = "%s x%d" % [item_name, count]
		item_label.custom_minimum_size.x = 150
		item_container.add_child(item_label)

		# 检查是否是作物（可以出售）
		if looi.crop_types.has(item_name):
			var sell_btn = Button.new()
			sell_btn.text = "出售"
			sell_btn.pressed.connect(_on_sell_item_pressed.bind(item_name))
			item_container.add_child(sell_btn)

func _on_sell_item_pressed(item_name: String) -> void:
	var looi = game_manager.looi
	if looi.crop_types.has(item_name):
		var sell_price = looi.crop_types[item_name]["sell_price"]
		if looi.sell_crop(item_name):
			job_label.text = "💰 卖出" + item_name + " +" + str(sell_price) + "金币!"
			await get_tree().create_timer(1.0).timeout
			job_label.text = "📋 状态: 空闲"

# 农场功能

func _on_farm_pressed() -> void:
	var farm_panel = $FarmPanel
	farm_panel.visible = not farm_panel.visible
	if farm_panel.visible:
		_update_farm()

func _update_farm() -> void:
	var grid = $FarmPanel/FarmGrid
	var looi = game_manager.looi

	for i in range(looi.farm_plots.size()):
		var btn = grid.get_child(i)
		if btn == null:
			continue

		var state = looi.farm_plots[i]
		var crop_name = looi.crops[i]

		match state:
			0:
				btn.text = "🌱 空地\n点击种植"
				btn.disabled = false
			1, 2:
				btn.text = "%s\n生长中..." % crop_name
				btn.disabled = false
			3:
				btn.text = "%s\n✅ 可收获!" % crop_name
				btn.disabled = false

func _on_farm_plot_pressed(plot_index: int) -> void:
	var looi = game_manager.looi
	var state = looi.farm_plots[plot_index]

	if state == 0:
		# 显示种植菜单
		_show_plant_menu(plot_index)
	elif state == 1 or state == 2:
		# 浇水
		looi.water_crop(plot_index)
		_update_farm()
	elif state == 3:
		# 收获
		looi.harvest_crop(plot_index)
		_update_farm()

func _show_plant_menu(plot_index: int) -> void:
	var menu_panel = $PlantMenuPanel
	menu_panel.visible = true
	var container = $PlantMenuPanel/PlantContainer
	for child in container.get_children():
		child.queue_free()

	var crops = ["胡萝卜", "番茄", "玉米", "草莓", "西瓜"]
	for crop_name in crops:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(100, 50)
		btn.text = crop_name
		btn.pressed.connect(_on_plant_selected.bind(plot_index, crop_name))
		container.add_child(btn)

	var close_btn = Button.new()
	close_btn.text = "关闭"
	close_btn.pressed.connect(func(): menu_panel.visible = false)
	container.add_child(close_btn)

	# 保存当前选中的plot_index
	menu_panel.set_meta("plot_index", plot_index)

func _on_plant_selected(plot_index: int, crop_name: String) -> void:
	if game_manager.looi.plant_crop(plot_index, crop_name):
		$PlantMenuPanel.visible = false
		_update_farm()
		job_label.text = "🌱 种植成功!"
		await get_tree().create_timer(1.0).timeout
		job_label.text = "📋 状态: 空闲"
	else:
		job_label.text = "❌ 没有" + crop_name + "种子!"
		await get_tree().create_timer(1.0).timeout
		job_label.text = "📋 状态: 空闲"

func _on_close_farm_pressed() -> void:
	$FarmPanel.visible = false

# 宠物功能

func _on_pet_pressed() -> void:
	var pet_panel = $PetPanel
	pet_panel.visible = not pet_panel.visible
	if pet_panel.visible:
		_update_pet()

func _update_pet() -> void:
	var looi = game_manager.looi
	var pet_status = $PetPanel/PetStatusLabel
	var pet_actions = $PetPanel/PetActionsContainer

	if not looi.has_pet:
		pet_status.text = "还没有宠物\n去商店领养一只吧!"
		# 隐藏操作按钮
		for child in pet_actions.get_children():
			child.visible = false
	else:
		var bonus = looi.get_pet_bonus() * 100
		pet_status.text = "%s\n❤️ 快乐度: %.0f%%\n🍖 饱食度: %.0f%%\n💰 加成: +%.0f%%" % [looi.pet_name, looi.pet_happiness, looi.pet_hunger, bonus]
		# 显示操作按钮
		for child in pet_actions.get_children():
			child.visible = true

func _on_feed_pet_pressed() -> void:
	if game_manager.looi.feed_pet():
		_update_pet()

func _on_pet_animal_pressed() -> void:
	if game_manager.looi.pet_animal():
		_update_pet()

func _on_close_pet_pressed() -> void:
	$PetPanel.visible = false

# 小游戏功能

var mini_game_panel: Control = null
var mini_game_click_btn: Button = null

func _on_minigame_pressed() -> void:
	if game_manager.looi.mini_game_active:
		return

	if game_manager.looi.start_mini_game(10.0):
		_show_mini_game()

func _show_mini_game() -> void:
	if mini_game_panel == null:
		mini_game_panel = Panel.new()
		mini_game_panel.custom_minimum_size = Vector2(400, 300)
		mini_game_panel.set_anchors_preset(Control.PRESET_CENTER)
		add_child(mini_game_panel)

		var title = Label.new()
		title.text = "小游戏: 点击得分!"
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.position = Vector2(0, 20)
		title.custom_minimum_size = Vector2(400, 40)
		mini_game_panel.add_child(title)

		mini_game_click_btn = Button.new()
		mini_game_click_btn.text = "点击得分!"
		mini_game_click_btn.custom_minimum_size = Vector2(200, 100)
		mini_game_click_btn.set_anchors_preset(Control.PRESET_CENTER)
		mini_game_click_btn.pressed.connect(_on_mini_game_click)
		mini_game_panel.add_child(mini_game_click_btn)

	mini_game_panel.visible = true
	_update_mini_game_ui()

func _on_mini_game_click() -> void:
	game_manager.looi.click_score(1)
	_update_mini_game_ui()

func _update_mini_game_ui() -> void:
	var looi = game_manager.looi
	if looi.mini_game_active and mini_game_panel != null:
		var time_left = looi.mini_game_duration - looi.mini_game_time
		var score_label = mini_game_panel.get_node_or_null("ScoreLabel")
		if score_label == null:
			score_label = Label.new()
			score_label.name = "ScoreLabel"
			score_label.set_anchors_preset(Control.PRESET_CENTER)
			score_label.position = Vector2(0, 60)
			mini_game_panel.add_child(score_label)

		score_label.text = "时间: %.1f秒\n得分: %d\n目标: %d" % [time_left, looi.mini_game_score, looi.mini_game_target]
	elif not looi.mini_game_active and mini_game_panel != null:
		mini_game_panel.visible = false
		# 显示结果
		var result = looi.mini_game_score * 0.5 * (1.0 + looi.get_pet_bonus())
		job_label.text = "小游戏结束! 获得 %.0f 金币" % result

func _process_mini_game(_delta: float) -> void:
	if game_manager.looi.mini_game_active:
		_update_mini_game_ui()
