extends NPC
class_name VillageElder

func _ready():
	setup_conversation_tree()

func setup_conversation_tree():
	npc_name = "Village Elder"
	dialogue_state = {
		"met_before": false,
		"shared_worry": false,
		"trust_built": false,
		"library_mentioned": false,
		"granddaughter_mentioned": false
	}

	if global_state:
		global_state.add_story_connection("library_loss", ["elder_library_worry"], ["Baker", "Librarian"])
		global_state.add_story_connection("forgotten_stories", ["elder_library_worry", "baker_lost_recipes"], ["Storyteller"])

	conversation_tree = {
		"branches": {
			"first_meeting": {
				"conditions": func(): return not dialogue_state.met_before,
				"entry_text": "Oh, hello there... I don't think I've seen you around here before. You have such a quiet presence about you...",
				"say_nothing": {
					"response": "Ah... you're one of those quiet ones, aren't you? That's refreshing. People these days, always rushing to fill every silence with chatter. But you... you understand the value of simply being present.",
					"trust_change": 2,
					"unlocks": ["met_before"],
					"continues": true,
					"emotional_beat": "appreciation",
					"next_branch": "comfortable_silence"
				},
				"nod": {
					"response": "Yes, I can see in your eyes that you're listening. Really listening. That's become so rare...",
					"trust_change": 1,
					"unlocks": ["met_before"],
					"continues": true,
					"emotional_beat": "recognition"
				},
				"ask_why": {
					"response": "Why? Well... I suppose it's because you remind me of my granddaughter. She used to listen like that too, before... well, before she moved to the city.",
					"trust_change": 0,
					"unlocks": ["met_before", "granddaughter_mentioned"],
					"continues": false,
					"type": DeadEndType.GENTLE_DEFLECTION,
					"emotional_beat": "nostalgia"
				},
				"repeat_back": {
					"response": "Yes... 'such a quiet presence.' You're reflecting my words back to me like a gentle mirror. That's a rare gift, child.",
					"trust_change": 3,
					"unlocks": ["met_before"],
					"continues": true,
					"emotional_beat": "understanding"
				}
			},
			"library_worry": {
				"conditions": func(): return dialogue_state.met_before and trust_level >= 3 and not dialogue_state.shared_worry,
				"entry_text": "You know, I've been thinking about what happened to the old library. Nobody talks about it anymore, but I remember...",
				"say_nothing": {
					"response": "Three years it's been since the fire. Three years, and it's like everyone just... forgot. But libraries aren't just buildings, you know? They're memory keepers.",
					"trust_change": 1,
					"continues": true,
					"emotional_beat": "melancholy"
				},
				"nod": {
					"response": "Yes, you understand. The library burned down three years ago, but that's not the real tragedy. The real tragedy is how quickly everyone forgot what we lost. All those stories... all that history...",
					"trust_change": 2,
					"unlocks": ["shared_worry", "library_mentioned"],
					"knowledge_gained": ["elder_library_worry"],
					"continues": true,
					"emotional_beat": "grief"
				},
				"ask_why": {
					"response": "Why does it matter? Because stories are how we remember who we are. Without them, we're just... existing. Not really living.",
					"trust_change": 1,
					"continues": false,
					"type": DeadEndType.PROTECTIVE_BOUNDARY,
					"emotional_beat": "protective"
				},
				"repeat_back": {
					"response": "'All those stories, all that history...' Yes, exactly. You see it too, don't you? The weight of what we've lost. No one else seems to care, but you... you truly hear me.",
					"trust_change": 3,
					"unlocks": ["shared_worry", "trust_built", "library_mentioned"],
					"knowledge_gained": ["elder_library_worry", "elder_understands_loss"],
					"continues": false,
					"type": DeadEndType.BREAKTHROUGH_MOMENT,
					"emotional_beat": "catharsis"
				}
			},
			"deep_trust": {
				"conditions": func(): return dialogue_state.trust_built and trust_level >= 7,
				"entry_text": "There's something comforting about your presence, child. Like you actually listen...",
				"say_nothing": {
					"response": "Sometimes I feel like I'm the only one who remembers the old stories. But with you here... maybe they won't be completely forgotten.",
					"trust_change": 1,
					"continues": false,
					"type": DeadEndType.COMFORTABLE_CONCLUSION
				},
				"nod": {
					"response": "You've given me something precious - the feeling of being truly heard. That's worth more than all the books in that old library.",
					"trust_change": 2,
					"continues": false,
					"type": DeadEndType.BREAKTHROUGH_MOMENT
				},
				"repeat_back": {
					"response": "Yes... 'actually listen.' That's exactly what you do. In a world of noise, you offer the gift of silence and attention.",
					"trust_change": 1,
					"continues": false,
					"type": DeadEndType.BREAKTHROUGH_MOMENT
				}
			},
			"cross_npc_connection": {
				"conditions": func(): return global_state and global_state.player_knows("baker_lost_recipes") and dialogue_state.shared_worry,
				"entry_text": "I see you've been talking to Martha at the bakery...",
				"say_nothing": {
					"response": "She's struggling without her grandmother's recipes, isn't she? Just like we all struggle without the library's stories. Loss has a way of connecting us all.",
					"trust_change": 2,
					"knowledge_gained": ["elder_sees_connections"],
					"continues": false,
					"type": DeadEndType.BREAKTHROUGH_MOMENT
				},
				"nod": {
					"response": "Yes, you see it too. We're all grieving different losses, but grief is grief. Maybe that's why you understand us so well.",
					"trust_change": 1,
					"continues": false,
					"type": DeadEndType.COMFORTABLE_CONCLUSION
				}
			}
		}
	}

func get_current_dialogue() -> String:
	var current_branch = get_current_branch()
	if current_branch.has("entry_text"):
		return current_branch.entry_text

	if not dialogue_state.met_before:
		return "Oh, hello there... I don't think I've seen you around here before. You have such a quiet presence about you..."
	elif not dialogue_state.shared_worry:
		return "You know, I've been thinking about what happened to the old library. Nobody talks about it anymore, but I remember..."
	else:
		return "There's something comforting about your presence, child. Like you actually listen..."