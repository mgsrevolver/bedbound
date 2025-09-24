extends Node2D

enum GameState {
	OVERWORLD,
	DIALOG,
	CUTSCENE,
	PAUSED
}

signal state_changed(new_state: GameState)

@onready var npc_manager: NPCManager = $Systems/NPCManager
@onready var world_streamer: WorldStreamer = $World/WorldStreamer
@onready var dialogue_manager: DialogueManager = $UI/DialogueManager
@onready var game_ui: GameUI = $UI/GameUI
@onready var player: Player = $World/Player

var current_state: GameState = GameState.OVERWORLD
var save_manager: SaveManager

func _ready():
	add_to_group("main")
	setup_systems()
	setup_connections()
	initialize_world()

	print("Main: Game initialized - scalable architecture ready")

func setup_systems():
	save_manager = SaveManager.new()
	save_manager.name = "SaveManager"
	$Systems.add_child(save_manager)

	npc_manager.initialize(player)
	world_streamer.initialize(player, npc_manager)

	var dialogue_pool = ObjectPool.new()
	dialogue_pool.initialize(preload("res://scenes/ui/DialogueUI.tscn"), 3, 10)
	$Systems.add_child(dialogue_pool)

func setup_connections():
	dialogue_manager.dialogue_ended.connect(_on_dialogue_ended)
	player.interaction_triggered.connect(_on_player_interaction)

	npc_manager.npc_loaded.connect(_on_npc_loaded)
	npc_manager.npc_unloaded.connect(_on_npc_unloaded)

	world_streamer.chunk_loaded.connect(_on_chunk_loaded)
	world_streamer.chunk_unloaded.connect(_on_chunk_unloaded)

func initialize_world():
	player.position = Vector2(512, 384)

func _on_dialogue_ended():
	transition_to_state(GameState.OVERWORLD)

func _on_player_interaction(npc):
	if current_state == GameState.OVERWORLD:
		transition_to_state(GameState.DIALOG)
		dialogue_manager.start_dialogue(npc)

func _on_npc_loaded(npc: NPC):
	npc.player_approached.connect(func(): _on_player_interaction(npc))
	print("Main: NPC loaded - %s" % npc.npc_name)

func _on_npc_unloaded(npc_name: String):
	print("Main: NPC unloaded - %s" % npc_name)

func _on_chunk_loaded(chunk: WorldChunk):
	print("Main: Chunk loaded at %v" % chunk.chunk_coords)

func _on_chunk_unloaded(coords: Vector2i):
	print("Main: Chunk unloaded at %v" % coords)

func transition_to_state(new_state: GameState):
	if current_state == new_state:
		return

	exit_state(current_state)
	current_state = new_state
	enter_state(new_state)
	state_changed.emit(new_state)

func exit_state(state: GameState):
	match state:
		GameState.OVERWORLD:
			player.set_movement_enabled(false)
		GameState.DIALOG:
			pass
		GameState.CUTSCENE:
			pass
		GameState.PAUSED:
			get_tree().paused = false

func enter_state(state: GameState):
	match state:
		GameState.OVERWORLD:
			player.set_movement_enabled(true)
			game_ui.hide_all()
		GameState.DIALOG:
			player.set_movement_enabled(false)
		GameState.CUTSCENE:
			player.set_movement_enabled(false)
			game_ui.hide_all()
		GameState.PAUSED:
			get_tree().paused = true

func _input(event):
	if event.is_action_pressed("pause"):
		if current_state == GameState.PAUSED:
			transition_to_state(GameState.OVERWORLD)
		else:
			transition_to_state(GameState.PAUSED)

	if event.is_action_pressed("save"):
		save_game()
	elif event.is_action_pressed("load"):
		load_game()

func save_game():
	var save_data = {
		"player": player.get_save_data(),
		"npcs": npc_manager.save_all_npc_states(),
		"world": world_streamer.save_world_state(),
		"global_state": GlobalState.get_save_data()
	}
	save_manager.save_game(save_data)
	print("Main: Game saved")

func load_game():
	var save_data = save_manager.load_game()
	if save_data:
		player.load_save_data(save_data.get("player", {}))
		npc_manager.load_all_npc_states(save_data.get("npcs", {}))
		world_streamer.load_world_state(save_data.get("world", {}))
		GlobalState.load_save_data(save_data.get("global_state", {}))
		print("Main: Game loaded")

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()