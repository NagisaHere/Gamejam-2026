extends CharacterBody2D

@export var speed := 200.0
@export var vertical_factor := 0.5

var cutscene_mode := false

var min_pos := Vector2(-500, 130)
var max_pos := Vector2(500, 250)

func _physics_process(delta):
	if cutscene_mode:
		velocity = Vector2.ZERO
		return

	var input_vector := Vector2.ZERO

	input_vector.x = Input.get_axis("ui_left", "ui_right")
	input_vector.y = Input.get_axis("ui_up", "ui_down") * vertical_factor

	input_vector = input_vector.normalized()

	velocity = input_vector * speed
	move_and_slide()

	global_position.x = clamp(global_position.x, min_pos.x, max_pos.x)
	global_position.y = clamp(global_position.y, min_pos.y, max_pos.y)
