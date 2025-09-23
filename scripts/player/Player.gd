extends CharacterBody2D
class_name Player

signal encounter_triggered(enemy_type)

# RPG Stats using the addon's system
@export var character_stats: RpgCharacterMetaStats
var exp: int = 0
var exp_to_next: int = 100

# Health component reference (will be added back later)
# @onready var health_component: IndieBlueprintHealth = $HealthComponent

# Movement
var speed: float = 120.0
var direction: Vector2 = Vector2.DOWN

# Combat
var in_combat: bool = false

func _ready():
	# Initialize character stats if not set
	if not character_stats:
		character_stats = RpgCharacterMetaStats.new()
		setup_default_stats()

	# Sync health component with character stats (will be added back later)
	# health_component.max_health = character_stats.max_hp
	# health_component.current_health = character_stats.hp

	# Connect health component signals (will be added back later)
	# health_component.health_changed.connect(_on_health_changed)
	# health_component.died.connect(_on_player_died)

	# Create a simple colored rectangle as sprite
	var texture = ImageTexture.new()
	var image = Image.create(24, 32, false, Image.FORMAT_RGB8)
	image.fill(Color(0.29, 0.565, 0.886))  # Blue color
	texture.set_image(image)
	$Sprite2D.texture = texture

func setup_default_stats():
	character_stats.level = 1
	character_stats.hp = 20
	character_stats.max_hp = 20
	character_stats.raw_physical_attack = 5
	character_stats.raw_physical_defense = 2
	character_stats.strength = 12
	character_stats.constitution = 10
	character_stats.dexterity = 8
	character_stats.intelligence = 6

func _physics_process(delta):
	if in_combat:
		return

	handle_movement()
	move_and_slide()

func set_combat_mode(combat_active: bool):
	in_combat = combat_active
	# Disable camera when in combat
	if has_node("Camera2D"):
		$Camera2D.enabled = not combat_active

func handle_movement():
	var input_vector = Vector2.ZERO

	if Input.is_action_pressed("move_up"):
		input_vector.y -= 1
		direction = Vector2.UP
	elif Input.is_action_pressed("move_down"):
		input_vector.y += 1
		direction = Vector2.DOWN
	elif Input.is_action_pressed("move_left"):
		input_vector.x -= 1
		direction = Vector2.LEFT
	elif Input.is_action_pressed("move_right"):
		input_vector.x += 1
		direction = Vector2.RIGHT

	velocity = input_vector.normalized() * speed

	# Update sprite based on direction (simple visual indicator)
	update_sprite_direction()

func update_sprite_direction():
	# This would be where you'd change sprite frames for different directions
	# For now, just rotate the character slightly
	match direction:
		Vector2.UP:
			rotation_degrees = -5
		Vector2.DOWN:
			rotation_degrees = 5
		Vector2.LEFT:
			rotation_degrees = -2
		Vector2.RIGHT:
			rotation_degrees = 2

func gain_exp(amount: int):
	exp += amount

	while exp >= exp_to_next:
		level_up()

func level_up():
	exp -= exp_to_next
	character_stats.level += 1

	# Random stat increases using RPG stats
	var hp_increase = randi_range(3, 7)
	var attack_increase = randi_range(1, 3)
	var defense_increase = randi_range(1, 2)
	var strength_increase = randi_range(1, 2)
	var constitution_increase = randi_range(1, 2)

	character_stats.max_hp += hp_increase
	character_stats.hp = character_stats.max_hp  # Full heal on level up
	character_stats.raw_physical_attack += attack_increase
	character_stats.raw_physical_defense += defense_increase
	character_stats.strength += strength_increase
	character_stats.constitution += constitution_increase

	# Sync health component with new max health (will be added back later)
	# health_component.max_health = character_stats.max_hp
	# health_component.current_health = character_stats.hp

	exp_to_next = int(exp_to_next * 1.5)

	print("Level up! Now level ", character_stats.level)

func take_damage(amount: int):
	character_stats.hp -= amount
	character_stats.hp = max(character_stats.hp, 0)

	if character_stats.hp <= 0:
		print("Player defeated!")

func heal(amount: int):
	character_stats.hp = min(character_stats.hp + amount, character_stats.max_hp)

# Health component signal handlers (will be added back later)
# func _on_health_changed(amount: int, type):
#	character_stats.hp = health_component.current_health
#	print("Health changed: ", amount, " Type: ", type)

# func _on_player_died():
#	print("Player defeated!")
#	# Handle player death logic here

func get_stats() -> Dictionary:
	return {
		"level": character_stats.level,
		"hp": character_stats.hp,
		"max_hp": character_stats.max_hp,
		"attack": character_stats.raw_physical_attack,
		"defense": character_stats.raw_physical_defense,
		"strength": character_stats.strength,
		"constitution": character_stats.constitution,
		"dexterity": character_stats.dexterity,
		"intelligence": character_stats.intelligence,
		"exp": exp,
		"exp_to_next": exp_to_next
	}
