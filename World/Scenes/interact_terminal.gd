extends Area2D

@export var next_scene := "res://World/Scenes/computer.tscn"

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "Player":
		print("HIIII getting here")
		get_tree().change_scene_to_file(next_scene)
