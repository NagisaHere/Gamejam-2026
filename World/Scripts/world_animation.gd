extends Node2D

func _ready():
	$AnimationPlayer.play("Intro")
	$Rope.play()
	await $AnimationPlayer.animation_finished
	$"Thretening ambience".play()

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "Intro":
		$AnimationPlayer.play("IntroCam")
		

	elif anim_name == "IntroCam":
		$Player.cutscene_mode = false
		$Camera2D.global_position = $Player.global_position
		$Camera2D.following = true
