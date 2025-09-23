extends Area2D
class_name NPC

signal player_approached

var npc_name: String
var dialogue_state: Dictionary = {}
var conversation_tree: Dictionary = {}
var trust_level: int = 0

func setup(name: String, pos: Vector2, color: Color = Color.GREEN):
	npc_name = name
	position = pos
	create_sprite(color)
	area_entered.connect(_on_area_entered)
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
		player_approached.emit()
		var dialogue_manager = get_tree().get_first_node_in_group("dialogue_manager")
		if dialogue_manager:
			dialogue_manager.start_dialogue(self)

func get_current_dialogue() -> String:
	return "Hello there..."

func process_dialogue_option(option: DialogueManager.DialogueOption) -> Dictionary:
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

func handle_say_nothing() -> Dictionary:
	trust_level += 1
	return {
		"text": "You listen quietly...",
		"continues": false,
		"options": []
	}

func handle_nod() -> Dictionary:
	trust_level += 1
	return {
		"text": "Yes... exactly...",
		"continues": false,
		"options": []
	}

func handle_ask_why() -> Dictionary:
	return {
		"text": "Well, because...",
		"continues": false,
		"options": []
	}

func handle_repeat_back() -> Dictionary:
	trust_level += 2
	return {
		"text": "That's right... you understand...",
		"continues": false,
		"options": []
	}