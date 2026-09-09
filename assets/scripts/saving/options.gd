extends Node2D

@onready var stars_button: Button = $stars_button
@onready var trail_button: Button = $trail_button
@onready var path_button: Button = $path_button
@onready var music_button: Button = $music_button


func _ready() -> void:
	# Restore the saved button states.
	stars_button.button_pressed = Settings.stars_enabled
	trail_button.button_pressed = Settings.trail_enabled
	path_button.button_pressed = Settings.path_enabled
	music_button.button_pressed = Settings.music_enabled

	# Connect each button to its toggle function.
	stars_button.toggled.connect(_on_stars_toggled)
	trail_button.toggled.connect(_on_trail_toggled)
	path_button.toggled.connect(_on_path_toggled)
	music_button.toggled.connect(_on_music_toggled)


func _on_stars_toggled(enabled: bool) -> void:
	Settings.stars_enabled = enabled
	Settings.save_settings()


func _on_trail_toggled(enabled: bool) -> void:
	Settings.trail_enabled = enabled
	Settings.save_settings()


func _on_path_toggled(enabled: bool) -> void:
	Settings.path_enabled = enabled
	Settings.save_settings()
	
func _on_music_toggled(enabled: bool) -> void:
	Settings.music_enabled = enabled
	Settings.save_settings()
