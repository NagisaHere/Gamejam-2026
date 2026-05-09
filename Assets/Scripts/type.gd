extends Node2D

signal fingers_changed(value)
var active_enemy = null
var current_letter_index: int = -1 # undefined
var fingers_remaining: int = 10 
var prev_keycode: int = -1 # undefined for now
@onready var enemy_container = $EnemyContainer
@onready var fingers_label = $"CanvasLayer/VBoxContainer/BottomRow/fingers-value"
var current_mistakes: String = ""
var killed_fingers: Array[int] = []

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

# determine what fingers have not been killed
func _determine_esp32_message():
# 1. If all fingers are dead, return immediately
	if killed_fingers.size() >= 5:
		print("All fingers are dead. Cannot select a new one.")
		return

	# 2. Create a temporary list of ONLY the alive fingers
	var available_fingers: Array[int] = []

	for i in range(5):
		if not killed_fingers.has(i):
			available_fingers.append(i)

	# 3. Tell Godot to pick a random finger from the available ones
	# .pick_random() is a built-in Godot 4 array function
	var selected_finger = available_fingers.pick_random()
	_kill_finger(selected_finger)

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
				fingers_changed.emit(fingers_remaining)
				_determine_esp32_message()
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

# BLUETOOTH RELATED THINGIES
# UUIDs from your ESP32 code (Note: BLE plugins often require lowercase UUIDs)
const TARGET_DEVICE_NAME = "ESP32S3_BLE_UART"
const SERVICE_UUID = "6e400001-b5a3-f393-e0a9-e50e24dcca9e"
const CHAR_UUID_RX = "6e400002-b5a3-f393-e0a9-e50e24dcca9e"

var bluetooth_manager: BluetoothManager
var connected_device: BleDevice = null

func _ready():
	# 1. Instantiate the BluetoothManager and add it to the scene tree
	bluetooth_manager = BluetoothManager.new()
	add_child(bluetooth_manager)
	
	# 2. Connect core manager signals
	bluetooth_manager.adapter_initialized.connect(_on_adapter_initialized)
	bluetooth_manager.device_discovered.connect(_on_device_discovered)
	bluetooth_manager.scan_stopped.connect(_on_scan_stopped)
	
	# 3. Initialize directly (Desktop needs no special permissions)
	bluetooth_manager.initialize()

# --- BLUETOOTH MANAGER CALLBACKS ---

func _on_adapter_initialized(success: bool, error: String):
	if success:
		print("Bluetooth Adapter Ready! Starting scan...")
		# Start scanning for 10 seconds
		bluetooth_manager.start_scan(10.0)
	else:
		print("Failed to initialize Bluetooth: ", error)

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

	# GDScript uses 'match' instead of 'switch'
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
	# Assuming connected_device, SERVICE_UUID, and CHAR_UUID_RX are in class scope
	if connected_device != null:
		connected_device.write_characteristic(SERVICE_UUID, CHAR_UUID_RX, data_to_send, false)
		print("BLE: Sent kill command '", command, "' for finger index: ", finger)
	else:
		print("BLE Error: No connected device to send command to.")

func _on_characteristic_written(char_uuid: String):
	print("Data successfully written to characteristic: ", char_uuid)
	# Optional: Disconnect after sending if you only need a single burst
	# connected_device.disconnect()
