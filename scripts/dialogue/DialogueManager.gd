extends Node
class_name DialogueManager

signal dialogue_ended

enum DialogueOption {
	WAIT,
	ACKNOWLEDGE,
	CLARIFY,
	REFLECT,
	PROBE
}

var current_npc: NPC
var dialogue_ui: Control
var debug_overlay: DebugOverlay
var main_scene: Node
var save_manager: SaveManager

func _ready():
	main_scene = get_parent()
	add_to_group("dialogue_manager")
	setup_debug_overlay()

	# Get or wait for SaveManager
	if has_node("/root/SaveManager"):
		save_manager = get_node("/root/SaveManager")
	else:
		# Wait for it to be created
		await get_tree().create_timer(0.1).timeout
		if has_node("/root/SaveManager"):
			save_manager = get_node("/root/SaveManager")

func start_dialogue(npc: NPC):
	current_npc = npc
	main_scene.start_dialog()

	# Initialize NPC in save manager if needed
	if save_manager:
		save_manager.init_npc_relationship(npc.npc_name)
		# Restore NPC state from save
		save_manager.restore_npc_state(npc.npc_name, npc)

	dialogue_ui = preload("res://scenes/ui/ConversationWheel.tscn").instantiate()

	var ui_layer = get_tree().current_scene.get_node("UI")
	if ui_layer:
		ui_layer.add_child(dialogue_ui)
	else:
		get_tree().current_scene.add_child(dialogue_ui)

	dialogue_ui.option_selected.connect(_on_option_selected)
	dialogue_ui.conversation_finished.connect(end_dialogue)
	dialogue_ui.conversation_left.connect(_on_conversation_left)
	dialogue_ui.set_trust_level(npc.trust_level)
	dialogue_ui.update_conversation_state(
		npc.conversation_level,
		npc.level_2_choice,
		npc.level_3_used_options
	)
	var initial_options = npc.get_current_options()
	dialogue_ui.setup_dialogue(npc.get_current_dialogue())
	dialogue_ui.setup_npc_portrait(npc)
	dialogue_ui.update_available_options(initial_options)

	if debug_overlay:
		debug_overlay.update_debug_info(current_npc)

func _on_option_selected(option: DialogueOption):
	print("DialogueManager: Option selected: ", option)
	var option_key = get_option_key_string(option)
	var response = current_npc.process_dialogue_option(option)
	print("DialogueManager: Response: ", response)

	# Log this exchange to SaveManager
	if save_manager and current_npc:
		save_manager.log_conversation(
			current_npc.npc_name,
			option_key,
			response.text,
			response.get("trust_change", 0)
		)

	if debug_overlay:
		debug_overlay.update_debug_info(current_npc)

	# Update conversation wheel with current state
	dialogue_ui.update_conversation_state(
		current_npc.conversation_level,
		current_npc.level_2_choice,
		current_npc.level_3_used_options
	)

	if response.continues:
		print("DialogueManager: Continuing with options: ", response.options)
		dialogue_ui.update_dialogue(response.text, response.options)
	else:
		print("DialogueManager: Conversation ending")
		# Update dialogue with empty options to hide wheel, then show end screen
		dialogue_ui.update_dialogue(response.text, response.options)
		show_conversation_end(response)

func show_conversation_end(response: Dictionary):
	print("DialogueManager: show_conversation_end called with response: ", response)
	var trust_change = current_npc.get_last_trust_change()
	var total_trust = current_npc.trust_level
	var dead_end_type = response.get("dead_end_type", null)
	var farewell_message = response.get("farewell", "")

	# Record breakthrough if this was a significant moment
	if save_manager and dead_end_type == NPC.DeadEndType.BREAKTHROUGH_MOMENT:
		save_manager.record_breakthrough(current_npc.npc_name, "authentic_moment")

	# Convert enum to string if needed
	var dead_end_type_string = ""
	var dead_end_type_enum = null
	if dead_end_type != null:
		if dead_end_type is int:
			dead_end_type_enum = dead_end_type
			# Convert enum value to string
			match dead_end_type:
				NPC.DeadEndType.GENTLE_DEFLECTION:
					dead_end_type_string = "GENTLE_DEFLECTION"
				NPC.DeadEndType.BREAKTHROUGH_MOMENT:
					dead_end_type_string = "BREAKTHROUGH_MOMENT"
				NPC.DeadEndType.PROTECTIVE_BOUNDARY:
					dead_end_type_string = "PROTECTIVE_BOUNDARY"
				NPC.DeadEndType.COMFORTABLE_CONCLUSION:
					dead_end_type_string = "COMFORTABLE_CONCLUSION"
				NPC.DeadEndType.TRUST_INSUFFICIENT:
					dead_end_type_string = "TRUST_INSUFFICIENT"
		else:
			dead_end_type_string = str(dead_end_type)

	dialogue_ui.show_conversation_end(current_npc.npc_name, trust_change, total_trust, dead_end_type_string, farewell_message, dead_end_type_enum)

func _on_conversation_left():
	print("DialogueManager: Player left conversation - saving state")
	# Clear the conversation cooldown when leaving early
	if current_npc:
		current_npc.conversation_cooldown = false
		print("DialogueManager: Cleared conversation cooldown for early exit")
	# Save current conversation state in the NPC (it's already saved)
	# Just exit to overworld without resetting NPC state
	end_dialogue()

func end_dialogue():
	# Save NPC state before ending
	if save_manager and current_npc:
		save_manager.update_npc_state(current_npc.npc_name, current_npc)

	if dialogue_ui:
		dialogue_ui.visible = false
		dialogue_ui.queue_free()

	if main_scene:
		main_scene.end_dialog()
	current_npc = null
	dialogue_ended.emit()

func get_option_key_string(option: DialogueOption) -> String:
	"""Convert option enum to string for logging"""
	match option:
		DialogueOption.WAIT:
			return "wait"
		DialogueOption.ACKNOWLEDGE:
			return "acknowledge"
		DialogueOption.CLARIFY:
			return "clarify"
		DialogueOption.REFLECT:
			return "reflect"
		DialogueOption.PROBE:
			return "probe"
		_:
			return "unknown"

func setup_debug_overlay():
	debug_overlay = preload("res://scenes/ui/DebugOverlay.tscn").instantiate()

	# Add debug overlay to the highest UI layer possible
	var ui_layer = get_tree().current_scene.get_node("UI")
	if ui_layer:
		ui_layer.add_child(debug_overlay)
	else:
		get_tree().current_scene.add_child(debug_overlay)

	# Ensure debug overlay is always on top
	debug_overlay.z_index = 100