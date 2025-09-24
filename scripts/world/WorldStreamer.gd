class_name WorldStreamer
extends Node2D

signal chunk_loaded(chunk: WorldChunk)
signal chunk_unloaded(coords: Vector2i)

const CHUNK_SIZE = 512
const LOAD_RADIUS = 2
const UNLOAD_RADIUS = 3

var active_chunks: Dictionary = {}
var chunk_definitions: Dictionary = {}
var player: Player
var npc_manager: NPCManager
var current_player_chunk: Vector2i = Vector2i.ZERO

func initialize(player_ref: Player, npc_mgr: NPCManager):
	player = player_ref
	npc_manager = npc_mgr
	load_world_definitions()
	set_process(true)

func load_world_definitions():
	chunk_definitions = {
		Vector2i(0, 0): {
			"terrain": "grass",
			"npcs": ["paul", "rita"],
			"objects": []
		},
		Vector2i(1, 0): {
			"terrain": "grass",
			"npcs": ["village_elder"],
			"objects": []
		},
		Vector2i(0, 1): {
			"terrain": "dirt",
			"npcs": [],
			"objects": []
		},
		Vector2i(-1, 0): {
			"terrain": "stone",
			"npcs": [],
			"objects": []
		}
	}

	for x in range(-5, 6):
		for y in range(-5, 6):
			var coord = Vector2i(x, y)
			if not coord in chunk_definitions:
				chunk_definitions[coord] = {
					"terrain": "grass",
					"npcs": [],
					"objects": []
				}

func _process(_delta):
	if not player:
		return

	var player_chunk = get_chunk_coords(player.global_position)

	if player_chunk != current_player_chunk:
		current_player_chunk = player_chunk
		update_loaded_chunks()

func get_chunk_coords(world_position: Vector2) -> Vector2i:
	return Vector2i(
		int(world_position.x / CHUNK_SIZE),
		int(world_position.y / CHUNK_SIZE)
	)

func update_loaded_chunks():
	var chunks_to_load: Array[Vector2i] = []
	var chunks_to_keep: Array[Vector2i] = []

	for x in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
		for y in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
			var chunk_coord = current_player_chunk + Vector2i(x, y)
			if chunk_coord in chunk_definitions:
				if not chunk_coord in active_chunks:
					chunks_to_load.append(chunk_coord)
				else:
					chunks_to_keep.append(chunk_coord)

	var chunks_to_unload: Array[Vector2i] = []
	for coord in active_chunks:
		if not coord in chunks_to_keep:
			var distance = (coord - current_player_chunk).length()
			if distance > UNLOAD_RADIUS:
				chunks_to_unload.append(coord)

	for coord in chunks_to_unload:
		unload_chunk(coord)

	for coord in chunks_to_load:
		load_chunk(coord)

func load_chunk(coords: Vector2i):
	if coords in active_chunks:
		return

	var chunk = WorldChunk.new()
	chunk.initialize(coords)

	var definition = chunk_definitions.get(coords, {})
	chunk.load_chunk(definition)

	active_chunks[coords] = chunk
	add_child(chunk)

	for npc_id in definition.get("npcs", []):
		var npc_data = npc_manager.npc_definitions.get(npc_id)
		if npc_data:
			var spawn_pos = Vector2(coords.x * CHUNK_SIZE, coords.y * CHUNK_SIZE) + npc_data.spawn_position
			npc_manager.spawn_npc(npc_id, spawn_pos)
			chunk.add_npc(npc_id)

	chunk_loaded.emit(chunk)

func unload_chunk(coords: Vector2i):
	if not coords in active_chunks:
		return

	var chunk = active_chunks[coords]

	for npc_id in chunk.get_npcs_in_chunk():
		npc_manager.despawn_npc(npc_id)

	chunk.unload_chunk()
	active_chunks.erase(coords)
	chunk.queue_free()

	chunk_unloaded.emit(coords)

func get_active_chunk(coords: Vector2i) -> WorldChunk:
	return active_chunks.get(coords, null)

func get_chunk_at_position(world_position: Vector2) -> WorldChunk:
	var coords = get_chunk_coords(world_position)
	return get_active_chunk(coords)

func save_world_state() -> Dictionary:
	var state = {}
	for coords in active_chunks:
		state[coords] = active_chunks[coords].save_chunk_state()
	return state

func load_world_state(state: Dictionary):
	for coords in state:
		if coords in active_chunks:
			active_chunks[coords].load_chunk_state(state[coords])