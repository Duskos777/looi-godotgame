## LOOI 经济系统核心类
extends Node

## LOOI 的名字
var looi_name: String = "LOOI"

## 当前金币数量
var coins: float = 0.0

## 经验值
var experience: int = 0

## 等级
var level: int = 1

## 好感度 (与用户的关系)
var affection: float = 50.0

## 能量值 (用于打工)
var energy: float = 100.0
var max_energy: float = 100.0

## 打工类型枚举
enum JobType {
	IDLE,           # 空闲
	MINE_COIN,      # 挖矿
	TRADE,          # 交易
	QUEST,          # 任务
	STUDY,          # 学习
	FARM,           # 农场
	PET              # 宠物互动
}

# 背包系统
var inventory: Dictionary = {}  # {item_name: count}
var inventory_max_size: int = 20

# 农场系统
# 土地状态: 0=空, 1=已种植, 2=生长中, 3=可收获
var farm_plots: Array = [0, 0, 0, 0, 0, 0]  # 6块土地
var farm_timers: Array = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var crops: Array = ["", "", "", "", "", ""]  # 当前种植的作物
var farm_growth_time: float = 30.0  # 生长时间30秒

# 可种植的作物
var crop_types: Dictionary = {
	"胡萝卜": {"sell_price": 15, "grow_time": 20, "exp": 5},
	"番茄": {"sell_price": 20, "grow_time": 30, "exp": 8},
	"玉米": {"sell_price": 25, "grow_time": 45, "exp": 10},
	"草莓": {"sell_price": 30, "grow_time": 60, "exp": 15},
	"西瓜": {"sell_price": 50, "grow_time": 90, "exp": 25}
}

# 宠物系统
var pet_name: String = ""
var pet_happiness: float = 50.0  # 宠物快乐度
var pet_hunger: float = 80.0    # 宠物饱食度
var pet_type: String = ""        # 宠物类型
var has_pet: bool = false

# 宠物类型及加成
var pet_types: Dictionary = {
	"小猫": {"cost": 100, "bonus": 0.1, "description": "金币+10%"},
	"小狗": {"cost": 150, "bonus": 0.15, "description": "金币+15%"},
	"小兔子": {"cost": 80, "bonus": 0.08, "description": "金币+8%"},
	"小鸟": {"cost": 120, "bonus": 0.12, "description": "金币+12%"}
}

# 小游戏
var mini_game_active: bool = false
var mini_game_score: int = 0
var mini_game_target: int = 0
var mini_game_time: float = 0.0
var mini_game_duration: float = 10.0

## 当前工作
var current_job: JobType = JobType.IDLE

## 工作进度 (0.0 - 1.0)
var job_progress: float = 0.0

## 工作所需时间(秒)
var job_duration: float = 5.0

## 打工加成系数
var income_multiplier: float = 1.0

## 信号
signal coins_changed(amount: float)
signal energy_changed(amount: float)
signal level_up(new_level: int)
signal job_completed(job_type: JobType, reward: float)
signal affection_changed(amount: float)
signal inventory_changed()
signal farm_changed()

func _ready() -> void:
	# 初始给予一些启动资金
	coins = 100.0
	energy = max_energy

## 增加金币
func add_coins(amount: float) -> void:
	coins += amount
	coins_changed.emit(amount)

## 花费金币
func spend_coins(amount: float) -> bool:
	if coins >= amount:
		coins -= amount
		coins_changed.emit(-amount)
		return true
	return false

## 增加经验
func add_experience(exp: int) -> void:
	experience += exp
	_check_level_up()

## 检查升级
func _check_level_up() -> void:
	var exp_needed := level * 100
	while experience >= exp_needed:
		experience -= exp_needed
		level += 1
		level_up.emit(level)
		# 升级恢复能量
		energy = max_energy
		energy_changed.emit(max_energy)

## 恢复能量
func restore_energy(amount: float) -> void:
	energy = min(energy + amount, max_energy)
	energy_changed.emit(amount)

## 消耗能量
func consume_energy(amount: float) -> bool:
	if energy >= amount:
		energy -= amount
		energy_changed.emit(-amount)
		return true
	return false

## 开始工作
func start_job(job_type: JobType, duration: float = 5.0) -> bool:
	if current_job != JobType.IDLE:
		return false # 已经有工作在做了

	if not consume_energy(20.0): # 工作需要消耗20能量
		return false

	current_job = job_type
	job_duration = duration
	job_progress = 0.0
	return true

## 更新工作进度 (每帧调用)
func update_job(delta: float) -> void:
	if current_job == JobType.IDLE:
		return

	job_progress += delta / job_duration

	if job_progress >= 1.0:
		_complete_job()

## 完成工作
func _complete_job() -> void:
	var reward: float = 0.0

	match current_job:
		JobType.MINE_COIN:
			reward = 10.0 * income_multiplier * randf_range(0.8, 1.5)
		JobType.TRADE:
			reward = 15.0 * income_multiplier * randf_range(0.8, 1.5)
		JobType.QUEST:
			reward = 25.0 * income_multiplier * randf_range(0.8, 1.5)
		JobType.STUDY:
			reward = 5.0
			add_experience(20)

	add_coins(reward)
	job_completed.emit(current_job, reward)

	current_job = JobType.IDLE
	job_progress = 0.0

## 改变好感度
func change_affection(amount: float) -> void:
	affection = clamp(affection + amount, 0.0, 100.0)
	affection_changed.emit(amount)

## 购买物品
func buy_item(item_cost: float, item_name: String = "") -> bool:
	if spend_coins(item_cost):
		return true
	return false

## 获取状态信息
func get_status() -> Dictionary:
	return {
		"name": name,
		"coins": coins,
		"experience": experience,
		"level": level,
		"affection": affection,
		"energy": energy,
		"max_energy": max_energy,
		"current_job": JobType.keys()[current_job],
		"job_progress": job_progress
	}

# 背包系统方法

# 添加物品到背包
func add_item(item_name: String, count: int = 1) -> bool:
	var total_items = 0
	for k in inventory:
		total_items += inventory[k]
	if total_items >= inventory_max_size:
		return false
	inventory[item_name] = inventory.get(item_name, 0) + count
	inventory_changed.emit()
	return true

# 移除物品
func remove_item(item_name: String, count: int = 1) -> bool:
	if inventory.get(item_name, 0) >= count:
		inventory[item_name] -= count
		if inventory[item_name] <= 0:
			inventory.erase(item_name)
		inventory_changed.emit()
		return true
	return false

# 获取物品数量
func get_item_count(item_name: String) -> int:
	return inventory.get(item_name, 0)

# 是否有物品
func has_item(item_name: String) -> bool:
	return inventory.has(item_name) and inventory[item_name] > 0

# 农场系统方法

# 种植作物
func plant_crop(plot_index: int, crop_name: String) -> bool:
	if plot_index < 0 or plot_index >= farm_plots.size():
		return false
	if farm_plots[plot_index] != 0:
		return false  # 已经有作物
	if not crop_types.has(crop_name):
		return false
	if not has_item(crop_name + "种子"):
		return false  # 没有种子

	remove_item(crop_name + "种子", 1)
	farm_plots[plot_index] = 1  # 已种植
	crops[plot_index] = crop_name
	farm_timers[plot_index] = 0.0
	farm_changed.emit()
	return true

# 浇水促进生长
func water_crop(plot_index: int) -> bool:
	if plot_index < 0 or plot_index >= farm_plots.size():
		return false
	if farm_plots[plot_index] == 0:
		return false
	if farm_plots[plot_index] == 3:
		return false  # 已成熟

	farm_plots[plot_index] = 2  # 生长中
	farm_changed.emit()
	return true

# 更新农场
func update_farm(delta: float) -> void:
	for i in range(farm_plots.size()):
		if farm_plots[i] == 1 or farm_plots[i] == 2:  # 生长中
			farm_timers[i] += delta
			var crop_name = crops[i]
			if crop_name != "" and crop_types.has(crop_name):
				if farm_timers[i] >= crop_types[crop_name]["grow_time"]:
					farm_plots[i] = 3  # 可收获

# 收获作物
func harvest_crop(plot_index: int) -> bool:
	if plot_index < 0 or plot_index >= farm_plots.size():
		return false
	if farm_plots[plot_index] != 3:
		return false  # 未成熟

	var crop_name = crops[plot_index]
	if crop_name == "":
		return false

	var crop_data = crop_types[crop_name]
	add_coins(crop_data["sell_price"])
	add_experience(crop_data["exp"])

	# 清空土地
	farm_plots[plot_index] = 0
	crops[plot_index] = ""
	farm_timers[plot_index] = 0.0
	farm_changed.emit()
	return true

# 购买种子
func buy_seed(crop_name: String) -> bool:
	if not crop_types.has(crop_name):
		return false
	var seed_cost = crop_types[crop_name]["sell_price"] / 2
	if spend_coins(seed_cost):
		add_item(crop_name + "种子", 1)
		return true
	return false

# 出售作物
func sell_crop(crop_name: String) -> bool:
	if not crop_types.has(crop_name):
		return false
	if not has_item(crop_name):
		return false
	var sell_price = crop_types[crop_name]["sell_price"]
	remove_item(crop_name, 1)
	add_coins(sell_price)
	return true

# 宠物系统方法

# 领养宠物
func adopt_pet(pet_type_name: String) -> bool:
	if has_pet:
		return false  # 已经有宠物
	if not pet_types.has(pet_type_name):
		return false
	var cost = pet_types[pet_type_name]["cost"]
	if spend_coins(cost):
		pet_type = pet_type_name
		pet_name = pet_type_name
		has_pet = true
		pet_happiness = 50.0
		pet_hunger = 80.0
		return true
	return false

# 喂养宠物
func feed_pet() -> bool:
	if not has_pet:
		return false
	if pet_hunger >= 100.0:
		return false
	if has_item("食物"):
		remove_item("食物", 1)
		pet_hunger = min(pet_hunger + 30, 100.0)
		pet_happiness = min(pet_happiness + 10, 100.0)
		return true
	elif spend_coins(10):
		pet_hunger = min(pet_hunger + 30, 100.0)
		pet_happiness = min(pet_happiness + 10, 100.0)
		return true
	return false

# 抚摸宠物
func pet_animal() -> bool:
	if not has_pet:
		return false
	pet_happiness = min(pet_happiness + 15, 100.0)
	change_affection(5)
	return true

# 获取宠物加成
func get_pet_bonus() -> float:
	if not has_pet:
		return 0.0
	# 快乐度和饱食度影响加成
	var happiness_factor = pet_happiness / 100.0
	return pet_types[pet_type]["bonus"] * happiness_factor

# 更新宠物状态
func update_pet(delta: float) -> void:
	if not has_pet:
		return
	# 饱食度逐渐下降
	pet_hunger = max(pet_hunger - delta * 2, 0)
	# 快乐度随饱食度变化
	if pet_hunger < 30:
		pet_happiness = max(pet_happiness - delta * 5, 0)
	else:
		pet_happiness = min(pet_happiness + delta * 1, 100.0)

# 小游戏方法

# 开始小游戏
func start_mini_game(duration: float = 10.0) -> bool:
	if mini_game_active:
		return false
	if not consume_energy(10):
		return false
	mini_game_active = true
	mini_game_score = 0
	mini_game_time = 0.0
	mini_game_duration = duration
	mini_game_target = randi() % 50 + 50  # 目标50-100
	return true

# 更新小游戏
func update_mini_game(delta: float) -> void:
	if not mini_game_active:
		return
	mini_game_time += delta
	if mini_game_time >= mini_game_duration:
		end_mini_game()

# 点击得分
func click_score(points: int = 1) -> void:
	if mini_game_active:
		mini_game_score += points

# 结束小游戏
func end_mini_game() -> void:
	if not mini_game_active:
		return
	mini_game_active = false
	var reward = mini_game_score * 0.5 * (1.0 + get_pet_bonus())
	add_coins(reward)
	add_experience(mini_game_score / 5)
