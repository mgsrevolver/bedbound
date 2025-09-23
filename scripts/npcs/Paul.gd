extends NPC
class_name Paul

func _ready():
	setup_conversation_tree()

func setup_conversation_tree():
	npc_name = "Paul"

	conversation_tree = {
		"level_1": {
			"text": "My divorce was finalized this morning. Twenty-three years of marriage, and it all came down to a ten-minute hearing where the judge asked if we'd tried counseling.",
			"branches": {
				"wait": {
					"text": "I walked past our old house on the way here. She's already changed the curtains.",
					"trust_change": 1,
					"level_3": {
						"wait": {
							"text": "The only moments of grace came when I was patient and waited for her to fill the air. Every time I opened my mouth, I was stunned by what came out. If only I could have been stunned into silence.",
							"trust_change": 1
						},
						"clarify": {
							"text": "The curtains? A sort of azure-blue, with planets. Which makes absolutely no sense. There are no visible planets in the daytime sky. Not around here. It makes my blood boil.",
							"trust_change": 0
						},
						"acknowledge": {
							"text": "It's remarkable, the lengths to which people will go to assert their independence.",
							"trust_change": 1
						},
						"reflect": {
							"text": "It must all sound so trivial, given what you've been through. I didn't mean to whine.",
							"trust_change": 2
						}
					}
				},
				"acknowledge": {
					"text": "I was in this fluorescent-lit room, and the judge refused to make eye contact. He spoke in a monotone voice for 10 minutes, signed the papers, and it was over.",
					"trust_change": 1,
					"level_3": {
						"acknowledge": {
							"text": "You've survived a lot. You could survive a divorce. You're made of tougher stuff than me.",
							"trust_change": 1
						},
						"clarify": {
							"text": "He asked me what I learned. I didn't learn anything. I already knew that I wasn't supposed to do that. So, maybe I learned not to do it again. But it's too late.",
							"trust_change": 0
						},
						"reflect": {
							"text": "It's over. I'm staying over at the Jolly Roger. It's habitable.",
							"trust_change": 1
						},
						"wait": {
							"text": "When we walked out, my ex-wife turned to me and said, \"I wish things could have been different.\" I'm just not sure what to make of that.",
							"trust_change": 2
						}
					}
				},
				"clarify": {
					"text": "When I woke up, there were three Post-it notes on the kitchen counter in handwriting that definitely wasn't mine – or hers. Something about yogurt.",
					"trust_change": 0,
					"level_3": {
						"wait": {
							"text": "Another man has been in my house – eating yogurt.",
							"trust_change": 0
						},
						"acknowledge": {
							"text": "You're a clever one. That's exactly right. It's definitive proof of infidelity.",
							"trust_change": 1
						},
						"reflect": {
							"text": "I have a lactose sensitivity. I don't eat yogurt.",
							"trust_change": 2
						},
						"clarify": {
							"text": "A Post-it note is like a, uh, Pokemon card. With glue on the back, and words on the front. Words – from the pen of another man.",
							"trust_change": 0
						}
					}
				},
				"reflect": {
					"text": "I have been giving her compliments. Every day.",
					"trust_change": 2,
					"level_3": {
						"reflect": {
							"text": "Yes, such as: \"I like the shoestring fries. The wedges and the steak fries do nothing for me.\"",
							"trust_change": 1
						},
						"acknowledge": {
							"text": "I am relentlessly positive. It makes her uncomfortable. I suppose the writing has been on the wall for some time now.",
							"trust_change": 1
						},
						"wait": {
							"text": "I just don't see the need for \"counseling\" when everything is going just fine.",
							"trust_change": 0
						},
						"clarify": {
							"text": "My father taught me about compliments. A compliment is \"when you look someone in the eye and tell them something that they need to hear.\" That's what he told me.",
							"trust_change": 2
						}
					}
				}
			}
		}
	}