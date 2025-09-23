extends Control

signal combat_ended(player_won: bool)

enum CombatState {
	WAITING,
	PLAYER_TURN,
	ENEMY_TURN,
	BATTLE_END
}

var state: CombatState = CombatState.WAITING
var player: Player
var enemy_data: Dictionary
var battle_log: Array[String] = []
var wait_timer: float = 0.0
var action_selected: bool = false

func _ready():
	# Setup UI references
	pass


func setup_battle(player_ref: Player, enemy_info: Dictionary):
	player = player_ref
	enemy_data = enemy_info.duplicate()

	# Create player sprite in combat
	var player_texture = ImageTexture.new()
	var player_image = Image.create(48, 64, false, Image.FORMAT_RGB8)
	player_image.fill(Color(0.29, 0.565, 0.886))
	player_texture.set_image(player_image)
	$BattleArea/PlayerSprite.texture = player_texture

	# Create enemy sprite in combat
	var enemy_color = Color.BROWN if enemy_data.name == "Goon" else Color.DIM_GRAY
	var enemy_texture = ImageTexture.new()
	var enemy_image = Image.create(48, 48, false, Image.FORMAT_RGB8)
	enemy_image.fill(enemy_color)
	enemy_texture.set_image(enemy_image)
	$BattleArea/EnemySprite.texture = enemy_texture

	# Initialize combat
	add_to_log("A wild " + enemy_data.name + " appeared!")
	state = CombatState.WAITING
	wait_timer = 1.0
	$UI/ActionPrompt.visible = false
	update_ui()

	print("Combat scene setup complete - battle log should show: ", battle_log)

func _process(delta):
	if wait_timer > 0:
		wait_timer -= delta
		if wait_timer <= 0:
			print("Wait timer finished, current state: ", state)
		return

	match state:
		CombatState.WAITING:
			print("Combat transitioning from WAITING to PLAYER_TURN")
			state = CombatState.PLAYER_TURN
			action_selected = false
			$UI/ActionPrompt.visible = true
			print("Action prompt should now be visible: ", $UI/ActionPrompt.visible)

		CombatState.PLAYER_TURN:
			handle_player_turn()

		CombatState.ENEMY_TURN:
			handle_enemy_turn()

		CombatState.BATTLE_END:
			end_battle()

func handle_player_turn():
	if not action_selected and Input.is_action_just_pressed("interact"):
		player_attack()
		action_selected = true
		$UI/ActionPrompt.visible = false
		wait_timer = 1.0

func handle_enemy_turn():
	enemy_attack()
	wait_timer = 1.0

func player_attack():
	var damage = max(1, player.character_stats.raw_physical_attack - enemy_data.defense + randi_range(-1, 2))

	# Apply damage to enemy
	if enemy_data.has("reference"):
		enemy_data.reference.take_damage(damage)
		# Update enemy_data hp to reflect the current state
		enemy_data.hp = enemy_data.reference.hp

	add_to_log("You dealt " + str(damage) + " damage!")

	if enemy_data.hp <= 0:
		add_to_log(enemy_data.name + " was defeated!")
		add_to_log("You gained " + str(enemy_data.exp_reward) + " EXP!")
		state = CombatState.BATTLE_END
	else:
		state = CombatState.ENEMY_TURN

	update_ui()

func enemy_attack():
	var damage = max(1, enemy_data.attack - player.character_stats.raw_physical_defense + randi_range(-1, 2))
	player.take_damage(damage)

	add_to_log(enemy_data.name + " dealt " + str(damage) + " damage!")

	if player.character_stats.hp <= 0:
		add_to_log("You were defeated!")
		state = CombatState.BATTLE_END
	else:
		state = CombatState.PLAYER_TURN
		action_selected = false
		$UI/ActionPrompt.visible = true

	update_ui()

func add_to_log(message: String):
	battle_log.append(message)
	if battle_log.size() > 4:
		battle_log.pop_front()

	var log_text = ""
	for line in battle_log:
		log_text += line + "\n"

	$UI/BattleLog.text = log_text
	print("Battle log updated: ", log_text)

func update_ui():
	$UI/PlayerStats.text = "Player HP: " + str(player.character_stats.hp) + "/" + str(player.character_stats.max_hp)
	$UI/EnemyStats.text = enemy_data.name + " HP: " + str(enemy_data.hp) + "/" + str(enemy_data.max_hp)

func end_battle():
	var player_won = enemy_data.hp <= 0

	if player_won:
		player.gain_exp(enemy_data.exp_reward)
		if enemy_data.has("reference"):
			enemy_data.reference.mark_defeated()

	combat_ended.emit(player_won)
	queue_free()