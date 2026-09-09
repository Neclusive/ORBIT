extends Node

const SETTINGS_PATH := "user://settings.cfg"

var stars_enabled: bool = true
var trail_enabled: bool = true
var path_enabled: bool = true
var music_enabled: bool = true


func _ready() -> void:
	load_settings()


func load_settings() -> void:
	var config := ConfigFile.new()

	if config.load(SETTINGS_PATH) != OK:
		print("No settings file found yet")
		return

	stars_enabled = config.get_value("effects", "stars_enabled", true)
	trail_enabled = config.get_value("effects", "trail_enabled", true)
	path_enabled = config.get_value("effects", "path_enabled", true)
	music_enabled = config.get_value("effects", "music_enabled", true)


func save_settings() -> void:
	var config := ConfigFile.new()

	config.set_value("effects", "stars_enabled", stars_enabled)
	config.set_value("effects", "trail_enabled", trail_enabled)
	config.set_value("effects", "path_enabled", path_enabled)
	config.set_value("effects", "music_enabled", music_enabled)

	var error := config.save(SETTINGS_PATH)
	print("Save result: ", error)
