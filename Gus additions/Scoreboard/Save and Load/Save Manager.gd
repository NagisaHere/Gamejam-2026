extends Node

# its okay I swear we have RLS
const SUPABASE_URL = "https://lblxjnhvnycjsroywrbq.supabase.co"
const SUPABASE_KEY = "sb_publishable_xStcRVKY3hzkQPrfEhOoig_IfYhZxCH"

@onready var save_http_request: HTTPRequest = HTTPRequest.new()
@onready var load_http_request: HTTPRequest = HTTPRequest.new()

const SAVE_PATH := "user://save_data.tres"
var current_save: SaveData
var temp_time: float = 0.0
var temp_score: int = 0

func _ready():

	
	save_http_request.request_completed.connect(_on_request_completed)
	load_http_request.request_completed.connect(_on_load_completed)

	add_child(save_http_request)
	add_child(load_http_request)
	#load_data()
	load_data_from_supabase()

func save_data():
	ResourceSaver.save(current_save, SAVE_PATH)

# saves a single entry
func save_data_supabase(data: Dictionary):
	var url = SUPABASE_URL + "/rest/v1/saves"
	var headers = [
		"apikey: " + SUPABASE_KEY,
		"Authorization: Bearer " + SUPABASE_KEY,
		"Content-Type: application/json",
		"Prefer: resolution=merge-duplicates"
	]
	var body = JSON.stringify(data)

	print("Sending data to supabase")
	save_http_request.request(url, headers, HTTPClient.METHOD_POST, body)

# This function runs automatically when Supabase replies
func _on_request_completed(result, response_code, headers, body):
	if response_code >= 200 and response_code < 300:
		print("Successfully saved to cloud!")
	else:
		print("Failed to save. HTTP Code: ", response_code)
		var error_message = body.get_string_from_utf8()
		print("Supabase Error: ", error_message)

func load_data():
	if ResourceLoader.exists(SAVE_PATH):
		current_save = ResourceLoader.load(SAVE_PATH)
	else:
		current_save = SaveData.new()
		current_save.test_data = [{"name": "no-one","time": 40, "score": 1000}]
		save_data()

func load_data_from_supabase():
	var url = SUPABASE_URL + "/rest/v1/saves"
	
	var headers = [
		"apikey: " + SUPABASE_KEY,
		"Authorization: Bearer " + SUPABASE_KEY,
		"Content-Type: application/json",
	]
	
	load_http_request.request(url, headers, HTTPClient.METHOD_GET, "")

func _on_load_completed(result, response_code, headers, body):
	if response_code >= 200 and response_code < 300:
		var json_string = body.get_string_from_utf8()
		var data = JSON.parse_string(json_string)
		if (current_save == null):
			current_save = SaveData.new()
		if (data != null and typeof(data) == TYPE_ARRAY):
			current_save.test_data = data
			print("wow supa data")
		else:
			current_save.test_data = []
		# yeah this is bad lmao
		# Check if we actually got any data back
		save_data()
	else:
		print("Failed to load. HTTP Code: ", response_code)
		print("Error: ", body.get_string_from_utf8())
