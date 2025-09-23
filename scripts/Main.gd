extends Node2D

enum GameState {
	OVERWORLD,
	DIALOG
}

var current_state: GameState = GameState.OVERWORLD
var player: Player
var current_scene: Node2D

func _ready():
	add_to_group("main")
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