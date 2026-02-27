## 食物类 - 可拖拽的食物
extends Area2D

var food_name: String = ""
var _is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var screen_size: Vector2

# 食物价格
var food_prices: Dictionary = {
	"汉堡": 15,
	"薯条": 10,
	"可乐": 8,
	"披萨": 20,
	"炸鸡": 18
}

func _ready() -> void:
	screen_size = get_viewport_rect().size

func set_food(name: String) -> void:
	food_name = name
	$Label.text = name

func _physics_process(_delta: float) -> void:
	if _is_dragging:
		_drag()

func _on_input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if $Label.get_rect().has_point(to_local(event.position)):
				_is_dragging = true
				drag_offset = position - get_global_mouse_position()
				get_viewport().set_input_as_handled()
		elif _is_dragging:
			_is_dragging = false

func _drag() -> void:
	position = get_global_mouse_position() + drag_offset
	position = position.clamp(Vector2.ZERO, screen_size)
