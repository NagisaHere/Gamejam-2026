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
	#start_game()
	# set time and level count from settings
	sentences_to_win = SaveManager.sentences_needed
	$"../Timer".wait_time = SaveManager.time_limit
	
	randomize()
	load_phrases()
	spawn_phrase()

func _win_game() -> void:
	SaveManager.temp_time = $"../Timer".time_left
	SaveManager.temp_score = fingers_remaining

	# 2. Change to the popup scene
	# This current scene (and this script) will now be destroyed
	get_tree().change_scene_to_file("res://popup.tscn")

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
	if (not passphrases.is_empty()): # last is empty string, not good practice but filter doesnt work idk
		passphrases.remove_at(passphrases.size() - 1)
	
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
	$"../Death/DeathGlow".modulate.a = 20 #fade is in computer
	$"../Fadeout/Fade Transition".show()
	$"../Fadeout/Fade Transition/Fade_Timer".start()
	$"../Fadeout/Fade Transition/AnimationPlayer".play("Fade_out")
	

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
		return

	var available_fingers: Array[int] = []
	# find alive fingies
	for i in range(10):
		if not killed_fingers.has(i):
			available_fingers.append(i)

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
		if event.keycode == KEY_BACKSPACE:
			if event.is_pressed():
				
				if not backspace_is_held:
					fingers_remaining -= 1
					fingers_changed.emit(fingers_remaining)
					if not OS.has_feature("web"):
						_determine_esp32_message()
					backspace_is_held = true
					$"../backspace press".play()
					$"../Hurt/Bleed".modulate.a = 1 #fade is in computer script
					
					
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
		
		if next_character != " " and randf() < (10 - fingers_remaining) * 0.025:
			active_enemy.set_next_character(current_letter_index, current_mistakes, true)
			show_warning_message()
			#Sound of faulty key, like fallout one
			$"../Input not registered".play()
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

func _on_characteristic_written(char_uuid: String):
	print("Data successfully written to characteristic: ", char_uuid)
