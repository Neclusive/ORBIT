extends AudioStreamPlayer

func _ready() -> void:
	if Settings.music_enabled: play()
