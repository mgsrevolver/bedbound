extends Node2D

enum GameState {
	OVERWORLD,
	COMBAT,
	MENU,
	DIALOG
}

var current_state: GameState = GameState.OVERWORLD
var player: Player
var current_scene: Node2D

func _ready():
	add_to_group("main")
	initialize_game()

func initialize_game():
	# Load the overworld scene
	change_to_overworld()

func change_to_overworld():
	if current_scene:
		current_scene.queue_free()

	var overworld_scene = preload("res://scenes/overworld/Overworld.tscn")
	current_scene = overworld_scene.instantiate()
	$Overworld.add_child(current_scene)
	current_state = GameState.OVERWORLD

	# Get player reference
	player = current_scene.get_node("Player")
	if player:
		player.add_to_group("player")

func change_to_combat(enemy_data):
	if current_scene:
		current_scene.visible = false

	var combat_scene = preload("res://scenes/combat/Combat.tscn")
	var combat = combat_scene.instantiate()
	add_child(combat)
	combat.setup_battle(player, enemy_data)
	combat.combat_ended.connect(_on_combat_ended)
	current_state = GameState.COMBAT

func _on_combat_ended(player_won: bool):
	# Remove combat scene
	for child in get_children():
		if child.get_script() and child.get_script().get_path().ends_with("Combat.gd"):
			child.queue_free()

	# Show overworld again
	if current_scene:
		current_scene.visible = true

	current_state = GameState.OVERWORLD

	if player_won:
		print("Victory!")
	else:
		print("Defeat!")