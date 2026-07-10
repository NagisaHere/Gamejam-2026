extends CanvasLayer

func play_video(file_path: String) -> void:
	var stream_resource = load(file_path)
	if stream_resource:
		$VideoStreamPlayer.stream = stream_resource
		$VideoStreamPlayer.loop = true
		$VideoStreamPlayer.expand = true
		$VideoStreamPlayer.anchors_preset = Control.PRESET_FULL_RECT
		$VideoStreamPlayer.play()
		
func stop_video() -> void:
	$VideoStreamPlayer.stop()
