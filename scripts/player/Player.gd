extends CharacterBody2D
class_name Player

signal encounter_triggered(enemy_type)

# Player stats
var level: int = 1
var hp: int = 20
var max_hp: int = 20
var attack: int = 5
var defense: int = 2
var exp: int = 0
var exp_to_next: int = 100

# Movement
var speed: float = 120.0
var direction: Vector2 = Vector2.DOWN

# Combat
var in_combat: bool = false

func _ready():
	# Create a simple colored rectangle as sprite
	var texture = ImageTexture.new()
	var image = Image.create(24, 32, false, Image.FORMAT_RGB8)
	image.fill(Color(0.29, 0.565, 0.886))  # Blue color
	texture.set_image(image)
	$Sprite2D.texture = texture

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
	level += 1

	# Random stat increases
	var hp_increase = randi_range(3, 7)
	var attack_increase = randi_range(1, 3)
	var defense_increase = randi_range(1, 2)

	max_hp += hp_increase
	hp = max_hp  # Full heal on level up
	attack += attack_increase
	defense += defense_increase

	exp_to_next = int(exp_to_next * 1.5)

	print("Level up! Now level ", level)

func take_damage(amount: int):
	hp -= amount
	hp = max(hp, 0)

	if hp <= 0:
		print("Player defeated!")

func heal(amount: int):
	hp = min(hp + amount, max_hp)

func get_stats() -> Dictionary:
	return {
		"level": level,
		"hp": hp,
		"max_hp": max_hp,
		"attack": attack,
		"defense": defense,
		"exp": exp,
		"exp_to_next": exp_to_next
	}
