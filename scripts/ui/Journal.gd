extends Control
class_name Journal

signal journal_closed

@onready var background_panel: Panel = $BackgroundPanel
@onready var title_label: Label = $Title
@onready var npc_tabs: TabContainer = $NPCTabs
@onready var summary_tab: VBoxContainer = $NPCTabs/Summary
@onready var close_button: Button = $CloseButton

var save_manager: SaveManager

func _ready():
	save_manager = get_node("/root/SaveManager") if has_node("/root/SaveManager") else null
	close_button.pressed.connect(_on_close_pressed)
	refresh_journal()

func refresh_journal():
	"""Rebuild journal from save data"""
	if not save_manager:
		return

	# Clear existing tabs (except summary)
	for child in npc_tabs.get_children():
		if child != summary_tab:
			child.queue_free()

	# Create summary view
	populate_summary()

	# Create tab for each NPC with conversations
	for npc_name in save_manager.npc_relationships.keys():
		create_npc_tab(npc_name)

func populate_summary():
	"""Show overall statistics"""
	# Clear existing content
	for child in summary_tab.get_children():
		child.queue_free()

	var summary = save_manager.get_save_summary()

	# Title
	var header = Label.new()
	header.text = "Your Journey as a Listener"
	header.add_theme_font_size_override("font_size", 24)
	header.add_theme_color_override("font_color", Color(0.9, 0.9, 0.6))
	summary_tab.add_child(header)

	# Add spacing
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	summary_tab.add_child(spacer)

	# Stats
	var stats_text = """People met: %d
Total conversations: %d
Trust earned: %d
Breakthrough moments: %d
Total exchanges: %d""" % [
		summary.npcs_met,
		summary.total_conversations,
		summary.total_trust,
		summary.breakthroughs,
		summary.conversation_log_entries
	]

	var stats_label = Label.new()
	stats_label.text = stats_text
	stats_label.add_theme_font_size_override("font_size", 18)
	summary_tab.add_child(stats_label)

	# Individual NPC summary
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 30)
	summary_tab.add_child(spacer2)

	var npc_header = Label.new()
	npc_header.text = "Relationships:"
	npc_header.add_theme_font_size_override("font_size", 20)
	npc_header.add_theme_color_override("font_color", Color(0.9, 0.9, 0.6))
	summary_tab.add_child(npc_header)

	for npc_name in save_manager.npc_relationships.keys():
		var npc_data = save_manager.npc_relationships[npc_name]
		var npc_line = Label.new()
		npc_line.text = "  %s - Trust: %d | Talks: %d | Breakthroughs: %d" % [
			npc_name,
			npc_data.trust_level,
			npc_data.conversation_count,
			npc_data.breakthroughs.size()
		]
		npc_line.add_theme_font_size_override("font_size", 16)
		summary_tab.add_child(npc_line)

func create_npc_tab(npc_name: String):
	"""Create a detailed tab for specific NPC"""
	var npc_data = save_manager.npc_relationships[npc_name]

	# Create scroll container for this NPC's history
	var scroll = ScrollContainer.new()
	scroll.name = npc_name
	npc_tabs.add_child(scroll)

	var vbox = VBoxContainer.new()
	scroll.add_child(vbox)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# NPC header with stats
	var header = Label.new()
	header.text = "%s" % npc_name
	header.add_theme_font_size_override("font_size", 22)
	header.add_theme_color_override("font_color", Color(0.9, 0.9, 0.6))
	vbox.add_child(header)

	var stats = Label.new()
	stats.text = "Trust Level: %d | Conversations: %d" % [npc_data.trust_level, npc_data.conversation_count]
	stats.add_theme_font_size_override("font_size", 14)
	stats.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(stats)

	# Breakthroughs section
	if npc_data.breakthroughs.size() > 0:
		var spacer1 = Control.new()
		spacer1.custom_minimum_size = Vector2(0, 20)
		vbox.add_child(spacer1)

		var breakthrough_header = Label.new()
		breakthrough_header.text = "Breakthrough Moments:"
		breakthrough_header.add_theme_font_size_override("font_size", 18)
		breakthrough_header.add_theme_color_override("font_color", Color(0.6, 0.9, 0.9))
		vbox.add_child(breakthrough_header)

		for breakthrough in npc_data.breakthroughs:
			var bt_label = Label.new()
			var timestamp = Time.get_datetime_string_from_unix_time(breakthrough.timestamp)
			bt_label.text = "  • %s (%s)" % [breakthrough.type, timestamp]
			bt_label.add_theme_font_size_override("font_size", 14)
			vbox.add_child(bt_label)

	# Conversation history
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer2)

	var history_header = Label.new()
	history_header.text = "Conversation History:"
	history_header.add_theme_font_size_override("font_size", 18)
	history_header.add_theme_color_override("font_color", Color(0.9, 0.9, 0.6))
	vbox.add_child(history_header)

	var conversation_log = save_manager.get_conversation_history(npc_name)
	if conversation_log.is_empty():
		var no_conv = Label.new()
		no_conv.text = "  (No recorded conversations yet)"
		no_conv.add_theme_font_size_override("font_size", 14)
		no_conv.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		vbox.add_child(no_conv)
	else:
		for i in range(min(conversation_log.size(), 50)):  # Limit to last 50 exchanges
			var entry = conversation_log[i]
			var spacer_small = Control.new()
			spacer_small.custom_minimum_size = Vector2(0, 10)
			vbox.add_child(spacer_small)

			# Player choice
			var choice_label = Label.new()
			choice_label.text = "You: [%s]" % entry.player_choice
			choice_label.add_theme_font_size_override("font_size", 14)
			choice_label.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
			vbox.add_child(choice_label)

			# NPC response (truncated if too long)
			var response = entry.npc_response
			if response.length() > 200:
				response = response.substr(0, 197) + "..."

			var response_label = Label.new()
			response_label.text = "%s: \"%s\"" % [npc_name, response]
			response_label.add_theme_font_size_override("font_size", 14)
			response_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
			response_label.autowrap_mode = TextServer.AUTOWRAP_WORD
			response_label.custom_minimum_size.x = 600
			vbox.add_child(response_label)

			# Trust change indicator
			if entry.trust_change != 0:
				var trust_label = Label.new()
				var trust_color = Color.GREEN if entry.trust_change > 0 else Color.RED
				trust_label.text = "    [Trust %+d]" % entry.trust_change
				trust_label.add_theme_font_size_override("font_size", 12)
				trust_label.add_theme_color_override("font_color", trust_color)
				vbox.add_child(trust_label)

func _on_close_pressed():
	journal_closed.emit()
	queue_free()

func _input(event):
	if event.is_action_pressed("ui_cancel"):  # ESC key
		_on_close_pressed()
		accept_event()