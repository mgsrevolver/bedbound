extends Node

signal npc_loaded(npc: NPC)
signal npc_unloaded(npc_name: String)

const NPC_SCENE = preload("res://scenes/npcs/NPC.tscn")
const LOAD_DISTANCE = 1000.0
const UNLOAD_DISTANCE = 1500.0

var npc_definitions: Dictionary = {}
var active_npcs: Dictionary = {}
var inactive_npcs: Array = []
var player: Player

func _ready():
	set_process(false)
	load_npc_definitions()

func initialize(player_ref: Player):
	player = player_ref
	set_process(true)

func load_npc_definitions():
	var config_path = "res://data/npcs/"
	var dir = DirAccess.open(config_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var npc_data = load(config_path + file_name)
				if npc_data:
					npc_definitions[npc_data.npc_id] = npc_data
			file_name = dir.get_next()

func spawn_npc(npc_id: String, position: Vector2) -> NPC:
	if npc_id in active_npcs:
		return active_npcs[npc_id]

	if not npc_id in npc_definitions:
		push_error("NPC definition not found: " + npc_id)
		return null

	var npc_data = npc_definitions[npc_id]
	var npc_instance = NPC_SCENE.instantiate()

	npc_instance.position = position
	npc_instance.initialize_from_data(npc_data)

	active_npcs[npc_id] = npc_instance
	npc_loaded.emit(npc_instance)

	return npc_instance

func despawn_npc(npc_id: String):
	if not npc_id in active_npcs:
		return

	var npc = active_npcs[npc_id]
	active_npcs.erase(npc_id)

	var npc_state = {
		"id": npc_id,
		"position": npc.position,
		"state": npc.get_state_data()
	}
	inactive_npcs.append(npc_state)

	npc_unloaded.emit(npc_id)
	npc.queue_free()

func _process(_delta):
	if not player:
		return

	update_npc_loading()

func update_npc_loading():
	var player_pos = player.global_position

	for npc_id in npc_definitions:
		var npc_data = npc_definitions[npc_id]
		var distance = player_pos.distance_to(npc_data.spawn_position)

		if distance < LOAD_DISTANCE and not npc_id in active_npcs:
			spawn_npc(npc_id, npc_data.spawn_position)
		elif distance > UNLOAD_DISTANCE and npc_id in active_npcs:
			despawn_npc(npc_id)

func get_nearby_npcs(position: Vector2, radius: float) -> Array:
	var nearby = []
	for npc_id in active_npcs:
		var npc = active_npcs[npc_id]
		if position.distance_to(npc.global_position) <= radius:
			nearby.append(npc)
	return nearby

func get_npc_by_id(npc_id: String) -> NPC:
	if npc_id in active_npcs:
		return active_npcs[npc_id]
	return null

func save_all_npc_states() -> Dictionary:
	var save_data = {}

	for npc_id in active_npcs:
		var npc = active_npcs[npc_id]
		save_data[npc_id] = npc.get_state_data()

	for inactive_npc in inactive_npcs:
		save_data[inactive_npc.id] = inactive_npc.state

	return save_data

func load_all_npc_states(save_data: Dictionary):
	for npc_id in save_data:
		if npc_id in active_npcs:
			active_npcs[npc_id].load_state_data(save_data[npc_id])
		else:
			for i in range(inactive_npcs.size()):
				if inactive_npcs[i].id == npc_id:
					inactive_npcs[i].state = save_data[npc_id]
					break