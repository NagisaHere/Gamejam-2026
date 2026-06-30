extends VideoStreamPlayer

# Called when the node enters the scene tree for the first time.
func play_video(file_path: String) -> void:
	var stream_resource = load(file_path)
	if stream_resource:
		self.stream = stream_resource
		self.loop = true
		self.expand = true
		self.anchors_preset = Control.PRESET_FULL_RECT
		self.play()
		
func stop_video() -> void:
	self.stop()
