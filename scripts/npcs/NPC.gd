extends Area2D
class_name NPC

signal player_approached

enum DeadEndType {
	GENTLE_DEFLECTION,
	BREAKTHROUGH_MOMENT,
	PROTECTIVE_BOUNDARY,
	COMFORTABLE_CONCLUSION,
	TRUST_INSUFFICIENT
}

var npc_name: String
var dialogue_state: Dictionary = {}
var conversation_tree: Dictionary = {}
var trust_level: int = 0
var last_trust_change: int = 0
var emotional_state: Dictionary = {
	"beats_hit": [],
	"conversation_depth": 0,
	"last_meaningful_exchange": "",
	"comfort_level": 0
}
var global_state: GlobalState

func setup(name: String, pos: Vector2, color: Color = Color.GREEN):
	npc_name = name
	position = pos
	create_sprite(color)
	area_entered.connect(_on_area_entered)
	global_state = get_tree().get_first_node_in_group("global_state")
	call_deferred("setup_conversation_tree")

func create_sprite(color: Color):
	var texture = ImageTexture.new()
	var image = Image.create(24, 24, false, Image.FORMAT_RGB8)
	image.fill(color)
	texture.set_image(image)
	$Sprite2D.texture = texture

func setup_conversation_tree():
	pass

func _on_area_entered(area):
	if area.get_parent() is Player:
		# Check if we're already in dialogue
		var main_scene = get_tree().get_first_node_in_group("main")
		if main_scene and main_scene.current_state != main_scene.GameState.OVERWORLD:
			return

		player_approached.emit()
		var dialogue_manager = get_tree().get_first_node_in_group("dialogue_manager")
		if dialogue_manager:
			dialogue_manager.start_dialogue(self)

func get_current_dialogue() -> String:
	return "Hello there..."

func process_dialogue_option(option: DialogueManager.DialogueOption) -> Dictionary:
	var current_branch = get_current_branch()
	if current_branch.is_empty():
		return get_fallback_response(option)

	var option_key = get_option_key(option)
	if not current_branch.has(option_key):
		return get_contextual_default(option)

	var response_data = current_branch[option_key]
	return process_response(response_data, option)

func get_current_branch() -> Dictionary:
	for branch_name in conversation_tree.get("branches", {}):
		var branch = conversation_tree.branches[branch_name]
		if branch.has("conditions") and branch.conditions.call():
			return branch
	return {}

func get_option_key(option: DialogueManager.DialogueOption) -> String:
	match option:
		DialogueManager.DialogueOption.SAY_NOTHING:
			return "say_nothing"
		DialogueManager.DialogueOption.NOD:
			return "nod"
		DialogueManager.DialogueOption.ASK_WHY:
			return "ask_why"
		DialogueManager.DialogueOption.REPEAT_BACK:
			return "repeat_back"
		_:
			return "unknown"

func process_response(response_data: Dictionary, option: DialogueManager.DialogueOption) -> Dictionary:
	var trust_change = response_data.get("trust_change", 0)
	last_trust_change = trust_change
	trust_level += trust_change
	if global_state:
		global_state.update_npc_trust(npc_name, trust_change)

	if response_data.has("unlocks"):
		for unlock in response_data.unlocks:
			dialogue_state[unlock] = true

	if response_data.has("knowledge_gained"):
		for knowledge in response_data.knowledge_gained:
			if global_state:
				global_state.player_learns(knowledge, npc_name)

	if response_data.has("emotional_beat"):
		emotional_state.beats_hit.append(response_data.emotional_beat)

	emotional_state.conversation_depth += 1
	emotional_state.last_meaningful_exchange = get_option_key(option)

	return {
		"text": response_data.get("response", "..."),
		"continues": response_data.get("continues", false),
		"options": response_data.get("options", []),
		"dead_end_type": response_data.get("type", "")
	}

func get_contextual_default(option: DialogueManager.DialogueOption) -> Dictionary:
	match option:
		DialogueManager.DialogueOption.SAY_NOTHING:
			return handle_say_nothing()
		DialogueManager.DialogueOption.NOD:
			return handle_nod()
		DialogueManager.DialogueOption.ASK_WHY:
			return handle_ask_why()
		DialogueManager.DialogueOption.REPEAT_BACK:
			return handle_repeat_back()
		_:
			return {"text": "...", "continues": false, "options": []}

func get_fallback_response(option: DialogueManager.DialogueOption) -> Dictionary:
	return get_contextual_default(option)

func get_last_trust_change() -> int:
	return last_trust_change

func handle_say_nothing() -> Dictionary:
	var trust_change = 1
	last_trust_change = trust_change
	trust_level += trust_change

	if emotional_state.comfort_level >= 3:
		return {
			"text": "This comfortable silence... it feels like understanding.",
			"continues": false,
			"options": [],
			"type": DeadEndType.COMFORTABLE_CONCLUSION
		}
	elif trust_level >= 5:
		return {
			"text": "You don't need to fill every silence. I appreciate that.",
			"continues": false,
			"options": [],
			"type": DeadEndType.BREAKTHROUGH_MOMENT
		}
	else:
		return {
			"text": "You listen quietly...",
			"continues": false,
			"options": []
		}

func handle_nod() -> Dictionary:
	var trust_change = 1
	last_trust_change = trust_change
	trust_level += trust_change
	emotional_state.comfort_level += 1

	if "understanding" in emotional_state.beats_hit:
		return {
			"text": "Yes... you really do see it the same way I do.",
			"continues": false,
			"options": [],
			"type": DeadEndType.BREAKTHROUGH_MOMENT
		}
	else:
		return {
			"text": "Yes... exactly...",
			"continues": false,
			"options": []
		}

func handle_ask_why() -> Dictionary:
	if trust_level < 3:
		return {
			"text": "That's... quite personal. Perhaps when we know each other better.",
			"continues": false,
			"options": [],
			"type": DeadEndType.TRUST_INSUFFICIENT
		}
	elif "protective" in emotional_state.beats_hit:
		return {
			"text": "Some stories aren't mine to tell, but I appreciate your curiosity.",
			"continues": false,
			"options": [],
			"type": DeadEndType.PROTECTIVE_BOUNDARY
		}
	else:
		return {
			"text": "Well, because...",
			"continues": false,
			"options": []
		}

func handle_repeat_back() -> Dictionary:
	var trust_change = 2
	last_trust_change = trust_change
	trust_level += trust_change
	emotional_state.beats_hit.append("understanding")

	if emotional_state.conversation_depth >= 2:
		return {
			"text": "Yes, those exact words... you truly hear me. Thank you.",
			"continues": false,
			"options": [],
			"type": DeadEndType.BREAKTHROUGH_MOMENT
		}
	else:
		return {
			"text": "That's right... you understand...",
			"continues": false,
			"options": []
		}