class_name DialogueLoader
extends Node

static func load_dialogue_from_json(file_path: String) -> DialogueData:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("Failed to open dialogue file: " + file_path)
		return null

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		push_error("Failed to parse dialogue JSON: " + json.get_error_message())
		return null

	var data = json.data
	var dialogue_data = DialogueData.new()

	dialogue_data.dialogue_id = data.get("id", "")
	dialogue_data.npc_name = data.get("npc_name", "")
	dialogue_data.conversation_tree = data.get("conversation_tree", {})
	dialogue_data.author = data.get("author", "")
	dialogue_data.version = data.get("version", "1.0")
	dialogue_data.tags = data.get("tags", [])

	return dialogue_data

static func save_dialogue_to_json(dialogue_data: DialogueData, file_path: String) -> bool:
	var data = {
		"id": dialogue_data.dialogue_id,
		"npc_name": dialogue_data.npc_name,
		"conversation_tree": dialogue_data.conversation_tree,
		"author": dialogue_data.author,
		"version": dialogue_data.version,
		"tags": dialogue_data.tags
	}

	var json = JSON.new()
	var json_string = json.stringify(data, "\t")

	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		push_error("Failed to open file for writing: " + file_path)
		return false

	file.store_string(json_string)
	file.close()
	return true

static func create_sample_dialogue(npc_name: String) -> Dictionary:
	return {
		"id": npc_name.to_lower() + "_dialogue",
		"npc_name": npc_name,
		"conversation_tree": {
			"level_1": {
				"text": "Hello there, I'm %s. It's nice to meet you." % npc_name,
				"branches": {
					"wait": {
						"text": "Oh, you're the quiet type? That's refreshing actually...",
						"trust_change": 1,
						"level_3": {
							"wait": {
								"text": "Your silence speaks volumes. I feel like I can trust you.",
								"trust_change": 2
							},
							"acknowledge": {
								"text": "Thank you for understanding. Not many people do.",
								"trust_change": 1
							},
							"clarify": {
								"text": "It's hard to explain... maybe another time.",
								"trust_change": 0
							},
							"reflect": {
								"text": "Yes, exactly! You really get it.",
								"trust_change": 2
							}
						}
					},
					"acknowledge": {
						"text": "I appreciate that. It's been a while since someone really listened.",
						"trust_change": 1,
						"level_3": {
							"wait": {
								"text": "Sometimes the best conversations happen in comfortable silence.",
								"trust_change": 1
							},
							"acknowledge": {
								"text": "We seem to be on the same wavelength.",
								"trust_change": 1
							},
							"clarify": {
								"text": "Well, it's complicated... where do I even begin?",
								"trust_change": 0
							},
							"reflect": {
								"text": "You have a way of making people feel heard.",
								"trust_change": 2
							}
						}
					},
					"clarify": {
						"text": "You want to know more? I suppose I could share a bit...",
						"trust_change": 0,
						"level_3": {
							"wait": {
								"text": "Taking your time to think about it? I respect that.",
								"trust_change": 1
							},
							"acknowledge": {
								"text": "I'm glad you're following along.",
								"trust_change": 1
							},
							"clarify": {
								"text": "There's so much more to the story, but...",
								"trust_change": 0
							},
							"reflect": {
								"text": "You really understand what I'm trying to say.",
								"trust_change": 1
							}
						}
					},
					"reflect": {
						"text": "You echo my words back... it's like looking in a mirror.",
						"trust_change": 2,
						"level_3": {
							"wait": {
								"text": "Your patient presence is a gift.",
								"trust_change": 2
							},
							"acknowledge": {
								"text": "I feel truly seen by you.",
								"trust_change": 2
							},
							"clarify": {
								"text": "You want to dig deeper? I admire your curiosity.",
								"trust_change": 1
							},
							"reflect": {
								"text": "This connection we have... it's special.",
								"trust_change": 3
							}
						}
					}
				}
			},
			"exhausted_response": "We've covered so much ground already. Let me process everything we've discussed."
		},
		"author": "System",
		"version": "1.0",
		"tags": ["introductory", "trust_building"]
	}