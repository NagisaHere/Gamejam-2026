extends Node

var button_type: String = ""

var time_left: float = 150.0
var sentences_to_win_adjusted: int = 3
var dropkey_rate: float = 2.5

const MAX_TIME: float = 5940.0;
const MAX_LEVEL: int = 99;
const MAX_DROPKEY: float = 100;

@onready var DifficultyChange_Sound = $Sounds/ChangeDifficultySound

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$"Transition/Fade Transition".show()
	$"Transition/Fade Transition/AnimationPlayer".play("Fade_in")
	await $"Transition/Fade Transition/AnimationPlayer".animation_finished
	$"Transition/Fade Transition".hide()
	
	# if value exists?
	display_settings();
	$BongoCat/CheckBox.button_pressed = SaveManager.BongoCat
	
	#check if random or toggled mode
	_on_option_button_toggled(SaveManager.time_mode)
	$DropKeyControl/OptionButton.button_pressed = SaveManager.time_mode
	
	


func display_settings() -> void:
	$LevelControl/LevelCount.text = str(sentences_to_win_adjusted)
	$TimeControl/TimeCount.text = str(int(time_left/60)) # I hope you do floor div by default mins
	$TimeControl/TimeSecond.text = str(int(time_left) % 60)
	$DropKeyControl/DropKeyCount.text = str(dropkey_rate) + "%"
	SaveManager.time_limit = time_left
	SaveManager.sentences_needed = sentences_to_win_adjusted
	SaveManager.dropkey_level = dropkey_rate
	return

func _on_easy_pressed() -> void:
	DifficultyChange_Sound.play()
	await get_tree().create_timer(0.6).timeout
	
	button_type = "easy"
	time_left = 180.0
	sentences_to_win_adjusted = 2
	display_settings()
	$Difficulty/Normal.button_pressed = false
	$Difficulty/Hard.button_pressed = false
	SaveManager.difficulty = "easy"
	
	
func _on_normal_pressed() -> void:
	DifficultyChange_Sound.play()
	await get_tree().create_timer(0.6).timeout
	
	button_type = "normal"
	time_left = 150.0
	sentences_to_win_adjusted = 3
	display_settings()
	$Difficulty/Easy.button_pressed = false
	$Difficulty/Hard.button_pressed = false
	SaveManager.difficulty = "normal"
	
	
func _on_hard_pressed() -> void:
	DifficultyChange_Sound.play()
	await get_tree().create_timer(0.6).timeout
	
	button_type = "hard"
	time_left = 90.0
	sentences_to_win_adjusted = 3
	display_settings()
	$Difficulty/Easy.button_pressed = false
	$Difficulty/Normal.button_pressed = false
	SaveManager.difficulty = "hard"
	
	
func _on_main_menu_pressed() -> void:
	$"Transition/Fade Transition".show()
	$"Transition/Fade Transition/AnimationPlayer".play("Fade_out")
	await $"Transition/Fade Transition/AnimationPlayer".animation_finished
	get_tree().change_scene_to_file("res://Gus additions/Menu/main_menu.tscn")
	

func _on_min_up_pressed() -> void:
	$Sounds/MinuteTickUp.play()
	time_left += 60.0;
	if (time_left >= MAX_TIME):
		time_left = MAX_TIME;
	display_settings();
	return

func _on_min_down_pressed() -> void:
	$Sounds/MinuteTickDown.play()
	time_left -= 60.0;
	if (time_left <= 0):
		time_left = 0;
	display_settings();
	return

func _on_sec_up_pressed() -> void:
	$Sounds/SecTickUp.play()
	time_left += 1.0;
	if (time_left >= MAX_TIME):
		time_left = MAX_TIME;
	display_settings();
	return

func _on_sec_down_pressed() -> void:
	$Sounds/SecTickDown.play()
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


func _on_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		SaveManager.BongoCat = true
		BongoCat.enable()
	else:
		SaveManager.BongoCat = false
		BongoCat.disable()
		

var is_holding_dropkeyUP = false
var is_holding_dropkeyDOWN = false

func increment_dropkey():
	$Sounds/MinuteTickUp.play()
	dropkey_rate += 0.5;
	if (dropkey_rate >= MAX_DROPKEY):
		dropkey_rate = MAX_DROPKEY;
	display_settings();
	return
	
func decrement_dropkey():
	$Sounds/MinuteTickDown.play()
	dropkey_rate -= 0.5;
	if (dropkey_rate<= 0):
		dropkey_rate = 0;
	display_settings();
	return

func _on_drop_key_up_button_down() -> void:
	is_holding_dropkeyUP = true
	increment_dropkey()
	await get_tree().create_timer(0.4).timeout
	
	# Loop while the button remains held down
	while is_holding_dropkeyUP:
		increment_dropkey()
		await get_tree().create_timer(0.05).timeout


func _on_drop_key_up_button_up() -> void:
	is_holding_dropkeyUP = false


func _on_drop_key_down_button_down() -> void:
	is_holding_dropkeyDOWN = true
	decrement_dropkey()
	await get_tree().create_timer(0.4).timeout
	
	# Loop while the button remains held down
	while is_holding_dropkeyDOWN:
		decrement_dropkey()
		await get_tree().create_timer(0.05).timeout


func _on_drop_key_down_button_up() -> void:
	is_holding_dropkeyDOWN = false


func _on_option_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		$DropKeyControl/Random.modulate = Color(0.38, 0.38, 0.38, 1.0)
		$DropKeyControl/Time.modulate = Color(1.0, 1.0, 1.0, 1.0)
		SaveManager.time_mode = true
	else:
		$DropKeyControl/Time.modulate = Color(0.38, 0.38, 0.38, 1.0)
		$DropKeyControl/Random.modulate = Color(1.0, 1.0, 1.0, 1.0)
		SaveManager.time_mode = false
