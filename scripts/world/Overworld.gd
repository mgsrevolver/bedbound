extends Node2D

var player: Player
var npcs: Array[NPC] = []

func _ready():
	player = $Player
	setup_world()
	setup_npcs()

	player.interaction_triggered.connect(_on_interaction_triggered)

func setup_world():
	# Create a simple grass tilemap
	var tilemap = $TileMap

	# Create tileset resource programmatically
	var tileset = TileSet.new()
	var source = TileSetAtlasSource.new()

	# Create a simple grass texture
	var texture = ImageTexture.new()
	var image = Image.create(32, 32, false, Image.FORMAT_RGB8)
	image.fill(Color(0.133, 0.545, 0.133))  # Forest green
	texture.set_image(image)

	source.texture = texture
	source.texture_region_size = Vector2i(32, 32)

	# Add the source to tileset
	tileset.add_source(source, 0)

	# Set up the tilemap
	tilemap.tile_set = tileset

	# Fill the map with grass tiles
	for x in range(-20, 21):
		for y in range(-15, 16):
			tilemap.set_cell(0, Vector2i(x, y), 0, Vector2i(0, 0))

func setup_npcs():
	var paul = $NPCs/Paul
	paul.setup("Paul", Vector2(600, 384), Color.BLUE)
	npcs.append(paul)

func _on_interaction_triggered(npc):
	print("Player wants to interact with NPC: ", npc.npc_name)