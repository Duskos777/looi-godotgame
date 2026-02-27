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
	STUDY           # 学习
}

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
