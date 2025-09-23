extends Area2D
class_name NPC

signal player_approached
signal farewell_complete

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
var conversation_cooldown: bool = false

# 3-level conversation system
var conversation_level: int = 1
var level_2_choice: String = ""
var level_3_used_options: Array[String] = []
var level_3_available_options: Array[String] = []

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
		# Check if we're already in dialogue or on cooldown
		var main_scene = get_tree().get_first_node_in_group("main")
		if main_scene and main_scene.current_state != main_scene.GameState.OVERWORLD:
			return

		if conversation_cooldown:
			print("NPC: Conversation on cooldown, ignoring area_entered")
			return

		print("NPC: Starting new conversation")
		conversation_cooldown = true
		player_approached.emit()
		var dialogue_manager = get_tree().get_first_node_in_group("dialogue_manager")
		if dialogue_manager:
			dialogue_manager.start_dialogue(self)

func get_current_dialogue() -> String:
	# Only reset if this is a brand new conversation (no previous progress)
	if conversation_level == 1 and level_2_choice == "" and level_3_used_options.is_empty():
		# This is a fresh start
		conversation_level = 1
		level_2_choice = ""
		level_3_used_options.clear()
		level_3_available_options.clear()
		print("NPC: Starting fresh conversation")
	else:
		print("NPC: Resuming conversation at level ", conversation_level, " choice: ", level_2_choice, " used: ", level_3_used_options)

	# Return appropriate dialogue based on current state
	match conversation_level:
		1:
			return conversation_tree.get("level_1", {}).get("text", "Hello there...")
		2:
			# Shouldn't normally be here, but return level 1 text as fallback
			return conversation_tree.get("level_1", {}).get("text", "Hello there...")
		3:
			# At level 3, return continuation text based on level 2 choice
			var level_2_data = conversation_tree.get("level_1", {}).get("branches", {}).get(level_2_choice, {})
			return level_2_data.get("text", "Let's continue our conversation...")
		_:
			return "Hello there..."

func get_current_options() -> Array[String]:
	match conversation_level:
		1:
			# Level 1: All base options available for first response
			return ["wait", "acknowledge", "clarify", "reflect"]
		2:
			# Level 2: Shouldn't happen, transitions immediately to 3
			return ["wait", "acknowledge", "clarify", "reflect"]
		3:
			# Level 3: Return currently available options
			return level_3_available_options
		_:
			return ["wait", "acknowledge", "clarify", "reflect"]

func process_dialogue_option(option: DialogueManager.DialogueOption) -> Dictionary:
	var option_key = get_option_key(option)

	match conversation_level:
		1:
			return handle_level_1_choice(option_key)
		2:
			return handle_level_2_choice(option_key)
		3:
			return handle_level_3_choice(option_key)
		_:
			return get_fallback_response(option)

func handle_level_1_choice(option_key: String) -> Dictionary:
	# This shouldn't happen - Level 1 is just initial text
	# But if it does, treat as Level 2
	return handle_level_2_choice(option_key)

func handle_level_2_choice(option_key: String) -> Dictionary:
	conversation_level = 3  # Move to level 3 after this choice
	level_2_choice = option_key

	# Set up Level 3 available options (all 4 options, including repeating the choice)
	var all_options: Array[String] = ["reflect", "acknowledge", "clarify", "wait"]
	level_3_available_options = all_options.duplicate()
	level_3_used_options.clear()

	# Get response from conversation tree
	var level_2_data = conversation_tree.get("level_1", {}).get("branches", {}).get(option_key, {})
	var response_text = level_2_data.get("text", get_contextual_default_text(option_key))

	return {
		"text": response_text,
		"continues": true,
		"options": level_3_available_options,
		"trust_change": level_2_data.get("trust_change", 0)
	}

func handle_level_3_choice(option_key: String) -> Dictionary:
	# Mark this option as used
	if not level_3_used_options.has(option_key):
		level_3_used_options.append(option_key)

	# Remove from available options
	level_3_available_options = level_3_available_options.filter(func(opt): return opt != option_key)

	# Get response
	var level_3_data = conversation_tree.get("level_1", {}).get("branches", {}).get(level_2_choice, {}).get("level_3", {}).get(option_key, {})
	var response_text = level_3_data.get("text", get_contextual_default_text(option_key))

	# Check if all options exhausted
	if level_3_available_options.is_empty():
		# Conversation complete - trigger graceful end
		return {
			"text": response_text,
			"continues": false,
			"options": [],
			"trust_change": level_3_data.get("trust_change", 1),
			"dead_end_type": DeadEndType.COMFORTABLE_CONCLUSION,
			"farewell": "Thank you for listening so carefully. I feel truly heard."
		}
	else:
		# More options available
		return {
			"text": response_text,
			"continues": true,
			"options": level_3_available_options,
			"trust_change": level_3_data.get("trust_change", 1)
		}

func get_contextual_default_text(option_key: String) -> String:
	match option_key:
		"reflect":
			return "I can see this means a lot to you..."
		"acknowledge":
			return "Yes, I understand..."
		"clarify":
			return "Can you tell me more about that?"
		"wait":
			return "..."
		_:
			return "..."

func get_current_branch() -> Dictionary:
	for branch_name in conversation_tree.get("branches", {}):
		var branch = conversation_tree.branches[branch_name]
		if branch.has("conditions") and branch.conditions.call():
			return branch
	return {}

func get_option_key(option: DialogueManager.DialogueOption) -> String:
	match option:
		DialogueManager.DialogueOption.WAIT:
			return "wait"
		DialogueManager.DialogueOption.ACKNOWLEDGE:
			return "acknowledge"
		DialogueManager.DialogueOption.CLARIFY:
			return "clarify"
		DialogueManager.DialogueOption.REFLECT:
			return "reflect"
		DialogueManager.DialogueOption.PROBE:
			return "probe"
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
		DialogueManager.DialogueOption.WAIT:
			return handle_wait()
		DialogueManager.DialogueOption.ACKNOWLEDGE:
			return handle_acknowledge()
		DialogueManager.DialogueOption.CLARIFY:
			return handle_clarify()
		DialogueManager.DialogueOption.REFLECT:
			return handle_reflect()
		_:
			return {"text": "...", "continues": false, "options": []}

func get_fallback_response(option: DialogueManager.DialogueOption) -> Dictionary:
	return get_contextual_default(option)

func get_last_trust_change() -> int:
	return last_trust_change

func handle_wait() -> Dictionary:
	var trust_change = 1
	last_trust_change = trust_change
	trust_level += trust_change

	if emotional_state.comfort_level >= 3:
		return {
			"text": "This comfortable silence... it feels like understanding. I'll carry this with me.",
			"continues": false,
			"options": [],
			"type": DeadEndType.COMFORTABLE_CONCLUSION,
			"farewell": "Thank you for listening. Until next time."
		}
	elif trust_level >= 5:
		return {
			"text": "You don't need to fill every silence. I appreciate that more than you know.",
			"continues": false,
			"options": [],
			"type": DeadEndType.BREAKTHROUGH_MOMENT,
			"farewell": "Take care of yourself. You have a gift for understanding."
		}
	else:
		return {
			"text": "You listen quietly...",
			"continues": false,
			"options": [],
			"farewell": "Well, I should get going. See you around."
		}

func handle_acknowledge() -> Dictionary:
	var trust_change = 1
	last_trust_change = trust_change
	trust_level += trust_change
	emotional_state.comfort_level += 1

	if "understanding" in emotional_state.beats_hit:
		return {
			"text": "Yes... you really do see it the same way I do.",
			"continues": false,
			"options": [],
			"type": DeadEndType.BREAKTHROUGH_MOMENT,
			"farewell": "I feel lighter now. Thank you for truly seeing me."
		}
	else:
		return {
			"text": "Yes... exactly...",
			"continues": false,
			"options": [],
			"farewell": "I'm glad we understand each other. Take care."
		}

func handle_clarify() -> Dictionary:
	if trust_level < 3:
		return {
			"text": "That's... quite personal. Perhaps when we know each other better.",
			"continues": false,
			"options": [],
			"type": DeadEndType.TRUST_INSUFFICIENT,
			"farewell": "Maybe another time. I need some space to think."
		}
	elif "protective" in emotional_state.beats_hit:
		return {
			"text": "Some stories aren't mine to tell, but I appreciate your curiosity.",
			"continues": false,
			"options": [],
			"type": DeadEndType.PROTECTIVE_BOUNDARY,
			"farewell": "I hope you understand. Take care of yourself."
		}
	else:
		return {
			"text": "Well, because...",
			"continues": false,
			"options": [],
			"farewell": "I've given you something to think about. Until next time."
		}

func handle_reflect() -> Dictionary:
	var trust_change = 2
	last_trust_change = trust_change
	trust_level += trust_change
	emotional_state.beats_hit.append("understanding")

	if emotional_state.conversation_depth >= 2:
		return {
			"text": "Yes, those exact words... you truly hear me. Thank you.",
			"continues": false,
			"options": [],
			"type": DeadEndType.BREAKTHROUGH_MOMENT,
			"farewell": "I won't forget this moment. You have a rare gift."
		}
	else:
		return {
			"text": "That's right... you understand...",
			"continues": false,
			"options": [],
			"farewell": "It means a lot to be heard. Thank you."
		}

func play_farewell_animation(farewell_type: DeadEndType = DeadEndType.COMFORTABLE_CONCLUSION):
	var original_position = position
	var tween = create_tween()
	tween.set_parallel(true)

	match farewell_type:
		DeadEndType.BREAKTHROUGH_MOMENT:
			# Gentle fade with a slight upward movement (feeling lighter)
			tween.tween_property(self, "position", position + Vector2(0, -10), 0.8)
			tween.tween_property(self, "modulate", Color.TRANSPARENT, 1.0)
		DeadEndType.COMFORTABLE_CONCLUSION:
			# Peaceful walk away
			var direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
			tween.tween_property(self, "position", position + direction * 50, 1.2)
			tween.tween_property(self, "modulate", Color.TRANSPARENT, 1.5)
		DeadEndType.TRUST_INSUFFICIENT, DeadEndType.PROTECTIVE_BOUNDARY:
			# Quick, somewhat distant departure
			var direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
			tween.tween_property(self, "position", position + direction * 30, 0.6)
			tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.8)
		_:
			# Default gentle departure
			var direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
			tween.tween_property(self, "position", position + direction * 40, 1.0)
			tween.tween_property(self, "modulate", Color.TRANSPARENT, 1.2)

	tween.finished.connect(func():
		# Return to original position and make visible again
		position = original_position
		modulate = Color.WHITE
		# Reset conversation completely after farewell - they can start over
		reset_conversation_state()
		# Clear conversation cooldown after farewell animation
		var timer = Timer.new()
		add_child(timer)
		timer.wait_time = 1.0  # 1 second cooldown after farewell
		timer.one_shot = true
		timer.timeout.connect(func():
			conversation_cooldown = false
			print("NPC: Conversation cooldown cleared - conversation reset for new start")
			timer.queue_free()
		)
		timer.start()
		farewell_complete.emit()
	)

func reset_conversation_state():
	conversation_level = 1
	level_2_choice = ""
	level_3_used_options.clear()
	level_3_available_options.clear()
	print("NPC: Conversation state reset - ready for fresh start")
