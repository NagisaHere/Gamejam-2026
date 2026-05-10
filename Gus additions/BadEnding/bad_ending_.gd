extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_file("res://Gus additions/Menu/main_menu.tscn")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Gus additions/Menu/main_menu.tscn")



func _on_alarm_finished() -> void:
	$AnimationPlayer/alarm.play()
