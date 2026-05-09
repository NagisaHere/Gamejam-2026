extends CanvasLayer

var danger_amount := 0.0
@export var max_alpha := 0.65
@export var pulse_speed := 5.0

@onready var frame := $ColorRect

func _ready() -> void:
	layer = 100
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_fingers_remaining(10)

func _process(delta):
	var pulse := (sin(Time.get_ticks_msec() / 1000.0 * pulse_speed) + 1.0) / 2.0
	frame.color.a = danger_amount * max_alpha * (0.45 + pulse * 0.55)

func set_fingers_remaining(value: int):
	print("overlay received:", value)
	danger_amount = float(10 - value) / 10.0
