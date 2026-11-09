extends Node

## Autoload: progress that outlives a single screen (and a single run).

const SAVE_PATH := "user://progress.json"

var cleared := 0


func _ready() -> void:
	load_progress()


func save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({"cleared": cleared}))


func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		cleared = int(parsed.get("cleared", 0))
