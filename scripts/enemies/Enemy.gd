extends Area2D
class_name Enemy

signal player_collided(enemy_data)

var enemy_name: String
var hp: int
var max_hp: int
var attack: int
var defense: int
var exp_reward: int
var defeated: bool = false

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

	# Setup collision
	var collision = RectangleShape2D.new()
	collision.size = Vector2(24, 24)
	$CollisionShape2D.shape = collision

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
	if body is Player and not defeated:
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

func mark_defeated():
	defeated = true
	visible = false
	set_deferred("monitoring", false)