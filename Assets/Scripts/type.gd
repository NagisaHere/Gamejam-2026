extends Node2D

var active_enemy = null
var current_letter_index: int = -1 # undefined
var fingers_remaining: int = 10 
var prev_keycode: int = -1 # undefined for now
@onready var enemy_container = $EnemyContainer
@onready var fingers_label = $"CanvasLayer/VBoxContainer/BottomRow/fingers-value"
var current_mistakes: String = ""

#func _ready() -> void:
	#start_game()


#func spawn_enemy():
	#return
	
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

func _check_win(prompt: String) -> void:
	if current_letter_index == prompt.length() and current_mistakes.length() == 0:
		print("done")

func _game_over() -> void:
	return

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		var typed_event = event as InputEventKey
		var key_typed = PackedByteArray([typed_event.unicode]).get_string_from_utf8()
		if active_enemy == null:
			find_new_active_enemy(key_typed)
			return
		if event.keycode == KEY_BACKSPACE:
			if prev_keycode != event.keycode:
				## didnt hold down backspace, first press, so decrement the fingers
				fingers_remaining -= 1
				if fingers_remaining == 0:
					# game over
					_game_over()
			if current_mistakes.length() > 0:
				current_mistakes = current_mistakes.erase(current_mistakes.length() - 1)
			elif current_letter_index > 0:
				current_letter_index -= 1
			active_enemy.set_next_character(current_letter_index, current_mistakes)
			prev_keycode = event.keycode
			return
		var prompt = active_enemy.get_prompt()
		var next_character = prompt.substr(current_letter_index, 1)
		if current_mistakes.length() > 0:
			current_mistakes += key_typed
		else:
			if key_typed == next_character:
				print("successfully typed %s" % key_typed)
				current_letter_index += 1
			else:
				current_mistakes += key_typed
				print("incorrectly typed %s instead of %s" % [key_typed, next_character])
		active_enemy.set_next_character(current_letter_index, current_mistakes)
		_check_win(prompt)
		prev_keycode = event.keycode

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
