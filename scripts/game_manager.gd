## 游戏管理器 - 管理全局游戏状态
extends Node

## 单例实例
static var instance: GameManager

## LOOI 实例
var looi: LOOI

## 游戏是否暂停
var is_paused: bool = false

## 购买物品商店数据
var shop_items: Array[Dictionary] = [
	{"name": "能量药水", "cost": 50.0, "description": "恢复 50 能量", "type": "energy", "value": 50.0},
	{"name": "幸运护符", "cost": 200.0, "description": "打工收益 +10%", "type": "buff", "value": 0.1},
	{"name": "学习书籍", "cost": 150.0, "description": "获得 50 经验", "type": "experience", "value": 50.0},
	{"name": "豪华礼物", "cost": 500.0, "description": "增加 10 好感度", "type": "affection", "value": 10.0},
	{"name": "超级能量饮料", "cost": 100.0, "description": "完全恢复能量", "type": "energy", "value": 100.0},
	{"name": "胡萝卜种子", "cost": 10.0, "description": "种胡萝卜", "type": "seed", "value": "胡萝卜"},
	{"name": "番茄种子", "cost": 15.0, "description": "种番茄", "type": "seed", "value": "番茄"},
	{"name": "玉米种子", "cost": 20.0, "description": "种玉米", "type": "seed", "value": "玉米"},
	{"name": "草莓种子", "cost": 30.0, "description": "种草莓", "type": "seed", "value": "草莓"},
	{"name": "西瓜种子", "cost": 50.0, "description": "种西瓜", "type": "seed", "value": "西瓜"},
	{"name": "宠物食物", "cost": 20.0, "description": "喂养宠物", "type": "pet_food", "value": 1.0},
	{"name": "小猫", "cost": 100.0, "description": "领养小猫 金币+10%", "type": "pet", "value": "小猫"},
	{"name": "小狗", "cost": 150.0, "description": "领养小狗 金币+15%", "type": "pet", "value": "小狗"},
	{"name": "小兔子", "cost": 80.0, "description": "领养小兔子 金币+8%", "type": "pet", "value": "小兔子"},
	{"name": "小鸟", "cost": 120.0, "description": "领养小鸟 金币+12%", "type": "pet", "value": "小鸟"}
]

func _ready() -> void:
	instance = self
	# LOOI 已经是 autoload，直接使用
	looi = LOOI

	# 连接信号
	looi.coins_changed.connect(_on_coins_changed)
	looi.level_up.connect(_on_level_up)
	looi.job_completed.connect(_on_job_completed)

	print("游戏初始化完成!")

func _process(delta: float) -> void:
	if not is_paused:
		looi.update_job(delta)
		looi.update_farm(delta)
		looi.update_pet(delta)
		looi.update_mini_game(delta)

## 购买物品
func purchase_item(item_index: int) -> bool:
	if item_index < 0 or item_index >= shop_items.size():
		return false

	var item = shop_items[item_index]

	match item["type"]:
		"energy":
			if looi.buy_item(item["cost"]):
				looi.restore_energy(item["value"])
				return true
		"buff":
			if looi.buy_item(item["cost"]):
				looi.income_multiplier += item["value"]
				return true
		"experience":
			if looi.buy_item(item["cost"]):
				looi.add_experience(int(item["value"]))
				return true
		"affection":
			if looi.buy_item(item["cost"]):
				looi.change_affection(item["value"])
				return true
		"seed":
			if looi.buy_item(item["cost"]):
				looi.add_item(item["value"] + "种子", 1)
				return true
		"pet_food":
			if looi.buy_item(item["cost"]):
				looi.add_item("食物", 1)
				return true
		"pet":
			if looi.adopt_pet(item["value"]):
				return true

	return false

## 信号回调
func _on_coins_changed(amount: float) -> void:
	print("金币变化: %s %+.2f" % [looi.looi_name, amount])

func _on_level_up(new_level: int) -> void:
	print("升级了! 等级: %d" % new_level)

func _on_job_completed(job_type: LOOI.JobType, reward: float) -> void:
	print("工作完成: %s, 获得: %.2f 金币" % [LOOI.JobType.keys()[job_type], reward])

## 暂停/恢复游戏
func toggle_pause() -> void:
	is_paused = not is_paused
	get_tree().paused = is_paused
