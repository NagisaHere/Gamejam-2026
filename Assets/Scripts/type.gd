extends Node2D

signal fingers_changed(value)
var passphrases = []
var active_enemy = null
var current_letter_index: int = -1 # undefined
var fingers_remaining: int = 10 
var prev_keycode: int = -1 # undefined for now
var backspace_is_held := false
var sentences_completed := 0
var sentences_to_win := 3
@onready var enemy = $EnemyContainer/Enemy
@onready var enemy_container = $EnemyContainer
@onready var fingers_label = $"CanvasLayer/VBoxContainer/BottomRow/fingers-value"
@onready var warning_label = $Label
var current_mistakes: String = ""

func _ready() -> void:
	#start_game()
	randomize()
	load_phrases()
	spawn_phrase()
	
func _win_game() -> void:
	get_tree().change_scene_to_file("res://Scenes/veryhappy.tscn")
	SaveManager.current_save = SaveData.new()
	SaveManager.current_save.test_data = [{"name": "no-one","time": $"../Timer".time_left, "score": fingers_remaining }]
	SaveManager.save_data()
	
	
	

func spawn_phrase():
	var index = randi_range(0, passphrases.size() - 1)
	var phrase = passphrases[index].strip_edges()
	enemy.set_prompt(phrase)

	active_enemy = enemy
	current_letter_index = 0
	current_mistakes = ""

	active_enemy.set_next_character(current_letter_index)
	
func load_phrases():
	var file = FileAccess.open("res://World/AssetsWorld/phrases.txt", FileAccess.READ)
	var text = file.get_as_text()
	passphrases = text.split("\n")
	
func _check_win(prompt: String) -> void:
	if current_letter_index == prompt.length() and current_mistakes.length() == 0:
		sentences_completed += 1
		print("done sentences:", sentences_completed)

		if sentences_completed >= sentences_to_win:
			_win_game()
		else:
			spawn_phrase()
		
func find_new_active_enemy(typed_character: String):
	for enemy in enemy_container.get_children():
		var prompt = enemy.get_prompt()
		var next_character = prompt.substr(0, 1)
		if next_character == typed_character:
			print("found new enemy that starts with %s" % next_character)
			active_enemy = enemy
			current_letter_index = 1
			active_enemy.set_next_character(current_letter_index)
	return

func _game_over() -> void:
	get_tree().change_scene_to_file("res://Gus additions/BadEnding/BadEnding_.tscn")
	
func show_warning_message():
	warning_label.text = "Key Stroke"
	warning_label.visible = true

	await get_tree().create_timer(0.8).timeout

	warning_label.visible = false
>>>>>>> d923241 (idk honestly, added animations and changed format of the terminal)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		
		var prompt = active_enemy.get_prompt()
		var next_character = prompt.substr(current_letter_index, 1)
		var typed_event = event as InputEventKey
		var key_typed = PackedByteArray([typed_event.unicode]).get_string_from_utf8()

		if event.keycode == KEY_BACKSPACE:
			if event.is_pressed():
				if not backspace_is_held:
					fingers_remaining -= 1
					fingers_changed.emit(fingers_remaining)
					backspace_is_held = true

					if fingers_remaining == 0:
						_game_over()

				if active_enemy != null:
					if current_mistakes.length() > 0:
						current_mistakes = current_mistakes.erase(current_mistakes.length() - 1)
					elif current_letter_index > 0:
						current_letter_index -= 1

					active_enemy.set_next_character(current_letter_index, current_mistakes)

				return
			else:
				backspace_is_held = false
				return

		if not event.is_pressed() or event.is_echo():
			return
			
		if randf() < (10 - fingers_remaining) * 0.0:
			var special_chars = "!@#$%^&*"
			key_typed = special_chars[randi() % special_chars.length()]
		
		if next_character != " " and randf() < (10 - fingers_remaining) * 0.025:
			active_enemy.set_next_character(current_letter_index, current_mistakes, true)
			show_warning_message()
			#Sound of faulty key, like fallout one
			return

		if active_enemy == null:
			find_new_active_enemy(key_typed)
			return

		#var prompt = active_enemy.get_prompt()
		#var next_character = prompt.substr(current_letter_index, 1)

		if current_mistakes.length() > 0:
			current_mistakes += key_typed
		else:
			if key_typed == next_character:
				current_letter_index += 1
			else:
				current_mistakes += key_typed

		active_enemy.set_next_character(current_letter_index, current_mistakes)
		_check_win(prompt)

#func start_game():
	##game_over_screen.hide()
	##difficulty = 0
	##enemies_killed = 0
	##difficulty_value.text = str(0)
	##killed_value.text = str(0)
	#randomize()
	##spawn_timer.start()
	##difficulty_timer.start()
	#spawn_enemy()
