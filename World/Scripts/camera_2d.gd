extends Camera2D

@export var target: Node2D
var following := false

func _process(delta):
	if following and target:
		global_position = global_position.lerp(target.global_position, 8 * delta)
