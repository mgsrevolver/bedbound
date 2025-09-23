extends NPC
class_name VillageElder

func _ready():
	setup_conversation_tree()

func setup_conversation_tree():
	npc_name = "Village Elder"
	dialogue_state = {
		"met_before": false,
		"shared_worry": false,
		"trust_built": false
	}

func get_current_dialogue() -> String:
	if not dialogue_state.met_before:
		return "Oh, hello there... I don't think I've seen you around here before. You have such a quiet presence about you..."
	elif not dialogue_state.shared_worry:
		return "You know, I've been thinking about what happened to the old library. Nobody talks about it anymore, but I remember..."
	else:
		return "There's something comforting about your presence, child. Like you actually listen..."

func handle_say_nothing() -> Dictionary:
	trust_level += 2

	if not dialogue_state.met_before:
		dialogue_state.met_before = true
		return {
			"text": "Ah... you're one of those quiet ones, aren't you? That's refreshing. People these days, always rushing to fill every silence with chatter. But you... you understand the value of simply being present.",
			"continues": true,
			"options": []
		}
	else:
		return {
			"text": "Yes... sometimes silence says more than words ever could. You understand that, don't you?",
			"continues": false,
			"options": []
		}

func handle_nod() -> Dictionary:
	trust_level += 1

	if dialogue_state.met_before and not dialogue_state.shared_worry:
		dialogue_state.shared_worry = true
		return {
			"text": "Yes, you understand. The library burned down three years ago, but that's not the real tragedy. The real tragedy is how quickly everyone forgot what we lost. All those stories... all that history...",
			"continues": true,
			"options": []
		}
	else:
		return {
			"text": "I can see in your eyes that you really do understand. That means more to me than you know.",
			"continues": false,
			"options": []
		}

func handle_ask_why() -> Dictionary:
	if not dialogue_state.met_before:
		return {
			"text": "Why? Well... I suppose it's because you remind me of my granddaughter. She used to listen like that too, before... well, before she moved to the city.",
			"continues": true,
			"options": []
		}
	else:
		return {
			"text": "Why indeed... Sometimes I ask myself why I keep tending to this town when everyone seems so eager to forget its past. But then someone like you comes along...",
			"continues": false,
			"options": []
		}

func handle_repeat_back() -> Dictionary:
	trust_level += 3

	if dialogue_state.shared_worry:
		dialogue_state.trust_built = true
		return {
			"text": "'All those stories, all that history...' Yes, exactly. You see it too, don't you? The weight of what we've lost. No one else seems to care, but you... you truly hear me.",
			"continues": false,
			"options": []
		}
	else:
		return {
			"text": "You're reflecting my words back to me... like a gentle mirror. That's a rare gift, child. Most people are too busy preparing their next words to truly hear what's being said.",
			"continues": true,
			"options": []
		}