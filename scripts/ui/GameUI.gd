extends Control

var player: Player

func _ready():
	# Find player and connect to updates
	await get_tree().process_frame
	find_player()

func find_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		update_stats()

func _process(_delta):
	if player:
		update_stats()

func update_stats():
	if not player:
		return

	$PlayerStatsPanel/StatsContainer/HPLabel.text = "HP: " + str(player.hp) + "/" + str(player.max_hp)
	$PlayerStatsPanel/StatsContainer/LevelLabel.text = "Level: " + str(player.level)
	$PlayerStatsPanel/StatsContainer/EXPLabel.text = "EXP: " + str(player.exp)