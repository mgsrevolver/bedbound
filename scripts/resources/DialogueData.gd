class_name DialogueData
extends Resource

@export var dialogue_id: String = ""
@export var npc_name: String = ""

@export var conversation_tree: Dictionary = {}

@export_group("Metadata")
@export var author: String = ""
@export var version: String = "1.0"
@export var tags: Array[String] = []

func get_conversation_at_level(level: int, trust_level: int = 0) -> Dictionary:
	var level_key = "level_" + str(level)
	if level_key in conversation_tree:
		return conversation_tree[level_key]
	return {}

func get_branch(level: int, branch_key: String) -> Dictionary:
	var level_data = get_conversation_at_level(level)
	if "branches" in level_data and branch_key in level_data.branches:
		return level_data.branches[branch_key]
	return {}

func has_level_3_content(level: int, branch_key: String) -> bool:
	var branch = get_branch(level, branch_key)
	return "level_3" in branch

func get_level_3_content(level: int, branch_key: String) -> Dictionary:
	var branch = get_branch(level, branch_key)
	if "level_3" in branch:
		return branch.level_3
	return {}