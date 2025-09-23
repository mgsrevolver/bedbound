extends Node
class_name GlobalState

signal story_connection_unlocked(connection_key: String)

var player_knowledge: Dictionary = {}
var story_connections: Dictionary = {}
var global_trust_network: Dictionary = {}

func _ready():
	add_to_group("global_state")

func player_learns(knowledge_key: String, source_npc: String = ""):
	player_knowledge[knowledge_key] = {
		"learned": true,
		"source": source_npc,
		"timestamp": Time.get_unix_time_from_system()
	}

	_check_for_story_connections(knowledge_key)

func player_knows(knowledge_key: String) -> bool:
	return player_knowledge.has(knowledge_key) and player_knowledge[knowledge_key].learned

func add_story_connection(connection_key: String, required_knowledge: Array, unlocks_for_npcs: Array):
	story_connections[connection_key] = {
		"required_knowledge": required_knowledge,
		"unlocks_for_npcs": unlocks_for_npcs,
		"unlocked": false
	}

func _check_for_story_connections(new_knowledge: String):
	for connection_key in story_connections:
		var connection = story_connections[connection_key]
		if connection.unlocked:
			continue

		var all_requirements_met = true
		for required in connection.required_knowledge:
			if not player_knows(required):
				all_requirements_met = false
				break

		if all_requirements_met:
			connection.unlocked = true
			story_connection_unlocked.emit(connection_key)

func get_npc_trust_level(npc_name: String) -> int:
	return global_trust_network.get(npc_name, 0)

func update_npc_trust(npc_name: String, trust_change: int):
	var current_trust = get_npc_trust_level(npc_name)
	global_trust_network[npc_name] = current_trust + trust_change

func get_save_data() -> Dictionary:
	return {
		"player_knowledge": player_knowledge,
		"story_connections": story_connections,
		"global_trust_network": global_trust_network
	}

func load_save_data(data: Dictionary):
	player_knowledge = data.get("player_knowledge", {})
	story_connections = data.get("story_connections", {})
	global_trust_network = data.get("global_trust_network", {})