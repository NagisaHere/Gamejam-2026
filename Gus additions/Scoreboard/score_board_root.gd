extends Node2D

@export var row_scene: PackedScene
@onready var list_container = $Panel/ScrollContainer/VBoxContainer
var data = SaveData.new()

func _ready() -> void:
	if SaveManager.current_save:
		var data_to_display = SaveManager.current_save.test_data
		create_scoreboard(data_to_display)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func create_scoreboard(data):
	for entry in data:
		var new_row = row_scene.instantiate()
		list_container.add_child(new_row)
		new_row.setup(entry["name"], entry["time"], str(entry["score"]))
