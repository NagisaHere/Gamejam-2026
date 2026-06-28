extends VideoStreamPlayer

@onready var player: VideoStreamPlayer = get_tree().get_first_node_in_group("global_video_player")

# Called when the node enters the scene tree for the first time.
func play_video(file_path: String) -> void:
	if player:
		var stream_resource = load(file_path)
		player.stream = stream_resource
		player.play()
		
func stop_video() -> void:
	if player:
		player.stop()
