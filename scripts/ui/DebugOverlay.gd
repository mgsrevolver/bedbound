extends Control
class_name DebugOverlay

@onready var debug_panel: Panel = $DebugPanel
@onready var debug_text: RichTextLabel = $DebugPanel/DebugText

var is_visible: bool = true
var current_npc: NPC
var global_state: GlobalState

func _ready():
	global_state = get_tree().get_first_node_in_group("global_state")
	add_to_group("debug_overlay")

	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.0, 0.0, 0.0, 0.7)
	panel_style.border_color = Color(0.5, 0.5, 0.5, 1.0)
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_width_left = 2
	debug_panel.add_theme_stylebox_override("panel", panel_style)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_visibility()

func toggle_visibility():
	is_visible = !is_visible
	visible = is_visible

	# Notify dialogue UI to adjust layout
	var dialogue_ui = get_tree().get_nodes_in_group("dialogue_ui")
	for ui in dialogue_ui:
		if ui.has_method("on_debug_panel_toggled"):
			ui.on_debug_panel_toggled(is_visible)

func update_debug_info(npc: NPC = null):
	if npc:
		current_npc = npc

	var debug_info = ""

	if current_npc:
		debug_info += "[color=yellow]%s[/color] | Trust: %d (%+d) | Depth: %d" % [
			current_npc.npc_name,
			current_npc.trust_level,
			current_npc.last_trust_change,
			current_npc.emotional_state.conversation_depth
		]

		if current_npc.emotional_state.beats_hit.size() > 0:
			debug_info += " | Beats: %s" % str(current_npc.emotional_state.beats_hit)

		debug_info += "\n"

		var active_states = []
		for key in current_npc.dialogue_state:
			if current_npc.dialogue_state[key]:
				active_states.append(key)
		if active_states.size() > 0:
			debug_info += "[color=lightgreen]Active:[/color] %s\n" % str(active_states)

	if global_state:
		var npc_trusts = global_state.global_trust_network
		if npc_trusts.size() > 0:
			debug_info += "[color=magenta]Global Trust:[/color] "
			var trust_items = []
			for npc_name in npc_trusts:
				trust_items.append("%s:%d" % [npc_name, npc_trusts[npc_name]])
			debug_info += " | ".join(trust_items) + "\n"

		var knowledge_count = global_state.player_knowledge.size()
		var connections = global_state.story_connections
		var unlocked_connections = 0
		for connection_key in connections:
			if connections[connection_key].unlocked:
				unlocked_connections += 1

		debug_info += "[color=orange]Knowledge: %d | Connections: %d/%d[/color]" % [knowledge_count, unlocked_connections, connections.size()]

	debug_text.text = debug_info

func _on_dialogue_started(npc: NPC):
	update_debug_info(npc)

func _on_dialogue_option_processed(npc: NPC):
	update_debug_info(npc)