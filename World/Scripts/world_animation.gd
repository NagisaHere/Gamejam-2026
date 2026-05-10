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


func _on_button_pressed() -> void:
	$tutorial.play()
	$CanvasLayer/Button.hide()
	$CanvasLayer/Button2.show()
	


func _on_button_2_pressed() -> void:
	$tutorial.stop()
	$CanvasLayer/Button.show()
	$CanvasLayer/Button2.hide()
