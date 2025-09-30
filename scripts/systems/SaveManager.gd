class_name SaveManager
extends Node

const SAVE_PATH = "user://savegame.dat"
const SAVE_VERSION = 2  # Updated for NPC relationship tracking

signal save_completed
signal load_completed
signal save_failed(error: String)
signal load_failed(error: String)

# Track comprehensive NPC states
var npc_relationships: Dictionary = {}  # NPC name -> relationship data
var conversation_history: Array[Dictionary] = []  # Full conversation log
var global_flags: Dictionary = {}  # Story progression flags

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

# === NPC Relationship System ===

func init_npc_relationship(npc_name: String):
	"""Initialize tracking for a new NPC"""
	if npc_relationships.has(npc_name):
		return

	npc_relationships[npc_name] = {
		"trust_level": 0,
		"conversation_level": 1,
		"level_2_choice": "",
		"level_3_used_options": [],
		"conversation_count": 0,
		"last_interaction": 0,
		"breakthroughs": [],
		"emotional_beats": [],
		"topics_discussed": [],
		"player_choices": [],  # History of all choices made
		"exhausted": false
	}

func update_npc_state(npc_name: String, npc: NPC):
	"""Save current NPC state"""
	if not npc_relationships.has(npc_name):
		init_npc_relationship(npc_name)

	var state = npc_relationships[npc_name]
	state.trust_level = npc.trust_level
	state.conversation_level = npc.conversation_level
	state.level_2_choice = npc.level_2_choice
	state.level_3_used_options = npc.level_3_used_options.duplicate()
	state.conversation_exhausted = npc.conversation_exhausted
	state.last_interaction = Time.get_unix_time_from_system()
	state.emotional_beats = npc.emotional_state.beats_hit.duplicate()

	# Track conversation count
	state.conversation_count += 1

func restore_npc_state(npc_name: String, npc: NPC):
	"""Restore saved NPC state"""
	if not npc_relationships.has(npc_name):
		return

	var state = npc_relationships[npc_name]
	npc.trust_level = state.trust_level
	npc.conversation_level = state.conversation_level
	npc.level_2_choice = state.level_2_choice
	npc.level_3_used_options = state.level_3_used_options.duplicate()
	npc.conversation_exhausted = state.get("conversation_exhausted", false)
	npc.emotional_state.beats_hit = state.emotional_beats.duplicate()

func log_conversation(npc_name: String, player_choice: String, npc_response: String, trust_change: int):
	"""Record conversation exchange for journal/history"""
	var entry = {
		"timestamp": Time.get_unix_time_from_system(),
		"npc": npc_name,
		"player_choice": player_choice,
		"npc_response": npc_response,
		"trust_change": trust_change
	}
	conversation_history.append(entry)

	# Also update NPC's player choices history
	if npc_relationships.has(npc_name):
		npc_relationships[npc_name].player_choices.append(player_choice)

func get_npc_trust(npc_name: String) -> int:
	"""Get current trust level with NPC"""
	if not npc_relationships.has(npc_name):
		return 0
	return npc_relationships[npc_name].trust_level

func get_npc_conversation_count(npc_name: String) -> int:
	"""How many times player has talked to this NPC"""
	if not npc_relationships.has(npc_name):
		return 0
	return npc_relationships[npc_name].conversation_count

func get_total_trust() -> int:
	"""Sum of trust with all NPCs"""
	var total = 0
	for npc_data in npc_relationships.values():
		total += npc_data.trust_level
	return total

func get_conversation_history(npc_name: String = "") -> Array[Dictionary]:
	"""Get conversation history, optionally filtered by NPC"""
	if npc_name == "":
		return conversation_history

	var filtered: Array[Dictionary] = []
	for entry in conversation_history:
		if entry.npc == npc_name:
			filtered.append(entry)
	return filtered

func has_discussed_topic(npc_name: String, topic: String) -> bool:
	"""Check if player has discussed a topic with NPC"""
	if not npc_relationships.has(npc_name):
		return false
	return topic in npc_relationships[npc_name].topics_discussed

func mark_topic_discussed(npc_name: String, topic: String):
	"""Mark that a topic has been discussed"""
	if not npc_relationships.has(npc_name):
		init_npc_relationship(npc_name)
	if not topic in npc_relationships[npc_name].topics_discussed:
		npc_relationships[npc_name].topics_discussed.append(topic)

func record_breakthrough(npc_name: String, breakthrough_type: String):
	"""Record a psychological breakthrough moment"""
	if not npc_relationships.has(npc_name):
		init_npc_relationship(npc_name)
	npc_relationships[npc_name].breakthroughs.append({
		"type": breakthrough_type,
		"timestamp": Time.get_unix_time_from_system()
	})

func set_global_flag(flag_name: String, value: Variant):
	"""Set a global story progression flag"""
	global_flags[flag_name] = value

func get_global_flag(flag_name: String, default_value: Variant = null) -> Variant:
	"""Get a global story progression flag"""
	return global_flags.get(flag_name, default_value)

func get_save_summary() -> Dictionary:
	"""Get a human-readable summary of current save state"""
	var total_trust = get_total_trust()
	var npc_count = npc_relationships.size()
	var total_conversations = 0
	var total_breakthroughs = 0

	for npc_data in npc_relationships.values():
		total_conversations += npc_data.conversation_count
		total_breakthroughs += npc_data.breakthroughs.size()

	return {
		"total_trust": total_trust,
		"npcs_met": npc_count,
		"total_conversations": total_conversations,
		"breakthroughs": total_breakthroughs,
		"conversation_log_entries": conversation_history.size()
	}