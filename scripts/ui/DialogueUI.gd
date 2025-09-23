extends Control
class_name DialogueUI

signal option_selected(option: DialogueManager.DialogueOption)

@onready var dialogue_text: RichTextLabel = $DialoguePanel/DialogueText
@onready var option_container: VBoxContainer = $OptionsPanel/OptionContainer

var dialogue_options = [
	"Say nothing",
	"Nod",
	"Ask why",
	"Repeat their words back"
]

func _ready():
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	$DialoguePanel.add_theme_stylebox_override("panel", panel_style)

	var options_style = StyleBoxFlat.new()
	options_style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	$OptionsPanel.add_theme_stylebox_override("panel", options_style)

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