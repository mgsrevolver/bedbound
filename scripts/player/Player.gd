extends CharacterBody2D
class_name Player

signal interaction_triggered(npc)

var speed: float = 120.0
var direction: Vector2 = Vector2.DOWN
var main_scene: Node

func _ready():
	main_scene = get_tree().get_first_node_in_group("main")

	var texture = ImageTexture.new()
	var image = Image.create(24, 32, false, Image.FORMAT_RGB8)
	image.fill(Color(0.29, 0.565, 0.886))
	texture.set_image(image)
	$Sprite2D.texture = texture

func _physics_process(delta):
	handle_movement()
	move_and_slide()

func handle_movement():
	# Don't allow movement during dialogue
	if main_scene and main_scene.current_state != main_scene.GameState.OVERWORLD:
		velocity = Vector2.ZERO
		return

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
	update_sprite_direction()

func update_sprite_direction():
	match direction:
		Vector2.UP:
			rotation_degrees = -5
		Vector2.DOWN:
			rotation_degrees = 5
		Vector2.LEFT:
			rotation_degrees = -2
		Vector2.RIGHT:
			rotation_degrees = 2

func interact_with_npc(npc):
	interaction_triggered.emit(npc)
