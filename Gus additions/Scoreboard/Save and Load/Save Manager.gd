extends Node

const SAVE_PATH := "user://save_data.tres"
var current_save: SaveData
var temp_time: float = 0.0
var temp_score: int = 0

func _ready():
	load_data()
	
func save_data():
	ResourceSaver.save(current_save, SAVE_PATH)

func load_data():
	if ResourceLoader.exists(SAVE_PATH):
		current_save = ResourceLoader.load(SAVE_PATH)
	else:
		current_save = SaveData.new()
		current_save.test_data = [{"name": "no-one","time": 40, "score": 1000}]
		save_data()
