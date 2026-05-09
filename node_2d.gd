extends Node2D

@export var next_scene := "res://World/Scenes/computer.tscn"

var player_inside := false

func _ready():
	$Label.visible = false
	$Area2D.body_entered.connect(_on_body_entered)
	$Area2D.body_exited.connect(_on_body_exited)

func _process(delta):
	if player_inside and Input.is_action_just_pressed("interact"):
		get_tree().change_scene_to_file(next_scene)

func _on_body_entered(body):
	if body.name == "Player":
		player_inside = true
		$Label.visible = true

func _on_body_exited(body):
	if body.name == "Player":
		player_inside = false
		$Label.visible = false
