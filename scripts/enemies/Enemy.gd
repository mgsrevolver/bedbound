extends Area2D
class_name Enemy

signal player_collided(enemy_data)

var enemy_name: String
var attack: int
var defense: int
var exp_reward: int
var defeated: bool = false

# Component references (will be added back later)
# @onready var health_component: IndieBlueprintHealth = $HealthComponent

var hp: int
var max_hp: int

func setup(enemy_type: String, pos: Vector2):
	enemy_name = enemy_type
	position = pos

	# Set stats based on enemy type
	match enemy_type:
		"Goon":
			hp = 8
			max_hp = 8
			attack = 3
			defense = 1
			exp_reward = 15
			create_sprite(Color(0.545, 0.271, 0.075))  # Brown
		"Crow":
			hp = 12
			max_hp = 12
			attack = 4
			defense = 2
			exp_reward = 25
			create_sprite(Color(0.184, 0.184, 0.184))  # Dark gray

	# Connect health component signals (will be added back later)
	# health_component.died.connect(_on_enemy_died)

	# Connect signal
	body_entered.connect(_on_body_entered)

func create_sprite(color: Color):
	var texture = ImageTexture.new()
	var image = Image.create(24, 24, false, Image.FORMAT_RGB8)
	image.fill(color)
	texture.set_image(image)
	$Sprite2D.texture = texture

	# Add a red center dot to indicate it's an enemy
	var center_image = Image.create(8, 8, false, Image.FORMAT_RGB8)
	center_image.fill(Color.RED)
	var center_texture = ImageTexture.new()
	center_texture.set_image(center_image)

func _on_body_entered(body):
	print("Enemy collision detected with: ", body.name)
	if body is Player and not defeated:
		print("Player collision confirmed, triggering combat with ", enemy_name)
		var enemy_data = get_enemy_data()
		player_collided.emit(enemy_data)

func get_enemy_data() -> Dictionary:
	return {
		"name": enemy_name,
		"hp": hp,
		"max_hp": max_hp,
		"attack": attack,
		"defense": defense,
		"exp_reward": exp_reward,
		"reference": self
	}

func take_damage(amount: int):
	hp -= amount
	hp = max(hp, 0)

	if hp <= 0:
		_on_enemy_died()

func _on_enemy_died():
	print(enemy_name + " was defeated!")
	mark_defeated()

func mark_defeated():
	defeated = true
	visible = false
	set_deferred("monitoring", false)