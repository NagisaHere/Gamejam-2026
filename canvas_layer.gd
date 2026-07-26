extends Control

func _ready():
	await get_tree().create_timer(8.0).timeout
	get_tree().change_scene_to_file("res://Gus additions/Scoreboard/Scoreboard.tscn")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
