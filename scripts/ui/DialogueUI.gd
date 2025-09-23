extends Control
class_name DialogueUI

signal option_selected(option: DialogueManager.DialogueOption)
signal conversation_finished

@onready var dialogue_text: RichTextLabel = $DialoguePanel/DialogueText
@onready var option_container: VBoxContainer = $OptionsPanel/OptionContainer
@onready var options_panel: Panel = $OptionsPanel
@onready var dialogue_panel: Panel = $DialoguePanel

var dialogue_options = [
	"Say nothing",
	"Nod",
	"Ask why",
	"Repeat their words back"
]

func _ready():
	add_to_group("dialogue_ui")

	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	$DialoguePanel.add_theme_stylebox_override("panel", panel_style)

	var options_style = StyleBoxFlat.new()
	options_style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	$OptionsPanel.add_theme_stylebox_override("panel", options_style)

	adjust_layout_for_debug_panel()

func setup_dialogue(text: String):
	dialogue_text.text = text
	create_option_buttons()

func update_dialogue(text: String, available_options: Array = []):
	dialogue_text.text = text
	if available_options.is_empty():
		create_option_buttons()
	else:
		create_custom_options(available_options)

func create_option_buttons():
	clear_options()

	for i in range(4):
		var button = Button.new()
		button.text = dialogue_options[i]
		button.custom_minimum_size = Vector2(200, 60)
		button.add_theme_font_size_override("font_size", 18)

		var option_type = DialogueManager.DialogueOption.values()[i]
		button.pressed.connect(func(): option_selected.emit(option_type))

		option_container.add_child(button)

func create_custom_options(options: Array):
	clear_options()

	for i in range(options.size()):
		var button = Button.new()
		button.text = options[i]
		button.custom_minimum_size = Vector2(200, 60)
		button.add_theme_font_size_override("font_size", 18)

		var option_index = i
		button.pressed.connect(func(): option_selected.emit(option_index))

		option_container.add_child(button)

func clear_options():
	for child in option_container.get_children():
		child.queue_free()

func show_conversation_end(npc_name: String, trust_change: int, total_trust: int, dead_end_type: String = ""):
	clear_options()

	var end_message = "Conversation with %s ended." % npc_name
	var trust_message = ""

	if trust_change > 0:
		trust_message = "\n[color=green]Trust gained: +%d[/color]" % trust_change
	elif trust_change < 0:
		trust_message = "\n[color=red]Trust lost: %d[/color]" % trust_change

	var trust_level_message = "\n[color=yellow]Total Trust: %d[/color]" % total_trust

	var type_message = ""
	if dead_end_type != "":
		match dead_end_type:
			"BREAKTHROUGH_MOMENT":
				type_message = "\n[color=cyan]✨ Breakthrough moment[/color]"
			"COMFORTABLE_CONCLUSION":
				type_message = "\n[color=lightblue]😌 Comfortable ending[/color]"
			"GENTLE_DEFLECTION":
				type_message = "\n[color=gray]🤐 They deflected gently[/color]"
			"PROTECTIVE_BOUNDARY":
				type_message = "\n[color=orange]🛡️ They set a boundary[/color]"
			"TRUST_INSUFFICIENT":
				type_message = "\n[color=red]⚠️ Need more trust[/color]"

	dialogue_text.text = end_message + trust_message + trust_level_message + type_message

	var continue_button = Button.new()
	continue_button.text = "Continue"
	continue_button.custom_minimum_size = Vector2(200, 60)
	continue_button.add_theme_font_size_override("font_size", 18)
	continue_button.pressed.connect(func(): conversation_finished.emit())
	option_container.add_child(continue_button)

func adjust_layout_for_debug_panel():
	# Check if debug overlay exists and is visible
	var debug_overlay = get_tree().get_first_node_in_group("debug_overlay")
	var debug_panel_height = 0

	if debug_overlay and debug_overlay.visible:
		debug_panel_height = 125  # Debug panel height + margin

	# Adjust options panel to start after debug panel
	options_panel.offset_top = 10 + debug_panel_height

	# If debug panel is taking space, reduce options panel height accordingly
	if debug_panel_height > 0:
		options_panel.offset_bottom = 390  # Keep same bottom position
	else:
		# Reclaim the space when debug panel is hidden
		options_panel.offset_top = 10
		options_panel.offset_bottom = 390

func on_debug_panel_toggled(is_visible: bool):
	adjust_layout_for_debug_panel()