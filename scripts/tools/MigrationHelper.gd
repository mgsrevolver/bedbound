@tool
extends EditorScript

func _run():
	print("=== Starting Migration to Scalable Architecture ===")

	migrate_npcs()
	setup_autoloads()
	create_sample_resources()

	print("=== Migration Complete ===")
	print("Next steps:")
	print("1. Update Main.tscn to use MainRefactored.gd")
	print("2. Replace NPC instances with NPCRefactored class")
	print("3. Test dialogue loading from JSON files")
	print("4. Configure autoloads in Project Settings")

func migrate_npcs():
	print("\n--- Migrating NPC Data ---")

	var npcs_to_migrate = [
		{
			"id": "paul",
			"name": "Paul",
			"position": Vector2(600, 384),
			"color": Color.BLUE,
			"dialogue_file": "res://data/dialogues/paul_dialogue.json",
			"trust": 0
		},
		{
			"id": "rita",
			"name": "Rita",
			"position": Vector2(400, 384),
			"color": Color.PURPLE,
			"dialogue_file": "res://data/dialogues/rita_dialogue.json",
			"trust": 0
		}
	]

	for npc_info in npcs_to_migrate:
		create_npc_resource(npc_info)

func create_npc_resource(info: Dictionary):
	var npc_data = NPCData.new()
	npc_data.npc_id = info.id
	npc_data.npc_name = info.name
	npc_data.spawn_position = info.position
	npc_data.sprite_color = info.color
	npc_data.dialogue_file = info.dialogue_file
	npc_data.initial_trust_level = info.trust
	npc_data.interaction_radius = 50.0

	var save_path = "res://data/npcs/%s.tres" % info.id
	ResourceSaver.save(npc_data, save_path)
	print("Created NPC resource: %s" % save_path)

func setup_autoloads():
	print("\n--- Setting up Autoloads ---")
	print("Add these autoloads in Project Settings > Autoload:")
	print("1. GlobalState: res://scripts/dialogue/GlobalState.gd")
	print("2. NPCManager: res://scripts/systems/NPCManager.gd")
	print("3. SaveManager: res://scripts/systems/SaveManager.gd")

func create_sample_resources():
	print("\n--- Creating Sample Resources ---")

	var dir = DirAccess.open("res://")
	if not dir.dir_exists("data"):
		dir.make_dir("data")
	if not dir.dir_exists("data/npcs"):
		dir.make_dir("data/npcs")
	if not dir.dir_exists("data/dialogues"):
		dir.make_dir("data/dialogues")

	print("Created data directory structure")

	create_additional_npc_samples()

func create_additional_npc_samples():
	var sample_npcs = [
		{
			"id": "merchant",
			"name": "Marcus",
			"position": Vector2(800, 400),
			"color": Color.GOLD,
			"description": "Town merchant with stories of distant places"
		},
		{
			"id": "elder",
			"name": "Eleanor",
			"position": Vector2(500, 200),
			"color": Color.GRAY,
			"description": "Village elder who remembers everything"
		},
		{
			"id": "artist",
			"name": "Alex",
			"position": Vector2(300, 500),
			"color": Color.MAGENTA,
			"description": "Struggling artist seeking meaning"
		},
		{
			"id": "teacher",
			"name": "Thomas",
			"position": Vector2(600, 600),
			"color": Color.GREEN,
			"description": "Retired teacher questioning their impact"
		},
		{
			"id": "doctor",
			"name": "Diana",
			"position": Vector2(700, 300),
			"color": Color.RED,
			"description": "Doctor dealing with burnout"
		}
	]

	for npc_info in sample_npcs:
		var npc_data = NPCData.new()
		npc_data.npc_id = npc_info.id
		npc_data.npc_name = npc_info.name
		npc_data.spawn_position = npc_info.position
		npc_data.sprite_color = npc_info.color
		npc_data.initial_trust_level = 0
		npc_data.interaction_radius = 50.0
		npc_data.description = npc_info.description

		var dialogue_path = "res://data/dialogues/%s_dialogue.json" % npc_info.id
		npc_data.dialogue_file = dialogue_path

		var save_path = "res://data/npcs/%s.tres" % npc_info.id
		ResourceSaver.save(npc_data, save_path)
		print("Created sample NPC: %s" % npc_info.name)

		create_sample_dialogue_json(npc_info.id, npc_info.name)

func create_sample_dialogue_json(id: String, npc_name: String):
	var dialogue = DialogueLoader.create_sample_dialogue(npc_name)
	var json = JSON.new()
	var json_string = json.stringify(dialogue, "\t")

	var file_path = "res://data/dialogues/%s_dialogue.json" % id
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print("Created sample dialogue: %s" % file_path)