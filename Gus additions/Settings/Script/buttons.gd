extends Node

var button_type = null

var time_left = SaveManager.time_limit
var sentences_to_win_adjusted = SaveManager.sentences_needed

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# if value exists?
	#$LevelCount.text = str(sentences_to_win_adjusted)
	#$TimeCount.text = str(time_left)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.aa
#func _process(delta: float) -> void:
#	pass

func display_settings() -> void:
	$LevelCount.text = str(sentences_to_win_adjusted)
	$TimeCount.text = str(time_left)
	SaveManager.time_limit = time_left
	SaveManager.sentences_needed = sentences_to_win_adjusted
	return

func _on_easy_pressed() -> void:
	button_type = "easy"
	time_left = 180.0
	sentences_to_win_adjusted = 2
	display_settings()
	
	
func _on_normal_pressed() -> void:
	button_type = "normal"
	time_left = 150.0
	sentences_to_win_adjusted = 3
	display_settings()
	
	
func _on_hard_pressed() -> void:
	button_type = "hard"
	time_left = 90.0
	sentences_to_win_adjusted = 3
	display_settings()
	
func _on_main_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://Gus additions/Menu/main_menu.tscn")

func _when_button_worked() -> void:
	if button_type == "easy":
		_on_easy_pressed()
		print(time_left)
		print(sentences_to_win_adjusted)
	elif button_type == "normal":
		_on_normal_pressed()
		print(time_left)
		print(sentences_to_win_adjusted)
	elif button_type == "hard":
		_on_hard_pressed()
		print(time_left)
		print(sentences_to_win_adjusted)
	
