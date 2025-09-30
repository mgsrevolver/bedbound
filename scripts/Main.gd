extends Node2D

enum GameState {
	OVERWORLD,
	DIALOG,
	JOURNAL
}

var current_state: GameState = GameState.OVERWORLD
var player: Player
var current_scene: Node2D
var save_manager: SaveManager
var journal_instance: Control

func _ready():
	add_to_group("main")

	# Create or get SaveManager as autoload
	if not has_node("/root/SaveManager"):
		save_manager = SaveManager.new()
		save_manager.name = "SaveManager"
		get_tree().root.add_child(save_manager)
	else:
		save_manager = get_node("/root/SaveManager")

	initialize_game()

func initialize_game():
	change_to_overworld()

func change_to_overworld():
	if current_scene:
		current_scene.queue_free()

	var overworld_scene = preload("res://scenes/overworld/Overworld.tscn")
	current_scene = overworld_scene.instantiate()
	$Overworld.add_child(current_scene)
	current_state = GameState.OVERWORLD

	player = current_scene.get_node("Player")
	if player:
		player.add_to_group("player")

func start_dialog():
	current_state = GameState.DIALOG

func end_dialog():
	current_state = GameState.OVERWORLD

func open_journal():
	if current_state != GameState.OVERWORLD:
		return

	current_state = GameState.JOURNAL

	# Load and show journal
	var journal_scene = preload("res://scenes/ui/Journal.tscn")
	journal_instance = journal_scene.instantiate()
	$UI.add_child(journal_instance)
	journal_instance.journal_closed.connect(_on_journal_closed)
	journal_instance.refresh_journal()

func _on_journal_closed():
	current_state = GameState.OVERWORLD
	if journal_instance:
		journal_instance = null

func _input(event):
	# Press J to open journal
	if event is InputEventKey and event.pressed and event.keycode == KEY_J and not event.echo:
		if current_state == GameState.OVERWORLD:
			open_journal()