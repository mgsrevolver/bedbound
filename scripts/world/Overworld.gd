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
	# Paul - The Self-Absorbed Complainer (Left - isolated, withdrawn)
	var paul = $NPCs/Paul
	paul.setup("Paul", Vector2(300, 384), Color(0.4, 0.5, 0.7))  # Muted blue - passive, deflated
	npcs.append(paul)

	# Rita - The Failed Academic (North - above others, looking down)
	var rita = $NPCs/Rita
	rita.setup("Rita", Vector2(512, 200), Color(0.6, 0.3, 0.7))  # Purple - intellectual, scattered
	npcs.append(rita)

	# Tatiana - The Irony-Poisoned Troll (Right - aggressive, confrontational)
	var tatiana = $NPCs/Tatiana
	tatiana.setup("Tatiana", Vector2(724, 384), Color(0.9, 0.2, 0.3))  # Red - hostile, intense
	npcs.append(tatiana)

	# Larry - The Enlightened Seeker (South - grounded, "centered")
	var larry = $NPCs/Larry
	larry.setup("Larry", Vector2(512, 568), Color(0.3, 0.8, 0.5))  # Green - natural, spiritual
	npcs.append(larry)

	# Mark - The Compulsive Liar (Northeast - restless, in motion)
	var mark = $NPCs/Mark
	mark.setup("Mark", Vector2(650, 250), Color(0.9, 0.7, 0.2))  # Yellow/Gold - energetic, unstable
	npcs.append(mark)

func _on_interaction_triggered(npc):
	print("Player wants to interact with NPC: ", npc.npc_name)