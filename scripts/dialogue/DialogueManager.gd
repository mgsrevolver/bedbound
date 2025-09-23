extends Node
class_name DialogueManager

signal dialogue_ended

enum DialogueOption {
	SAY_NOTHING,
	NOD,
	ASK_WHY,
	REPEAT_BACK,
	PROBE
}

var current_npc: NPC
var dialogue_ui: Control
var debug_overlay: DebugOverlay
var main_scene: Node

func _ready():
	main_scene = get_parent()
	add_to_group("dialogue_manager")
	setup_debug_overlay()

func start_dialogue(npc: NPC):
	current_npc = npc
	main_scene.start_dialog()

	dialogue_ui = preload("res://scenes/ui/ConversationWheel.tscn").instantiate()

	var ui_layer = get_tree().current_scene.get_node("UI")
	if ui_layer:
		ui_layer.add_child(dialogue_ui)
	else:
		get_tree().current_scene.add_child(dialogue_ui)

	dialogue_ui.option_selected.connect(_on_option_selected)
	dialogue_ui.conversation_finished.connect(end_dialogue)
	dialogue_ui.set_trust_level(npc.trust_level)
	dialogue_ui.setup_dialogue(npc.get_current_dialogue())

	if debug_overlay:
		debug_overlay.update_debug_info(current_npc)

func _on_option_selected(option: DialogueOption):
	var response = current_npc.process_dialogue_option(option)

	if debug_overlay:
		debug_overlay.update_debug_info(current_npc)

	if response.continues:
		dialogue_ui.update_dialogue(response.text, response.options)
	else:
		show_conversation_end(response)

func show_conversation_end(response: Dictionary):
	var trust_change = current_npc.get_last_trust_change()
	var total_trust = current_npc.trust_level
	var dead_end_type = response.get("dead_end_type", null)
	var farewell_message = response.get("farewell", "")

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

func end_dialogue():
	if dialogue_ui:
		dialogue_ui.visible = false
		dialogue_ui.queue_free()

	if main_scene:
		main_scene.end_dialog()
	current_npc = null
	dialogue_ended.emit()

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