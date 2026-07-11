extends CanvasLayer

@export var target_node: Node2D   # Drag your quest objective here
@export var player_node: Node2D   # Drag your player here (for distance tracking)
@export var margin: float = 40.0  # Pixels away from the screen edge to stay clamped

@onready var icon = $Sprite2D
@onready var distance_label: Label = $Label

func _process(_delta: float) -> void:
	# Safety check to ensure nodes haven't been deleted
	if not is_instance_valid(target_node):
		icon.visible = false
		return
		
	# 1. Get the target's raw position on the player's screen canvas
	var screen_pos: Vector2 = target_node.get_global_transform_with_canvas().origin
	
	# Get the current window size of the game
	var screen_size: Vector2 = get_viewport().get_visible_rect().size
	
	# 2. Check if the target is physically outside the player's screen view
	var is_off_screen: bool = (
		screen_pos.x < 0 or 
		screen_pos.x > screen_size.x or 
		screen_pos.y < 0 or 
		screen_pos.y > screen_size.y
	)
	
	# 3. Clamp the icon to the screen edges if it goes off-screen
	var clamped_x = clamp(screen_pos.x, margin, screen_size.x - margin)
	var clamped_y = clamp(screen_pos.y, margin, screen_size.y - margin)
	
	# 4. Apply the position (offsetting by half the icon size so it stays perfectly centered)
	icon.position = Vector2(clamped_x, clamped_y)
	icon.visible = true
	
	# 5. Optional: Rotate an arrow indicator to point toward the target when off-screen
	if is_off_screen:
		var direction: Vector2 = (target_node.global_position - player_node.global_position).normalized()
		icon.rotation = direction.angle()
	else:
		icon.rotation = 0 # Face upright when looking right at it
		
	# 6. Optional: Update distance text
	if is_instance_valid(player_node):
		var distance: float = player_node.global_position.distance_to(target_node.global_position)
		# Convert pixels to game "meters" (e.g., assuming 32 pixels = 1 meter)
		var meters = round(distance / 32.0) 
		distance_label.text = str(meters) + "m"
		distance_label.position = icon.position - (distance_label.size / 2.0)
		distance_label.visible = icon.visible
