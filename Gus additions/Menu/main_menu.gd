extends Node2D

var button_type = null

func _ready() -> void:
	$"Fade Transition".show()
	$"Fade Transition/AnimationPlayer".play("Fade_in")
	await $"Fade Transition/AnimationPlayer".animation_finished
	$"Fade Transition".hide()

func _on_start_pressed() -> void:
	button_type = "start"
	$"Fade Transition".show()
	$"Fade Transition/Fade_Timer".start()
	$"Fade Transition/AnimationPlayer".play("Fade_out")


func _on_options_pressed() -> void:
	button_type = "options"
	$"Fade Transition".show()
	$"Fade Transition/Fade_Timer".start()
	$"Fade Transition/AnimationPlayer".play("Fade_out")


func _on_quit_pressed() -> void:
	button_type = "quit"
	$"Fade Transition".show()
	$"Fade Transition/Fade_Timer".start()
	$"Fade Transition/AnimationPlayer".play("Fade_out")
	get_tree().quit()


func _on_fade_timer_timeout() -> void:
	if button_type == "start":
		get_tree().change_scene_to_file("res://World/Scenes/WorldAnimation.tscn")
	elif button_type == "quit":
		get_tree().quit()
	elif button_type == "options":
		get_tree().change_scene_to_file("res://placeholder_game_scene.tscn")
	
