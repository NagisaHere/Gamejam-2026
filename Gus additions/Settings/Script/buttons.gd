extends Node

var button_type: String = ""

var time_left: float = 150.0
var sentences_to_win_adjusted: int = 3

const MAX_TIME: float = 5940.0;
const MAX_LEVEL: int = 99;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# if value exists?
	display_settings();


# Called every frame. 'delta' is the elapsed time since the previous frame.aa
#func _process(delta: float) -> void:
#	pass

func display_settings() -> void:
	$LevelControl/LevelCount.text = str(sentences_to_win_adjusted)
	$TimeControl/TimeCount.text = str(int(time_left/60)) # I hope you do floor div by default mins
	$TimeControl/TimeSecond.text = str(int(time_left) % 60)
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

func _on_min_up_pressed() -> void:
	time_left += 60.0;
	if (time_left >= MAX_TIME):
		time_left = MAX_TIME;
	display_settings();
	return

func _on_min_down_pressed() -> void:
	time_left -= 60.0;
	if (time_left <= 0):
		time_left = 0;
	display_settings();
	return

func _on_sec_up_pressed() -> void:
	time_left += 1.0;
	if (time_left >= MAX_TIME):
		time_left = MAX_TIME;
	display_settings();
	return

func _on_sec_down_pressed() -> void:
	time_left -= 1.0;
	if (time_left <= 0):
		time_left = 0;
	display_settings();
	return

func _on_level_up_pressed() -> void:
	sentences_to_win_adjusted += 1;
	if (sentences_to_win_adjusted > MAX_LEVEL):
		sentences_to_win_adjusted = MAX_LEVEL;
	display_settings();
	$Sounds/LevelUpSound.play()
	return

func _on_level_down_pressed() -> void:
	sentences_to_win_adjusted -= 1;
	if (sentences_to_win_adjusted <= 0):
		sentences_to_win_adjusted = 1
	display_settings();
	$Sounds/LevelDownSound.play()
	return

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
