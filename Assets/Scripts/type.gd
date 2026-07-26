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
var killed_fingers: Array[int] = []
var drop_rate = SaveManager.dropkey_level/float(100)

var dropkey_ready = false
signal restart_timer
signal finger_lost

#Hand modifiers
var no_left := false
var no_right := false
var restrict_modifier := false
var random_freeze_modifier := false
var random_frozen_fingers := []
var numberOf_random_frozen_fingers := 3

func _ready() -> void:
	# 1. Instantiate the BluetoothManager and add it to the scene tree
	if not OS.has_feature("web"):
		if ClassDB.class_exists("BluetoothManager"):
			bluetooth_manager = ClassDB.instantiate("BluetoothManager")
		add_child(bluetooth_manager)
		
		# 2. Connect core manager signals
		bluetooth_manager.adapter_initialized.connect(_on_adapter_initialized)
		bluetooth_manager.device_discovered.connect(_on_device_discovered)
		bluetooth_manager.scan_stopped.connect(_on_scan_stopped)
		
		bluetooth_manager.initialize()

	# set time and level count from settings
	sentences_to_win = SaveManager.sentences_needed
	$"../Timer".wait_time = SaveManager.time_limit
	randomize()
	load_phrases()
	spawn_phrase()
	
	#challenge mode setups
	if no_left == true:
		kill_left()
	
	if no_right == true:
		kill_right()
	
	if restrict_modifier == true:
		restrict_fingers([0,1,2,3,4], 90)
	
	if random_freeze_modifier == true:
		$"../Freeze_timer".start()
	
	#var popups: Array[Callable] = [
	#			open_popup2,
	#			open_popup1
	#		]
	#popups.pick_random().call()
	if SaveManager.time_mode:
		$"../DropKeyTimer/ProgressBar".show()
		$"../DropKeyTimer/RichTextLabel".show()
	else:
		$"../DropKeyTimer/ProgressBar".hide()
		$"../DropKeyTimer/RichTextLabel".hide()
			
func kill_left():
	for fingers_toKill in [0,1,2,3,4]:
			_kill_finger(fingers_toKill)
		
#TODO replace with indices for left hand
func kill_right():
	for fingers_toKill in [0,1,2,3,4]:
			_kill_finger(fingers_toKill)

#pass a list of the fingers you want to restrict and the angle from (restrict)0->180(relax)
func restrict_fingers(fingers:Array, restriction_angle:int) -> void:
	for finger in fingers:
		#only restrict fingers that are alive
		if not killed_fingers.has(finger):
			_move_finger_to_angle(finger, restriction_angle)
	
func _on_freeze_timer_timeout() -> void:
	#grab remaining fingers
	var available_fingers = []
	for finger in [1,2,3,4,5,6,7,8,9,0]:
		if not killed_fingers.has(finger):
			available_fingers.append(finger)
			
	#free all previously frozen fingers
	for finger in random_frozen_fingers:
		_unrestrict_finger(finger)
	
	#add chosen fingers to list and kill/freeze temporarily
	for finger in range(0,numberOf_random_frozen_fingers):
		random_frozen_fingers.append(available_fingers.pick_random())
	for finger in random_frozen_fingers:
		_move_finger_to_angle(finger, 0)
	#TODO maybe make it killed so it doesn't overlap maybe
	


func _win_game() -> void:
	SaveManager.temp_time = $"../Timer".time_left
	SaveManager.temp_score = fingers_remaining

	if not OS.has_feature("web"):
		_stop_all_servos()

	# 2. Change to the popup scene
	# This current scene (and this script) will now be destroyed
	get_tree().change_scene_to_file("res://popup.tscn")

func spawn_phrase():
	var index = randi_range(0, passphrases.size() - 1)
	var phrase = passphrases[index].strip_edges()
	print("passphrase")
	print(phrase)
	enemy.set_prompt(phrase)

	active_enemy = enemy
	current_letter_index = 0
	current_mistakes = ""

	active_enemy.set_next_character(current_letter_index)

func load_phrases():
	var file = FileAccess.open("res://World/AssetsWorld/phrases.txt", FileAccess.READ)
	var text = file.get_as_text()
	passphrases = text.split("\n")
	if (not passphrases.is_empty()): # last is empty string, not good practice but filter doesnt work idk
		passphrases.remove_at(passphrases.size() - 1)

#Run to check if win conditions are now fufilled
func _check_win(prompt: String) -> void:
	if current_letter_index == prompt.length() and current_mistakes.length() == 0:
		sentences_completed += 1
		#print("done sentences:", sentences_completed)
	
		
		if sentences_completed >= sentences_to_win:
			_win_game()
		else:
			#open a random authentication protocol
			$"../PopUp_open".play()
			var popups: Array[Callable] = [
				open_popup2,
				open_popup1
			]
		
			popups.pick_random().call()
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

#game over transition
func _game_over() -> void:
	if not OS.has_feature("web"):
		_stop_all_servos()
	$"../Death/DeathGlow".modulate.a = 20 #fade is in computer
	
	#gameover transition
	$"../Fadeout/Fade Transition".show()
	$"../Fadeout/Fade Transition/Fade_Timer".start()
	$"../Fadeout/Fade Transition/AnimationPlayer".play("Fade_out")

#change scene once gameover transition has finished
func _on_fade_timer_timeout() -> void:
	get_tree().change_scene_to_file("res://Gus additions/BadEnding/BadEnding_.tscn")


func show_warning_message():
	warning_label.text = "Key Stroke Dropped"
	warning_label.visible = true

	await get_tree().create_timer(0.8).timeout

	warning_label.visible = false

# determine what fingers have not been killed
# 0-4 = right hand, 5-9 = left hand
func _determine_esp32_message():
#  If all fingers are dead, return immediately
	if killed_fingers.size() >= 10:
		print("All fingers are dead. Cannot select a new one.")
# determine what fingers have not been killed 
#Kill a remaining finger.
func _determine_esp32_message():
#  If all fingers are dead, return immediately
	if killed_fingers.size() >= 5:
		#print("All fingers are dead. Cannot select a new one.")
		return

	var available_fingers: Array[int] = []
	# find alive fingies
	for i in range(10):
		if not killed_fingers.has(i):
			available_fingers.append(i)
	
	#kill a random finger
	var selected_finger = available_fingers.pick_random()
	_kill_finger(selected_finger)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:

		var typed_event = event as InputEventKey
		var key_typed = PackedByteArray([typed_event.unicode]).get_string_from_utf8()
		if active_enemy == null:
			find_new_active_enemy(key_typed)
			return
		var prompt = active_enemy.get_prompt()
		var next_character = prompt.substr(current_letter_index, 1)
		
		#Events for pressing backspace/finger-loss
		if event.keycode == KEY_BACKSPACE:
			if event.is_pressed():
				
				if not backspace_is_held:
					#update fingers
					fingers_remaining -= 1
					fingers_changed.emit(fingers_remaining)
					
					#call kill finger
					if not OS.has_feature("web"):
						_determine_esp32_message()
					
					backspace_is_held = true
					
					#Finger loss vfx
					$"../backspace press".play()
					$"../Hurt/Bleed".modulate.a = 1 #fade is in computer script
					trigger_steam_burst()
					trigger_ice_spike(1.3,0.7)
					$"../Camera2D".trigger_shake()
					$"../Freezing Finger".play()
					finger_lost.emit()
					flash_dropkey_time()
					
				
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
		# some other character
		if typed_event.unicode == 0:
			return
			
		if randf() < (10 - fingers_remaining) * 0.0:
			var special_chars = "!@#$%^&*"
			key_typed = special_chars[randi() % special_chars.length()]
		
		if next_character != " " and randf() < (10 - fingers_remaining) * drop_rate and not SaveManager.time_mode:
			active_enemy.set_next_character(current_letter_index, current_mistakes, true)
			show_warning_message()
			#Sound of faulty key, like fallout one
			$"../Input not registered".play()
			pop_letter_off_screen(current_letter_index)
			terminal_spark()
			dropkey_ready = false
			restart_timer.emit()
			return
			
		if next_character != " " and dropkey_ready and SaveManager.time_mode:
			active_enemy.set_next_character(current_letter_index, current_mistakes, true)
			show_warning_message()
			#Sound of faulty key, like fallout one
			$"../Input not registered".play()
			pop_letter_off_screen(current_letter_index)
			terminal_spark()
			dropkey_ready = false
			restart_timer.emit()
			return

		if active_enemy == null:
			find_new_active_enemy(key_typed)
			return

		#var prompt = active_enemy.get_prompt()
		#var next_character = prompt.substr(current_letter_index, 1)

		if current_mistakes.length() > 0:
			current_mistakes += key_typed
		else:
			if key_typed.to_lower() == next_character.to_lower():
				current_letter_index += 1
				$"../normal press".play()
			else:
				current_mistakes += key_typed
				$"../Wrong Input".play()

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

# BLUETOOTH RELATED THINGIES
# UUIDs from your ESP32 code (Note: BLE plugins often require lowercase UUIDs)
const TARGET_DEVICE_RIGHT = "ESP32S3_GLOVE_R"
const TARGET_DEVICE_LEFT = "ESP32S3_GLOVE_L"
const SERVICE_UUID = "6e400001-b5a3-f393-e0a9-e50e24dcca9e"
const CHAR_UUID_RX = "6e400002-b5a3-f393-e0a9-e50e24dcca9e"
# BluetoothManager
var bluetooth_manager = null
# BleDevice (need to remove typehints otherwise web broke)
var connected_device_r = null
var connected_device_l = null



# --- BLUETOOTH MANAGER CALLBACKS ---
# keep scanning for devices
func _on_adapter_initialized(success: bool, error: String):
	if success:
		print("Bluetooth Adapter Ready! Starting scan...")
		# Start scanning for 15 seconds (need both gloves)
		bluetooth_manager.start_scan(15.0)
	else:
		print("Failed to initialize Bluetooth: ", error)

# connect
func _on_device_discovered(device_info: Dictionary):
	var device_name = device_info.get("name", "Unknown")
	var address = device_info.get("address")

	if device_name == TARGET_DEVICE_RIGHT and connected_device_r == null:
		print("Found RIGHT glove at address: ", address)
		connect_to_esp32(address, "R")
	elif device_name == TARGET_DEVICE_LEFT and connected_device_l == null:
		print("Found LEFT glove at address: ", address)
		connect_to_esp32(address, "L")

	if connected_device_r != null and connected_device_l != null:
		bluetooth_manager.stop_scan()

# eh placeholder function
func _on_scan_stopped():
	if connected_device_r == null:
		print("Scan finished. RIGHT glove not found. Make sure it is powered on and advertising.")
	if connected_device_l == null:
		print("Scan finished. LEFT glove not found. Make sure it is powered on and advertising.")

# --- DEVICE CONNECTION & COMMUNICATION ---

func connect_to_esp32(address: String, hand: String):
	var device = bluetooth_manager.connect_device(address)
	if hand == "R":
		connected_device_r = device
	else:
		connected_device_l = device

	if device:
		device.connect("connected", _on_device_connected.bind(hand))
		device.connect("services_discovered", _on_services_discovered.bind(hand))
		device.connect("characteristic_written", _on_characteristic_written)

		print("Attempting to connect to ", hand, " glove...")
		device.connect_async()

# send start sequence upon start connection
func _on_device_connected(hand: String):
	print("Successfully Connected to ", hand, " glove! Discovering services...")
	var device = connected_device_r if hand == "R" else connected_device_l
	# You must discover services before you can read/write to them
	device.discover_services()

func _on_services_discovered(services: Array, hand: String):
	print("Services discovered on ", hand, " glove. Sending start command...")

	var device = connected_device_r if hand == "R" else connected_device_l
	var data_to_send = "S".to_utf8_buffer()

	# write_characteristic(service_uuid, char_uuid, data, with_response)
	# with_response = false is standard for simple UART streams
	device.write_characteristic(SERVICE_UUID, CHAR_UUID_RX, data_to_send, false)

# 0-4 right (thumb..pinky), 5-9 left (thumb..pinky)
func _kill_finger(finger: int):
	killed_fingers.append(finger)
	if finger < 0 or finger > 9:
		print("Invalid finger index: ", finger)
		return

	var command = str(finger)
	var device = connected_device_r if finger <= 4 else connected_device_l
	var hand_label = "RIGHT" if finger <= 4 else "LEFT"

	var data_to_send = command.to_utf8_buffer()
	if device != null:
		device.write_characteristic(SERVICE_UUID, CHAR_UUID_RX, data_to_send, false)
		print("BLE: Sent kill command '", command, "' to ", hand_label, " glove for finger index: ", finger)
	else:
		print("BLE Error: No connected ", hand_label, " glove to send command to.")

# Reset both gloves to initial servo state (CMD_STOP_ALL = 'X')
func _stop_all_servos() -> void:
	var data_to_send = "X".to_utf8_buffer()
	if connected_device_r != null:
		connected_device_r.write_characteristic(SERVICE_UUID, CHAR_UUID_RX, data_to_send, false)
		print("BLE: Sent STOP_ALL ('X') to RIGHT glove")
	else:
		print("BLE Error: No connected RIGHT glove for STOP_ALL")
	if connected_device_l != null:
		connected_device_l.write_characteristic(SERVICE_UUID, CHAR_UUID_RX, data_to_send, false)
		print("BLE: Sent STOP_ALL ('X') to LEFT glove")
	else:
		print("BLE Error: No connected LEFT glove for STOP_ALL")

func _on_characteristic_written(char_uuid: String):
	print("Data successfully written to characteristic: ", char_uuid)
# Convenient wrapper to free a single finger instantly
func _unrestrict_finger(finger: int) -> void:
	if killed_fingers.has(finger):
		killed_fingers.erase(finger)
	_move_finger_to_angle(finger, 180) # Relaxes completely back to 180 degrees



@export var width = 53.0 
@export var height = 58.0
@export var letter_spawn_offset: Vector2 = Vector2(0, 4)
@export var origin: Vector2
@onready var main_label = $EnemyContainer/Enemy/RichTextLabel

func pop_letter_off_screen(char_index: int) -> void:
	var full_text = $EnemyContainer/Enemy.get_prompt()
	
	# 1. Clean the text string
	var clean_text = main_label.get_parsed_text()
	
	print("\n============= DICTIONARY LAYOUT DEBUG =============")
	print("Raw Text (BBCode): ", full_text)
	print("Clean Text (Visible): ", clean_text)
	print("Target Index Requested: ", char_index)
	
	if char_index < 0 or char_index >= clean_text.length():
		print("❌ ERROR: Index out of bounds!")
		return
		
	var target_char = clean_text[char_index].capitalize()
	print("Target Character: '", target_char, "'")
	
	# 2. Setup your exact dimensions
	var chars_per_line = 23
	var label_width: float = main_label.size.x
	
	# 3. Simulate the Word Wrap
	var words = clean_text.split(" ")
	var rows = []
	var current_line = ""
	
	for word in words:
		if current_line == "":
			current_line = word
		elif current_line.length() + 1 + word.length() <= chars_per_line:
			current_line += " " + word
		else:
			rows.append(current_line)
			current_line = word
	if current_line != "":
		rows.append(current_line)
		
	# --- CONSOLE DEBUG: Print out how our loop built the rows ---
	print("--- Simulated Rows ---")
	for i in range(rows.size()):
		print("Row ", i, " [Length ", rows[i].length(), "]: \"", rows[i], "\"")
		
	# 4. Locate Row and Column
	var target_row = -1
	var target_column = -1
	var accumulated_chars = 0
		
	for r in range(rows.size()):
		var row_text = rows[r]
		if char_index >= accumulated_chars and char_index < accumulated_chars + row_text.length():
			target_row = r
			target_column = char_index - accumulated_chars
			break
		accumulated_chars += row_text.length() + 1
		
	print("--- Target Matrix Location ---")
	print("Calculated Row: ", target_row)
	print("Calculated Column: ", target_column)
	
	if target_row == -1:
		print("❌ ERROR: Failed to find target row! Index fell on a skipped space.")
		return
		
	# 5. Centering and Position Math
	var current_row_text = rows[target_row]
	var row_pixel_width = current_row_text.length() * width
	print(row_pixel_width)
	var centering_offset = (label_width - row_pixel_width) / 2.0
	
	#centering_offset + 
	var local_x = (target_column * width)
	var local_y = target_row * height
	
	#main_label.global_position
	#spawn_world_marker(origin) + Vector2(local_x, local_y)
	var spawn_pos = letter_spawn_offset
	
	print("--- Spatial Math ---")
	print("Label Global Pos: ", main_label.global_position)
	print("Centering Offset for this row: ", centering_offset)
	print("Local X: ", local_x, " | Local Y: ", local_y)
	print("🎯 FINAL TARGET SPAWN POSITION: ", spawn_pos)
	print("===================================================\n")
	
	# 6. VISUAL DEBUGGER: Spawn a flashing target box over the screen coordinates
	var debug_box = ColorRect.new()
	debug_box.size = Vector2(width, height)
	debug_box.color = Color(1.0, 0.0, 0.0, 0.4) # Semi-transparent Red
	debug_box.global_position = spawn_pos
	add_child(debug_box)
	
	# Create a quick tween to make the debug box fade out over 2 seconds
	var tween = create_tween()
	tween.tween_property(debug_box, "modulate:a", 0.0, 2.0)
	tween.tween_callback(debug_box.queue_free)
	
	# 7. Proceed with standard script execution
	
	var flying_letter = Label.new()
	flying_letter.set_script(preload("res://World/Scripts/DroppingLetter.gd"))
	add_child(flying_letter)
	
	flying_letter.modulate = Color(0x9901efff)
	var font = main_label.get_theme_font("font")
	var font_size = main_label.get_theme_font_size("font_size")
	flying_letter.launch(spawn_pos, target_char, font, 70)
	
@onready var steam_particles: GPUParticles2D = $"../SteamCoolant3/SteamParticlesMask/SteamCoolant"
@onready var steam_particles2: GPUParticles2D = $"../SteamCoolant3/SteamParticlesMask/SteamCoolant2"

func trigger_steam_burst() -> void:
	# 1. Start shooting the steam
	steam_particles.emitting = true
	steam_particles2.emitting = true
	await get_tree().create_timer(0.05).timeout
	$"../shooting steam".play()
	# 2. Tell the code to pause right here for exactly 0.2 seconds
	# This creates a lightweight, one-time timer on the fly
	await get_tree().create_timer(0.15).timeout
	
	# 3. Stop spawning new steam particles
	steam_particles.emitting = false
	steam_particles2.emitting = false
	

func trigger_ice_spike(peak_coverage: float, total_duration: float) -> void:
	# 1. Create a fresh, clean tween instance
	await get_tree().create_timer(0.05).timeout
	var tween = create_tween()
	
	# Split our time: 30% to burst out, 70% to melt away
	var build_up_time = total_duration * 0.1
	var melt_down_time = total_duration * 1
	
	# 2. THE EXPLOSION (Rapid Increase)
	# TRANS_CUBIC with EASE_OUT makes the ice snap forward violently at first,
	# decelerating right as it reaches its peak.
	tween.tween_property(
		$"../IceCoverShader2/ColorRect", 
		"material:shader_parameter/coverage", 
		peak_coverage, 
		build_up_time
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# 3. THE MELT (Immediate Decrease)
	# Because this is chained next, it starts the exact microsecond the peak is reached.
	# TRANS_SINE with EASE_IN makes the ice pull back smoothly and progressively faster.
	tween.tween_property(
		$"../IceCoverShader2/ColorRect", 
		"material:shader_parameter/coverage", 
		0.0, # Return to completely clear screen
		melt_down_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
@onready var popup1 = $"../Slider"
func open_popup1():
	popup1.visible = true
	get_tree().paused = true
	
	
@onready var popup2 = $"../TwisterFingers"
func open_popup2():
	popup2.visible = true
	get_tree().paused = true
	

@onready var sparks_sound = $"../TerminalMalfunction/AudioStreamPlayer"
@onready var sparks = $"../TerminalMalfunction/GPUParticles2D"
@onready var sparks3 = $"../TerminalMalfunction/GPUParticles2D3"
func terminal_spark():
	sparks.emitting = true

	sparks3.emitting = true
	sparks_sound.play()
	await get_tree().create_timer(0.3).timeout
	sparks.emitting = false

	sparks3.emitting = false
	


func _on_drop_key_timer_timeout() -> void:
	dropkey_ready = true

const flashes = 3
func flash_dropkey_time():
	var tween = create_tween().set_loops(flashes)
	
	# Instantly switch to Red, wait 0.2 seconds
	tween.tween_callback(func(): $"../DropKeyTimer/RichTextLabel".modulate = Color.RED)
	tween.tween_interval(0.2)
	
	# Instantly switch to White, wait 0.2 seconds
	tween.tween_callback(func(): $"../DropKeyTimer/RichTextLabel".modulate = Color(0.761, 0.65, 1.0, 1.0))
	tween.tween_interval(0.2)
