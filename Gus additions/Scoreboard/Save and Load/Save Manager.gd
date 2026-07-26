extends Node

const SAVE_PATH := "user://save_data.tres"
var current_save: SaveData
var temp_time: float = 0.0
var temp_score: int = 0

var time_limit: float = 120.0
var sentences_needed: int = 3
var BongoCat = false
var playIntro = true
var difficulty = "easy"
var dropkey_level: float = 2.5
var time_mode = true

func _ready():
	load_data()
	
func save_data():
	ResourceSaver.save(current_save, SAVE_PATH)

func load_data():
	if ResourceLoader.exists(SAVE_PATH):
		current_save = ResourceLoader.load(SAVE_PATH)
	else:
		current_save = SaveData.new()
		current_save.test_data = [{"name": "no-one","time": 40, "score": 0,
		 "levels": 0, "time_limit": 0.0}]
		save_data()
