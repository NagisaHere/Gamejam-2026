extends VideoStreamPlayer


func play_video(file_path: String) -> void:
	self.show_behind_parent = false
	
	var stream_resource = load(file_path)
	if stream_resource:
		self.stream = stream_resource
		self.loop = true
		self.expand = true
		self.anchors_preset = Control.PRESET_FULL_RECT
		#self.size = Vector2(1280, 720)
		self.play()
		
func stop_video() -> void:
	self.stop()
