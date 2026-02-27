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
	{"name": "超级能量饮料", "cost": 100.0, "description": "完全恢复能量", "type": "energy", "value": 100.0}
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
