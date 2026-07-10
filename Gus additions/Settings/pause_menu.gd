extends Control

func _ready() -> void:
	$".".hide()
	$AnimationPlayer.play("RESET")
	PauseMenu.get_node("VideoManager").play_video("res://Tutorial/first.ogv")

func resume():
	get_tree().paused =false
	$AnimationPlayer.play_backwards("blur")
	$".".hide()
	
func pause():
	get_tree().paused = true
	$AnimationPlayer.play("blur")
	$".".show()
	
func test_esc():
	if Input.is_action_just_pressed("Pause") and !get_tree().paused:
		pause()
		
	elif Input.is_action_just_pressed("Pause") and get_tree().paused:
		resume()
		
func _process(delta: float) -> void:
	test_esc()

func _on_resume_pressed() -> void:
	resume()
	

func _on_restart_pressed() -> void:
	resume()
	get_tree().reload_current_scene()
	

func _on_main_menu_pressed() -> void:
		resume()
		get_tree().change_scene_to_file("res://Gus additions/Menu/main_menu.tscn")


func _on_tutorial_pressed() -> void:
	$AnimationPlayer.play_backwards("blur")
	$".".hide()
	var overlay = preload("res://Tutorial/Tutorial.tscn").instantiate()
	add_child(overlay)
	#get_tree().change_scene_to_file("res://Tutorial/Tutorial.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
