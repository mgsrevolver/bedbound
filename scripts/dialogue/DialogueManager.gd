extends Node
class_name DialogueManager

signal dialogue_ended

enum DialogueOption {
	SAY_NOTHING,
	NOD,
	ASK_WHY,
	REPEAT_BACK
}

var current_npc: NPC
var dialogue_ui: DialogueUI
var main_scene: Node

func _ready():
	main_scene = get_parent()
	add_to_group("dialogue_manager")

func start_dialogue(npc: NPC):
	current_npc = npc
	main_scene.start_dialog()

	dialogue_ui = preload("res://scenes/ui/DialogueUI.tscn").instantiate()

	var ui_layer = get_tree().current_scene.get_node("UI")
	if ui_layer:
		ui_layer.add_child(dialogue_ui)
	else:
		get_tree().current_scene.add_child(dialogue_ui)

	dialogue_ui.option_selected.connect(_on_option_selected)
	dialogue_ui.setup_dialogue(npc.get_current_dialogue())

func _on_option_selected(option: DialogueOption):
	var response = current_npc.process_dialogue_option(option)

	if response.continues:
		dialogue_ui.update_dialogue(response.text, response.options)
	else:
		end_dialogue()

func end_dialogue():
	if dialogue_ui:
		dialogue_ui.queue_free()

	main_scene.end_dialog()
	current_npc = null
	dialogue_ended.emit()