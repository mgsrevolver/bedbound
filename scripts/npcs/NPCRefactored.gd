extends Area2D
class_name NPCRefactored

signal player_approached
signal farewell_complete
signal state_changed

enum DeadEndType {
	GENTLE_DEFLECTION,
	BREAKTHROUGH_MOMENT,
	PROTECTIVE_BOUNDARY,
	COMFORTABLE_CONCLUSION,
	TRUST_INSUFFICIENT
}

var npc_data: NPCData
var dialogue_data: DialogueData
var npc_id: String
var npc_name: String
var trust_level: int = 0
var conversation_cooldown: bool = false

var dialogue_state: Dictionary = {}
var emotional_state: Dictionary = {
	"beats_hit": [],
	"conversation_depth": 0,
	"last_meaningful_exchange": "",
	"comfort_level": 0
}

var conversation_level: int = 1
var level_2_choice: String = ""
var level_3_used_options: Array[String] = []
var level_3_available_options: Array[String] = []
var conversation_exhausted: bool = false

var global_state: GlobalState
var last_trust_change: int = 0

func initialize_from_data(data: NPCData):
	npc_data = data
	npc_id = data.npc_id
	npc_name = data.npc_name
	trust_level = data.initial_trust_level

	create_sprite(data.sprite_color)
	setup_interaction_area(data.interaction_radius)

	if data.dialogue_file != "":
		dialogue_data = load(data.dialogue_file)

	if data.uses_custom_script and data.custom_script_path != "":
		var custom_script = load(data.custom_script_path)
		if custom_script:
			set_script(custom_script)

	area_entered.connect(_on_area_entered)
	global_state = get_tree().get_first_node_in_group("global_state")

func create_sprite(color: Color):
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"

	var texture = ImageTexture.new()
	var image = Image.create(24, 24, false, Image.FORMAT_RGB8)
	image.fill(color)
	texture.set_image(image)

	sprite.texture = texture
	add_child(sprite)

func setup_interaction_area(radius: float):
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = radius
	collision.shape = shape
	add_child(collision)

func _on_area_entered(area):
	if area.get_parent() is Player:
		var main_scene = get_tree().get_first_node_in_group("main")
		if main_scene and main_scene.current_state != main_scene.GameState.OVERWORLD:
			return

		if conversation_cooldown:
			return

		conversation_cooldown = true
		player_approached.emit()

		var dialogue_manager = get_tree().get_first_node_in_group("dialogue_manager")
		if dialogue_manager:
			dialogue_manager.start_dialogue(self)

func get_current_dialogue() -> String:
	if conversation_exhausted:
		return get_exhausted_response()

	if not dialogue_data:
		return "..."

	return dialogue_data.get_conversation_at_level(conversation_level, trust_level).get("text", "Hello there...")

func get_exhausted_response() -> String:
	if dialogue_data and "exhausted_response" in dialogue_data.conversation_tree:
		return dialogue_data.conversation_tree.exhausted_response

	var responses = [
		"...",
		"We've said all there is to say, haven't we?",
		"Sometimes the best conversations are the ones we've already had.",
		"I need some time to think about everything we've discussed."
	]
	return responses[randi() % responses.size()]

func get_current_options() -> Array[String]:
	if conversation_exhausted:
		return []

	match conversation_level:
		1:
			return ["wait", "acknowledge", "clarify", "reflect"]
		3:
			return level_3_available_options
		_:
			return ["wait", "acknowledge", "clarify", "reflect"]

func process_dialogue_option(option: DialogueManager.DialogueOption) -> Dictionary:
	var option_key = get_option_key(option)

	match conversation_level:
		1, 2:
			return handle_level_2_choice(option_key)
		3:
			return handle_level_3_choice(option_key)
		_:
			return get_fallback_response(option)

func handle_level_2_choice(option_key: String) -> Dictionary:
	conversation_level = 3
	level_2_choice = option_key

	level_3_available_options = ["reflect", "acknowledge", "clarify", "wait"]
	level_3_used_options.clear()

	if not dialogue_data:
		return get_fallback_response_for_key(option_key)

	var branch = dialogue_data.get_branch(1, option_key)
	var response_text = branch.get("text", get_contextual_default_text(option_key))
	var trust_change = branch.get("trust_change", 0)

	apply_trust_change(trust_change)
	update_conversation_depth()

	return {
		"text": response_text,
		"continues": true,
		"options": level_3_available_options,
		"trust_change": trust_change
	}

func handle_level_3_choice(option_key: String) -> Dictionary:
	if not level_3_used_options.has(option_key):
		level_3_used_options.append(option_key)

	level_3_available_options = level_3_available_options.filter(func(opt): return opt != option_key)

	if not dialogue_data:
		return get_fallback_response_for_key(option_key)

	var level_3_content = dialogue_data.get_level_3_content(1, level_2_choice)
	var response_data = level_3_content.get(option_key, {})
	var response_text = response_data.get("text", get_contextual_default_text(option_key))
	var trust_change = response_data.get("trust_change", 1)

	apply_trust_change(trust_change)
	update_conversation_depth()

	if level_3_available_options.is_empty():
		check_if_fully_exhausted()
		return {
			"text": response_text,
			"continues": false,
			"options": [],
			"trust_change": trust_change,
			"dead_end_type": DeadEndType.COMFORTABLE_CONCLUSION,
			"farewell": "Thank you for listening so carefully. I feel truly heard."
		}
	else:
		return {
			"text": response_text,
			"continues": true,
			"options": level_3_available_options,
			"trust_change": trust_change
		}

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
		_:
			return "unknown"

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

func get_fallback_response_for_key(option_key: String) -> Dictionary:
	match option_key:
		"wait":
			return handle_wait()
		"acknowledge":
			return handle_acknowledge()
		"clarify":
			return handle_clarify()
		"reflect":
			return handle_reflect()
		_:
			return {"text": "...", "continues": false, "options": []}

func get_fallback_response(option: DialogueManager.DialogueOption) -> Dictionary:
	return get_fallback_response_for_key(get_option_key(option))

func handle_wait() -> Dictionary:
	apply_trust_change(1)
	return {
		"text": "You listen quietly...",
		"continues": false,
		"options": [],
		"farewell": "Well, I should get going. See you around."
	}

func handle_acknowledge() -> Dictionary:
	apply_trust_change(1)
	emotional_state.comfort_level += 1
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
	return {
		"text": "Well, because...",
		"continues": false,
		"options": [],
		"farewell": "I've given you something to think about. Until next time."
	}

func handle_reflect() -> Dictionary:
	apply_trust_change(2)
	emotional_state.beats_hit.append("understanding")
	return {
		"text": "That's right... you understand...",
		"continues": false,
		"options": [],
		"farewell": "It means a lot to be heard. Thank you."
	}

func apply_trust_change(trust_change: int):
	last_trust_change = trust_change
	trust_level += trust_change
	if global_state:
		global_state.update_npc_trust(npc_name, trust_change)

func update_conversation_depth():
	emotional_state.conversation_depth += 1

func check_if_fully_exhausted():
	if level_3_used_options.size() == 4:
		conversation_exhausted = true

func reset_conversation_state():
	conversation_level = 1
	level_2_choice = ""
	level_3_used_options.clear()
	level_3_available_options.clear()

func play_farewell_animation(farewell_type: DeadEndType = DeadEndType.COMFORTABLE_CONCLUSION):
	var original_position = position
	var tween = create_tween()
	tween.set_parallel(true)

	var direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	tween.tween_property(self, "position", position + direction * 40, 1.0)
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 1.2)

	tween.finished.connect(func():
		position = original_position
		modulate = Color.WHITE
		reset_conversation_state()

		var timer = Timer.new()
		add_child(timer)
		timer.wait_time = 1.0
		timer.one_shot = true
		timer.timeout.connect(func():
			conversation_cooldown = false
			timer.queue_free()
		)
		timer.start()
		farewell_complete.emit()
	)

func get_last_trust_change() -> int:
	return last_trust_change

func get_state_data() -> Dictionary:
	return {
		"trust_level": trust_level,
		"dialogue_state": dialogue_state,
		"emotional_state": emotional_state,
		"conversation_level": conversation_level,
		"level_2_choice": level_2_choice,
		"level_3_used_options": level_3_used_options,
		"conversation_exhausted": conversation_exhausted
	}

func load_state_data(data: Dictionary):
	trust_level = data.get("trust_level", 0)
	dialogue_state = data.get("dialogue_state", {})
	emotional_state = data.get("emotional_state", {})
	conversation_level = data.get("conversation_level", 1)
	level_2_choice = data.get("level_2_choice", "")
	level_3_used_options = data.get("level_3_used_options", [])
	conversation_exhausted = data.get("conversation_exhausted", false)