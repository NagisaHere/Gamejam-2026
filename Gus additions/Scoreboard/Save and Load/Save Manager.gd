extends Node

const SAVE_PATH := "user://save_data.tres"
var current_save: SaveData

func _ready():
	load_data()
	
func save_data():
	ResourceSaver.save(current_save, SAVE_PATH)

func load_data():
	if ResourceLoader.exists(SAVE_PATH):
		current_save = ResourceLoader.load(SAVE_PATH)
	else:
		current_save = SaveData.new()
		current_save.test_data = [{"name": "Subject_02","time": "00:00", "score": 100}]
		save_data()
