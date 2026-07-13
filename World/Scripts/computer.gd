extends Node2D

@onready var time_label = $CanvasTimer/Label
@onready var redGlow = $"alarm overlay/RedGlow"
@onready var previous_second: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$TypingHand.show_typing_state(0)
	$typing.fingers_changed.connect($CanvasLayer.set_fingers_remaining)
	$Timer.start()
	redGlow.modulate.a = 0.0
	$Death/DeathGlow.modulate.a = 0.0
	$Hurt/Bleed.modulate.a = 0.0
	previous_second = int($Timer.time_left)
	freeze_screen(10)
	


func _process(delta):
	var seconds = int($Timer.time_left)
	var time_left = $Timer.time_left
	time_label.text = "%02d:%02d" % [seconds / 60, seconds % 60]
	if seconds != previous_second:
		previous_second = seconds
		if seconds == 0:
			time_label.modulate = Color.RED
			$alarm.pitch_scale = 0.5
			$alarm.play()
			var tween = create_tween()
			tween.tween_property($alarm, "volume_db", -80, 2.5)
			tween.tween_callback($alarm.stop)
		elif ((seconds/60 == 0) and (seconds%60 <= 10)) or seconds%60 == 0:
			time_label.modulate = Color.RED
			redGlow.modulate.a = 0.8
			$alarm.play()
				
	if fmod(time_left, 1.0) < 0.5 and time_label.modulate == Color.RED:
		time_label.modulate = Color.WHITE
	
	#fades for red effects
	redGlow.modulate.a = lerp(redGlow.modulate.a, 0.0, delta * 1.0)
	$Death/DeathGlow.modulate.a = lerp($Death/DeathGlow.modulate.a, 0.0, delta * 1.0)
	$Hurt/Bleed.modulate.a = lerp($Hurt/Bleed.modulate.a, 0.0, delta * 1.0)


func _on_timer_timeout() -> void:
	#time has runout, all fingers frozen effect
	$typing.kill_left()
	$typing.kill_right()
	#add ice cracking sound of all fingers freezing over
	
	$typing._game_over()
	


func _on_startup_finished() -> void:
	$"computer ambience".play()


func _on_computer_ambience_finished() -> void:
	$"computer ambience".play()
	
func freeze_screen(duration: float) -> void:
	var tween = create_tween()
	
	var total_steps: int = 8 # How many distinct "cracking bursts" you want
	var time_per_step: float = duration / total_steps
	var target_max_coverage: float = 1.4
	
	for i in range(total_steps):
		# 1. Calculate a base coverage milestone for this step
		var next_coverage = lerp(0.0, target_max_coverage, float(i + 1) / total_steps)
		
		# 2. Add a little organic randomness so the jumps aren't perfectly uniform
		if i < total_steps - 1:
			next_coverage += randf_range(-0.15, 0.15)
		
		# 3. STUTTER: Make the tween hold still for 75% of the step duration
		tween.tween_interval(time_per_step * 0.75)
		
		# 4. BURST: Force the coverage to jump forward rapidly during the remaining 25%
		tween.tween_property(
			$IceCoverShader/ColorRect, 
			"material:shader_parameter/coverage", 
			next_coverage, 
			time_per_step * 0.25
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
