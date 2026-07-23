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
@export var drop_rate = 0.025

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
			match (sentences_completed):
				1:
					open_popup1()
				2:
					open_popup2()
			
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
	#Death time effects
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
#Kill a remaining finger.
func _determine_esp32_message():
#  If all fingers are dead, return immediately
	if killed_fingers.size() >= 5:
		#print("All fingers are dead. Cannot select a new one.")
		return

	var available_fingers: Array[int] = []
	# find alive fingies
	for i in range(5):
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
		
		if next_character != " " and randf() < (10 - fingers_remaining) * drop_rate:
			active_enemy.set_next_character(current_letter_index, current_mistakes, true)
			show_warning_message()
			#Sound of faulty key, like fallout one
			$"../Input not registered".play()
			pop_letter_off_screen(current_letter_index)
			terminal_spark()
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
const TARGET_DEVICE_NAME = "ESP32S3_BLE_UART"
const SERVICE_UUID = "6e400001-b5a3-f393-e0a9-e50e24dcca9e"
const CHAR_UUID_RX = "6e400002-b5a3-f393-e0a9-e50e24dcca9e"
# BluetoothManager
var bluetooth_manager = null
# BleDevice (need to remove typehints otherwise web broke)
var connected_device = null



# --- BLUETOOTH MANAGER CALLBACKS ---
# keep scanning for devices
func _on_adapter_initialized(success: bool, error: String):
	if success:
		print("Bluetooth Adapter Ready! Starting scan...")
		# Start scanning for 10 seconds
		bluetooth_manager.start_scan(10.0)
	else:
		print("Failed to initialize Bluetooth: ", error)

# connect
func _on_device_discovered(device_info: Dictionary):
	var device_name = device_info.get("name", "Unknown")
	
	# Check if we found our ESP32
	if device_name == TARGET_DEVICE_NAME:
		var address = device_info.get("address")
		print("Found ESP32 at address: ", address)
		
		# Stop scanning immediately to save resources
		bluetooth_manager.stop_scan()
		
		# Proceed to connection
		connect_to_esp32(address)

# eh placeholder function
func _on_scan_stopped():
	if connected_device == null:
		print("Scan finished. ESP32 not found. Make sure it is powered on and advertising.")

# --- DEVICE CONNECTION & COMMUNICATION ---

func connect_to_esp32(address: String):
	# Fetch the specific BleDevice object
	connected_device = bluetooth_manager.connect_device(address)
	
	if connected_device:
		# Wire up the device-specific signals
		connected_device.connect("connected", _on_device_connected)
		connected_device.connect("services_discovered", _on_services_discovered)
		connected_device.connect("characteristic_written", _on_characteristic_written)
		
		print("Attempting to connect...")
		connected_device.connect_async()

# send start sequence upon start connection
func _on_device_connected():
	print("Successfully Connected to ESP32! Discovering services...")
	# You must discover services before you can read/write to them
	connected_device.discover_services()

func _on_services_discovered(services: Array):
	print("Services discovered. Sending Servo command...")
	
	# Send the '1' command (convert string to PackedByteArray/utf8 buffer)
	var data_to_send = "S".to_utf8_buffer()
	
	# write_characteristic(service_uuid, char_uuid, data, with_response)
	# with_response = false is standard for simple UART streams
	connected_device.write_characteristic(SERVICE_UUID, CHAR_UUID_RX, data_to_send, false)

# 0 for thumb, 1 for index, 2 for middle, 3 for ring, 4 for pinky
func _kill_finger(finger: int) -> void:
	if finger > 9 or finger < 0:
		return
		
	if not killed_fingers.has(finger):
		killed_fingers.append(finger)
	_move_finger_to_angle(finger, 0) # Pulls down to 0 degrees
	

func _on_characteristic_written(char_uuid: String):
	print("Data successfully written to characteristic: ", char_uuid)
	# Optional: Disconnect after sending if you only need a single burst
	# connected_device.disconnect()

func _move_finger_to_angle(finger: int, target_angle: int) -> void:
	# Ensure the angle stays within your hardware's 0-180 limits
	var safe_angle = clamp(target_angle, 0, 180)
	
	# Build the parsed string (e.g., "1:180")
	var command: String = str(finger) + ":" + str(safe_angle)
	var data_to_send = command.to_utf8_buffer()
	
	if connected_device != null:
		connected_device.write_characteristic(SERVICE_UUID, CHAR_UUID_RX, data_to_send, false)
		print("BLE: Sent Target Command -> ", command)
	else:
		print("BLE Error: No connected device to send command to.")

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
	
