extends Node2D

func _ready():
	$Player.cutscene_mode = true
	
	#$Player/AnimatedSprite2D.play("down")
	$AnimationPlayer.play("Intro")
	$Rope.play()
	await $AnimationPlayer.animation_finished
	$"Thretening ambience".play()

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "Intro":
		$AnimationPlayer.play("IntroCam")
		#$Player/AnimatedSprite2D.play("idle")
		$Player/AnimatedSprite2D.play("down")
		

	elif anim_name == "IntroCam":
		$Player.cutscene_mode = false
		$Camera2D.global_position = $Player.global_position
		$Camera2D.following = true
