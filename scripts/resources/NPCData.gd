class_name NPCData
extends Resource

@export var npc_id: String = ""
@export var npc_name: String = ""
@export var spawn_position: Vector2 = Vector2.ZERO
@export var sprite_color: Color = Color.WHITE
@export var initial_trust_level: int = 0

@export var dialogue_file: String = ""
@export var uses_custom_script: bool = false
@export var custom_script_path: String = ""

@export_multiline var description: String = ""
@export var personality_traits: Array[String] = []

@export_group("Interaction Settings")
@export var interaction_radius: float = 50.0
@export var can_move: bool = false
@export var movement_pattern: String = "idle"
@export var movement_radius: float = 100.0

@export_group("Story Connections")
@export var knows_about_npcs: Array[String] = []
@export var unlocks_after_meeting: Array[String] = []
@export var requires_story_flags: Array[String] = []

@export_group("Schedule")
@export var has_schedule: bool = false
@export var schedule_data: Dictionary = {}

func _init():
	resource_name = "NPCData"