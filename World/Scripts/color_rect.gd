extends ColorRect

@export var max_alpha := 0.65
@export var pulse_speed := 5.0

var danger_amount := 0.0 # 0 = safe, 1 = dying

func _process(delta):
	var pulse := (sin(Time.get_ticks_msec() / 1000.0 * pulse_speed) + 1.0) / 2.0
	var alpha := danger_amount * max_alpha * (0.45 + pulse * 0.55)

	color = Color(1, 0, 0, alpha)
