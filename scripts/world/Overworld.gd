extends Node2D

var player: Player
var enemies: Array[Node2D] = []

func _ready():
	player = $Player
	setup_world()
	setup_enemies()

	# Connect player signals
	player.encounter_triggered.connect(_on_encounter_triggered)

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

func setup_enemies():
	# Create some enemies on the map
	create_enemy("Goon", Vector2(300, 300))
	create_enemy("Crow", Vector2(700, 500))
	create_enemy("Goon", Vector2(800, 200))

func create_enemy(enemy_type: String, pos: Vector2):
	var enemy_scene = preload("res://scenes/enemies/Enemy.tscn")
	var enemy = enemy_scene.instantiate()
	enemy.setup(enemy_type, pos)
	$Enemies.add_child(enemy)
	enemies.append(enemy)

	# Connect enemy signals
	enemy.player_collided.connect(_on_enemy_encounter)

func _on_enemy_encounter(enemy_data):
	# Trigger combat
	print("Overworld received enemy encounter signal for: ", enemy_data.name)
	get_tree().call_group("main", "change_to_combat", enemy_data)

func _on_encounter_triggered(enemy_type):
	# This would be called by random encounters
	print("Random encounter with ", enemy_type)