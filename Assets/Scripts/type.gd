extends Node2D

signal fingers_changed(value)
var passphrases = []
var active_enemy = null
var current_letter_index: int = -1 # undefined
var fingers_remaining: int = 10 
var prev_keycode: int = -1 # undefined for now
var backspace_is_held := false
var sentences_completed := 0
var sentences_to_win := 1
@onready var enemy = $EnemyContainer/Enemy
@onready var enemy_container = $EnemyContainer
@onready var fingers_label = $"CanvasLayer/VBoxContainer/BottomRow/fingers-value"
@onready var warning_label = $Label
var current_mistakes: String = ""
var killed_fingers: Array[int] = []

func _ready() -> void:
	# 1. Instantiate the BluetoothManager and add it to the scene tree
	bluetooth_manager = BluetoothManager.new()
	add_child(bluetooth_manager)
	
	# 2. Connect core manager signals
	bluetooth_manager.adapter_initialized.connect(_on_adapter_initialized)
	bluetooth_manager.device_discovered.connect(_on_device_discovered)
	bluetooth_manager.scan_stopped.connect(_on_scan_stopped)
	
	bluetooth_manager.initialize()
	#start_game()
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
	warning_label.text = "Key Stroke Dropped"
	warning_label.visible = true

	await get_tree().create_timer(0.8).timeout

	warning_label.visible = false

# determine what fingers have not been killed
func _determine_esp32_message():
#  If all fingers are dead, return immediately
	if killed_fingers.size() >= 5:
		print("All fingers are dead. Cannot select a new one.")
		return

	var available_fingers: Array[int] = []
	# find alive fingies
	for i in range(5):
		if not killed_fingers.has(i):
			available_fingers.append(i)

	var selected_finger = available_fingers.pick_random()
	_kill_finger(selected_finger)

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
					_determine_esp32_message()
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

# BLUETOOTH RELATED THINGIES
# UUIDs from your ESP32 code (Note: BLE plugins often require lowercase UUIDs)
const TARGET_DEVICE_NAME = "ESP32S3_BLE_UART"
const SERVICE_UUID = "6e400001-b5a3-f393-e0a9-e50e24dcca9e"
const CHAR_UUID_RX = "6e400002-b5a3-f393-e0a9-e50e24dcca9e"

var bluetooth_manager: BluetoothManager
var connected_device: BleDevice = null



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
		connected_device.connected.connect(_on_device_connected)
		connected_device.services_discovered.connect(_on_services_discovered)
		connected_device.characteristic_written.connect(_on_characteristic_written)
		
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
func _kill_finger(finger: int):
	killed_fingers.append(finger)
	var command: String = ""

	match finger:
		0: # Thumb
			command = "0"
		1: # Index
			command = "1"
		2: # Middle
			command = "2"
		3: # Ring
			command = "3"
		4: # Pinky
			command = "4"
		_: # Default catch-all
			print("Invalid finger index")
			return
	# Convert the matched string command to a byte array
	var data_to_send = command.to_utf8_buffer()
	if connected_device != null:
		connected_device.write_characteristic(SERVICE_UUID, CHAR_UUID_RX, data_to_send, false)
		print("BLE: Sent kill command '", command, "' for finger index: ", finger)
	else:
		print("BLE Error: No connected device to send command to.")

func _on_characteristic_written(char_uuid: String):
	print("Data successfully written to characteristic: ", char_uuid)
	# Optional: Disconnect after sending if you only need a single burst
	# connected_device.disconnect()
