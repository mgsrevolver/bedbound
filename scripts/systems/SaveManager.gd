class_name SaveManager
extends Node

const SAVE_PATH = "user://savegame.dat"
const SAVE_VERSION = 1

signal save_completed
signal load_completed
signal save_failed(error: String)
signal load_failed(error: String)

func save_game(data: Dictionary) -> bool:
	var save_file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)

	if not save_file:
		var error = "Failed to open save file for writing"
		save_failed.emit(error)
		push_error(error)
		return false

	var save_data = {
		"version": SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"data": data
	}

	save_file.store_var(save_data)
	save_file.close()

	save_completed.emit()
	return true

func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		load_failed.emit("Save file does not exist")
		return {}

	var save_file = FileAccess.open(SAVE_PATH, FileAccess.READ)

	if not save_file:
		var error = "Failed to open save file for reading"
		load_failed.emit(error)
		push_error(error)
		return {}

	var save_data = save_file.get_var()
	save_file.close()

	if not validate_save_data(save_data):
		load_failed.emit("Invalid save data format")
		return {}

	if save_data.version != SAVE_VERSION:
		save_data = migrate_save_data(save_data)

	load_completed.emit()
	return save_data.data

func validate_save_data(data: Variant) -> bool:
	if not data is Dictionary:
		return false

	if not "version" in data:
		return false

	if not "data" in data:
		return false

	return true

func migrate_save_data(old_data: Dictionary) -> Dictionary:
	print("SaveManager: Migrating save data from version %d to %d" % [old_data.version, SAVE_VERSION])
	return old_data

func save_exists() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> bool:
	if not save_exists():
		return false

	var dir = DirAccess.open("user://")
	return dir.remove(SAVE_PATH) == OK

func get_save_info() -> Dictionary:
	if not save_exists():
		return {}

	var save_file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not save_file:
		return {}

	var save_data = save_file.get_var()
	save_file.close()

	if not validate_save_data(save_data):
		return {}

	return {
		"version": save_data.version,
		"timestamp": save_data.get("timestamp", 0),
		"date": Time.get_datetime_string_from_unix_time(save_data.get("timestamp", 0))
	}

func autosave(data: Dictionary):
	var autosave_path = "user://autosave.dat"
	var save_file = FileAccess.open(autosave_path, FileAccess.WRITE)

	if save_file:
		var save_data = {
			"version": SAVE_VERSION,
			"timestamp": Time.get_unix_time_from_system(),
			"data": data,
			"is_autosave": true
		}
		save_file.store_var(save_data)
		save_file.close()