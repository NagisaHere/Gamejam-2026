
extends Label

var velocity: Vector2 = Vector2.ZERO
var gravity: float = 1200.0 # Adjust to make it fall faster/slower

func launch(start_position: Vector2, char_text: String, font_override: Font, size_override: int) -> void:
	# 1. Match the exact appearance of the original text
	text = char_text
	global_position = start_position
	add_theme_font_override("font", font_override)
	add_theme_font_size_override("font_size", size_override)
	
	# 2. Give it an initial upward and outward blast (The Jump)
	# Random X velocity makes it fly slightly left or right
	velocity = Vector2(50, -500)

func _process(delta: float) -> void:
	# 3. Apply gravity to the velocity over time
	velocity.y += gravity * delta
	
	# 4. Move the letter
	global_position += velocity * delta
	
	# 5. Self-destruct once it completely clears the bottom of the screen
	var screen_height = get_viewport().get_visible_rect().size.y
	if global_position.y > screen_height + 50:
		queue_free()
