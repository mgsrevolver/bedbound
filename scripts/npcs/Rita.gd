extends NPC
class_name Rita

func _ready():
	setup_conversation_tree()

func setup_conversation_tree():
	var dialogue_data = DialogueLoader.load_dialogue_from_json("res://data/dialogue/rita_dialogue.json")

	if dialogue_data:
		npc_name = dialogue_data.npc_name
		conversation_tree = dialogue_data.conversation_tree
		exhausted_response = dialogue_data.exhausted_response
		print("Rita: Successfully loaded dialogue from JSON")
	else:
		push_error("Rita: Failed to load dialogue from JSON")
		npc_name = "Rita"
		exhausted_response = "..."