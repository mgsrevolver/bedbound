class_name WorldChunk
extends Node2D

const CHUNK_SIZE = 512

var chunk_coords: Vector2i
var is_loaded: bool = false
var tilemap: TileMap
var npcs: Array[String] = []
var objects: Array = []
var chunk_data: Dictionary = {}

func initialize(coords: Vector2i):
	chunk_coords = coords
	position = Vector2(coords.x * CHUNK_SIZE, coords.y * CHUNK_SIZE)
	name = "Chunk_%d_%d" % [coords.x, coords.y]

func load_chunk(chunk_definition: Dictionary = {}):
	if is_loaded:
		return

	chunk_data = chunk_definition
	create_tilemap()
	is_loaded = true

func unload_chunk():
	if not is_loaded:
		return

	save_chunk_state()

	if tilemap:
		tilemap.queue_free()
		tilemap = null

	for obj in objects:
		obj.queue_free()
	objects.clear()

	is_loaded = false

func create_tilemap():
	tilemap = TileMap.new()
	tilemap.name = "TileMap"

	var tileset = create_tileset()
	tilemap.tile_set = tileset

	var terrain_type = chunk_data.get("terrain", "grass")
	fill_terrain(terrain_type)

	add_child(tilemap)

func create_tileset() -> TileSet:
	var tileset = TileSet.new()
	var source = TileSetAtlasSource.new()

	var texture = ImageTexture.new()
	var image = Image.create(32, 32, false, Image.FORMAT_RGB8)

	var terrain_colors = {
		"grass": Color(0.133, 0.545, 0.133),
		"dirt": Color(0.545, 0.353, 0.169),
		"stone": Color(0.502, 0.502, 0.502),
		"sand": Color(0.933, 0.855, 0.663)
	}

	var color = terrain_colors.get(chunk_data.get("terrain", "grass"), Color.WHITE)
	image.fill(color)
	texture.set_image(image)

	source.texture = texture
	source.texture_region_size = Vector2i(32, 32)
	tileset.add_source(source, 0)

	return tileset

func fill_terrain(terrain_type: String):
	var tiles_per_chunk = CHUNK_SIZE / 32

	for x in range(tiles_per_chunk):
		for y in range(tiles_per_chunk):
			tilemap.set_cell(0, Vector2i(x, y), 0, Vector2i(0, 0))

func get_npcs_in_chunk() -> Array[String]:
	return npcs

func add_npc(npc_id: String):
	if not npc_id in npcs:
		npcs.append(npc_id)

func remove_npc(npc_id: String):
	npcs.erase(npc_id)

func save_chunk_state() -> Dictionary:
	return {
		"coords": chunk_coords,
		"npcs": npcs,
		"objects": objects.map(func(obj): return obj.get_state() if obj.has_method("get_state") else {})
	}

func load_chunk_state(state: Dictionary):
	npcs = state.get("npcs", [])
	# Load objects state when implemented