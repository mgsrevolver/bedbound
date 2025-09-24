extends Control
class_name ConversationWheel

signal option_selected(option: DialogueManager.DialogueOption)
signal conversation_finished
signal conversation_left

@onready var dialogue_text: RichTextLabel = $DialoguePanel/DialogueText
@onready var dialogue_panel: Panel = $DialoguePanel
@onready var wheel_container: Control = $WheelContainer
@onready var segment_container: Control = $WheelContainer/SegmentContainer
@onready var center_point: Control = $WheelContainer/CenterPoint
@onready var selection_indicator: Control = $SelectionIndicator
var progress_indicator: Label
var leave_button: Button
var npc_portrait: Control
var npc_portrait_sprite: Sprite2D
var npc_name_label: Label
var animation_tween: Tween

# Wheel configuration
const WHEEL_RADIUS = 120.0
const CENTER_RADIUS = 40.0  # Touch area in center for spinning
const SEGMENT_ANGLE = 90.0  # 360 / 4 base options
const SPIN_THRESHOLD = 100.0  # Minimum drag distance to trigger spin
const MOMENTUM_DECAY = 0.95

# Touch state
var is_touching = false
var touch_start_pos: Vector2
var last_touch_pos: Vector2
var current_angle = 0.0
var target_angle = 0.0
var spin_velocity = 0.0
var selected_option = DialogueManager.DialogueOption.WAIT

# Option configuration
var base_options = [
	{"option": DialogueManager.DialogueOption.WAIT, "label": "Wait", "angle": 0},
	{"option": DialogueManager.DialogueOption.ACKNOWLEDGE, "label": "Acknowledge", "angle": 90},
	{"option": DialogueManager.DialogueOption.CLARIFY, "label": "Clarify", "angle": 180},
	{"option": DialogueManager.DialogueOption.REFLECT, "label": "Repeat Back", "angle": 270}
]

var option_segments = []
var trust_level = 0
var current_available_options: Array[String] = []
var conversation_level = 1
var level_2_choice = ""

func _ready():
	print("ConversationWheel: _ready() called")
	add_to_group("dialogue_ui")
	setup_styling()
	setup_wheel()
	setup_touch_input()

func setup_styling():
	# Style the dialogue panel similar to original
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	dialogue_panel.add_theme_stylebox_override("panel", panel_style)

	# Create progress indicator
	progress_indicator = Label.new()
	progress_indicator.name = "ProgressIndicator"
	progress_indicator.add_theme_font_size_override("font_size", 14)
	progress_indicator.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	progress_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_indicator.size = Vector2(300, 30)
	var screen_size = get_viewport().get_visible_rect().size
	progress_indicator.position = Vector2(screen_size.x * 0.5 - 150, 20)
	add_child(progress_indicator)

	# Create Leave button in bottom area
	leave_button = Button.new()
	leave_button.name = "LeaveButton"
	leave_button.text = "Leave"
	leave_button.custom_minimum_size = Vector2(80, 40)
	leave_button.add_theme_font_size_override("font_size", 14)
	leave_button.position = Vector2(screen_size.x - 100, screen_size.y - 60)
	leave_button.pressed.connect(_on_leave_pressed)
	add_child(leave_button)

	# Create NPC portrait in upper middle area (after debug panel)
	npc_portrait = Control.new()
	npc_portrait.name = "NPCPortrait"
	npc_portrait.position = Vector2(screen_size.x * 0.5, 120)  # Fixed position below debug panel
	add_child(npc_portrait)

	# Create portrait sprite (will be updated when NPC is set)
	npc_portrait_sprite = Sprite2D.new()
	npc_portrait_sprite.scale = Vector2(3, 3)  # Larger for portrait view
	npc_portrait.add_child(npc_portrait_sprite)

	# Create NPC name label
	npc_name_label = Label.new()
	npc_name_label.add_theme_font_size_override("font_size", 20)
	npc_name_label.add_theme_color_override("font_color", Color.WHITE)
	npc_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	npc_name_label.size = Vector2(200, 30)
	npc_name_label.position = Vector2(-100, 50)  # Below the sprite
	npc_portrait.add_child(npc_name_label)

func _input(event):
	if not visible:
		return

	# Handle touch input (mobile)
	if event is InputEventScreenTouch:
		handle_touch_input(event)
	elif event is InputEventScreenDrag:
		handle_drag_input(event)
	# Handle mouse input (desktop)
	elif event is InputEventMouseButton:
		handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		handle_mouse_motion(event)

func _process(delta):
	if spin_velocity != 0 and not is_touching:
		# Apply momentum-based rotation
		current_angle += spin_velocity * delta * 60
		spin_velocity *= MOMENTUM_DECAY

		if abs(spin_velocity) < 0.1:
			spin_velocity = 0
			snap_to_nearest_option()
		else:
			update_wheel_rotation()
			update_selection_indicator()

func setup_wheel():
	# Set up the wheel at the bottom, with proper spacing
	var screen_size = get_viewport().get_visible_rect().size
	# Position wheel at bottom with margin for leave button
	var wheel_center = Vector2(screen_size.x * 0.5, screen_size.y - 200)  # 200px from bottom

	wheel_container.position = wheel_center
	selection_indicator.position = wheel_center

	create_option_segments()
	update_wheel_rotation()
	update_selection_indicator()

func create_option_segments():
	# Clear existing segments
	for child in segment_container.get_children():
		child.queue_free()
	option_segments.clear()

	# Create base 4 options
	for option_data in base_options:
		var segment = create_option_segment(option_data)
		option_segments.append(segment)

	# Add probe option if trust level is high enough
	if trust_level >= 3:  # Arbitrary trust threshold
		var probe_data = {"option": DialogueManager.DialogueOption.PROBE, "label": "Probe", "angle": 45}  # Between Wait and Acknowledge
		var probe_segment = create_option_segment(probe_data)
		probe_segment.modulate = Color(1, 1, 0.7)  # Slightly different color
		option_segments.append(probe_segment)

func create_option_segment(option_data: Dictionary) -> Control:
	var segment = Control.new()
	segment.name = option_data.label + "Segment"
	segment_container.add_child(segment)

	# Calculate position on circumference
	var angle_rad = deg_to_rad(option_data.angle)
	var pos = Vector2(cos(angle_rad), sin(angle_rad)) * WHEEL_RADIUS
	segment.position = pos

	# Create label
	var label = Label.new()
	label.text = option_data.label
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = Vector2(100, 40)
	label.position = Vector2(-50, -20)  # Center the label
	segment.add_child(label)

	# Store option data
	segment.set_meta("option_data", option_data)

	return segment

func setup_touch_input():
	# Make the entire wheel responsive to touch
	mouse_filter = Control.MOUSE_FILTER_PASS

func handle_touch_input(event: InputEventScreenTouch):
	var wheel_center = wheel_container.global_position
	var wheel_local = event.position - wheel_center

	if event.pressed:
		is_touching = true
		touch_start_pos = event.position
		last_touch_pos = event.position
		spin_velocity = 0  # Stop any current momentum

		# Check if touch is in center (for spinning) or on edge (for direct selection)
		if wheel_local.length() <= CENTER_RADIUS:
			# Center touch - prepare for spin gesture
			pass
		else:
			# Edge touch - direct selection
			select_option_at_position(wheel_local)
	else:
		# Touch released
		if is_touching:
			var drag_distance = (event.position - touch_start_pos).length()

			if drag_distance < 20:  # Tap threshold
				# This was a tap, confirm current selection
				confirm_selection()
			else:
				# This was a drag, apply momentum or snap to selection
				var drag_delta = event.position - last_touch_pos
				if wheel_local.length() <= CENTER_RADIUS and drag_distance > SPIN_THRESHOLD:
					# Apply spin momentum
					var angle_delta = calculate_angle_delta(last_touch_pos, event.position)
					spin_velocity = angle_delta * 10  # Scale for nice feel
				else:
					# Snap to nearest option
					snap_to_nearest_option()

		is_touching = false

func handle_drag_input(event: InputEventScreenDrag):
	if not is_touching:
		return

	var wheel_center = wheel_container.global_position
	var wheel_local = event.position - wheel_center

	if wheel_local.length() <= CENTER_RADIUS:
		# Spinning gesture in center
		var angle_delta = calculate_angle_delta(last_touch_pos, event.position)
		current_angle += angle_delta
		update_wheel_rotation()
		update_selection_indicator()
	else:
		# Direct selection on wheel edge
		select_option_at_position(wheel_local)

	last_touch_pos = event.position

func handle_mouse_button(event: InputEventMouseButton):
	print("ConversationWheel: Mouse button event: ", event.button_index, " pressed: ", event.pressed)
	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	var wheel_center = wheel_container.global_position
	var wheel_local = event.position - wheel_center
	print("ConversationWheel: Wheel center: ", wheel_center, " Local: ", wheel_local, " Distance: ", wheel_local.length())

	if event.pressed:
		is_touching = true
		touch_start_pos = event.position
		last_touch_pos = event.position
		spin_velocity = 0  # Stop any current momentum

		# Check if click is in center (for spinning) or on edge (for direct selection)
		if wheel_local.length() <= CENTER_RADIUS:
			# Center click - prepare for spin gesture
			pass
		else:
			# Edge click - direct selection
			select_option_at_position(wheel_local)
	else:
		# Mouse released
		if is_touching:
			var drag_distance = (event.position - touch_start_pos).length()

			if drag_distance < 20:  # Click threshold
				# This was a click, confirm current selection
				confirm_selection()
			else:
				# This was a drag, apply momentum or snap to selection
				var drag_delta = event.position - last_touch_pos
				if wheel_local.length() <= CENTER_RADIUS and drag_distance > SPIN_THRESHOLD:
					# Apply spin momentum
					var angle_delta = calculate_angle_delta(last_touch_pos, event.position)
					spin_velocity = angle_delta * 10  # Scale for nice feel
				else:
					# Snap to nearest option
					snap_to_nearest_option()

		is_touching = false

func handle_mouse_motion(event: InputEventMouseMotion):
	if not is_touching:
		return

	var wheel_center = wheel_container.global_position
	var wheel_local = event.position - wheel_center

	if wheel_local.length() <= CENTER_RADIUS:
		# Spinning gesture in center
		var angle_delta = calculate_angle_delta(last_touch_pos, event.position)
		current_angle += angle_delta
		update_wheel_rotation()
		update_selection_indicator()
	else:
		# Direct selection on wheel edge
		select_option_at_position(wheel_local)

	last_touch_pos = event.position

func calculate_angle_delta(from_pos: Vector2, to_pos: Vector2) -> float:
	var center = wheel_container.global_position
	var from_angle = (from_pos - center).angle()
	var to_angle = (to_pos - center).angle()
	var delta = to_angle - from_angle

	# Normalize to -PI to PI range
	while delta > PI:
		delta -= 2 * PI
	while delta < -PI:
		delta += 2 * PI

	return rad_to_deg(delta)

func select_option_at_position(wheel_local: Vector2):
	var angle = rad_to_deg(wheel_local.angle())

	# Normalize angle to 0-360
	while angle < 0:
		angle += 360
	while angle >= 360:
		angle -= 360

	# Find nearest option from currently visible segments
	if option_segments.is_empty():
		return

	var nearest_segment = option_segments[0]
	var min_distance = 999999

	# Check all currently visible segments
	for segment in option_segments:
		if segment and segment.has_meta("option_data"):
			var option_data = segment.get_meta("option_data")
			var distance = abs(angle_difference(angle, option_data.angle))
			if distance < min_distance:
				min_distance = distance
				nearest_segment = segment

	# Update selection based on nearest segment
	if nearest_segment and nearest_segment.has_meta("option_data"):
		var option_data = nearest_segment.get_meta("option_data")
		selected_option = option_data.option
		target_angle = option_data.angle

		# Smoothly rotate to target
		if animation_tween:
			animation_tween.kill()
		animation_tween = create_tween()
		animation_tween.tween_method(set_wheel_angle, current_angle, target_angle, 0.3)

func snap_to_nearest_option():
	# Find the nearest option to current angle
	var normalized_angle = fmod(current_angle + 360, 360)

	# Use currently visible segments instead of base options
	if option_segments.is_empty():
		return

	var nearest_segment = option_segments[0]
	var min_distance = 999999

	# Check all currently visible segments
	for segment in option_segments:
		if segment and segment.has_meta("option_data"):
			var option_data = segment.get_meta("option_data")
			var distance = abs(angle_difference(normalized_angle, option_data.angle))
			if distance < min_distance:
				min_distance = distance
				nearest_segment = segment

	# Update selection based on nearest segment
	if nearest_segment and nearest_segment.has_meta("option_data"):
		var option_data = nearest_segment.get_meta("option_data")
		selected_option = option_data.option
		target_angle = option_data.angle

		# Smooth snap animation
		if animation_tween:
			animation_tween.kill()
		animation_tween = create_tween()
		animation_tween.tween_method(set_wheel_angle, current_angle, target_angle, 0.4)

func angle_difference(a1: float, a2: float) -> float:
	var diff = a1 - a2
	while diff > 180:
		diff -= 360
	while diff < -180:
		diff += 360
	return diff

func set_wheel_angle(angle: float):
	current_angle = angle
	update_wheel_rotation()
	update_selection_indicator()

func update_wheel_rotation():
	if wheel_container:
		wheel_container.rotation_degrees = current_angle
		# Keep all labels upright and readable
		for segment in option_segments:
			if segment:
				segment.rotation_degrees = -current_angle

func update_selection_indicator():
	# Highlight the currently selected option
	for i in range(option_segments.size()):
		var segment = option_segments[i]
		var option_data = segment.get_meta("option_data")

		if option_data.option == selected_option:
			segment.modulate = Color(1.2, 1.2, 0.8)  # Brighter/yellow tint
			segment.scale = Vector2(1.1, 1.1)
		else:
			segment.modulate = Color.WHITE
			segment.scale = Vector2(1.0, 1.0)

func confirm_selection():
	print("ConversationWheel: Confirming selection: ", selected_option)
	# Only emit if we're not in an ended state
	if mouse_filter != Control.MOUSE_FILTER_IGNORE:
		option_selected.emit(selected_option)
	else:
		print("ConversationWheel: Input ignored - conversation ended")

func setup_dialogue(text: String):
	print("ConversationWheel: setup_dialogue called with: ", text)
	dialogue_text.text = text
	reset_wheel_position()
	update_progress_indicator()

func setup_npc_portrait(npc: NPC):
	if npc and npc_name_label:
		npc_name_label.text = npc.npc_name
		# Copy the NPC's sprite texture for the portrait
		var npc_sprite = npc.get_node("Sprite2D")
		if npc_sprite and npc_portrait_sprite:
			npc_portrait_sprite.texture = npc_sprite.texture

func update_dialogue(text: String, available_options: Array = []):
	dialogue_text.text = text
	# Reset wheel to default position for new conversation turn
	reset_wheel_position()
	# Update wheel with new options if provided
	if not available_options.is_empty():
		update_available_options(available_options)
	else:
		# Show all base options if none specified
		create_option_segments()
	update_progress_indicator()

func show_conversation_end(npc_name: String, trust_change: int, total_trust: int, dead_end_type: String = "", farewell_message: String = "", dead_end_type_enum = null):
	print("ConversationWheel: show_conversation_end called")
	# Hide the wheel during conversation end and disable input
	wheel_container.visible = false
	selection_indicator.visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # Disable all input

	# Show farewell message first if available
	if farewell_message != "":
		dialogue_text.text = "[i]%s[/i]\n\n\"%s\"" % [npc_name, farewell_message]

		# Create a timer to show the summary after farewell
		var timer = Timer.new()
		add_child(timer)
		timer.wait_time = 2.5
		timer.one_shot = true
		timer.timeout.connect(func():
			show_conversation_summary(npc_name, trust_change, total_trust, dead_end_type, dead_end_type_enum)
			timer.queue_free()
		)
		timer.start()

		# Start NPC departure animation after a short delay
		var departure_timer = Timer.new()
		add_child(departure_timer)
		departure_timer.wait_time = 1.0
		departure_timer.one_shot = true
		departure_timer.timeout.connect(func():
			var dialogue_manager = get_tree().get_first_node_in_group("dialogue_manager")
			if dialogue_manager and dialogue_manager.current_npc:
				dialogue_manager.current_npc.play_farewell_animation(dead_end_type_enum if dead_end_type_enum != null else NPC.DeadEndType.COMFORTABLE_CONCLUSION)
			departure_timer.queue_free()
		)
		departure_timer.start()
	else:
		show_conversation_summary(npc_name, trust_change, total_trust, dead_end_type, dead_end_type_enum)

func show_conversation_summary(npc_name: String, trust_change: int, total_trust: int, dead_end_type: String = "", dead_end_type_enum = null):
	var end_message = "Conversation with %s ended." % npc_name
	var trust_message = ""

	if trust_change > 0:
		trust_message = "\n[color=green]Trust gained: +%d[/color]" % trust_change
	elif trust_change < 0:
		trust_message = "\n[color=red]Trust lost: %d[/color]" % trust_change

	var trust_level_message = "\n[color=yellow]Total Trust: %d[/color]" % total_trust

	var type_message = ""
	if dead_end_type != "":
		match dead_end_type:
			"BREAKTHROUGH_MOMENT":
				type_message = "\n[color=cyan]✨ Breakthrough moment[/color]"
			"COMFORTABLE_CONCLUSION":
				type_message = "\n[color=lightblue]😌 Comfortable ending[/color]"
			"GENTLE_DEFLECTION":
				type_message = "\n[color=gray]🤐 They deflected gently[/color]"
			"PROTECTIVE_BOUNDARY":
				type_message = "\n[color=orange]🛡️ They set a boundary[/color]"
			"TRUST_INSUFFICIENT":
				type_message = "\n[color=red]⚠️ Need more trust[/color]"

	dialogue_text.text = end_message + trust_message + trust_level_message + type_message

	# Show continue button in center where wheel was
	var continue_button = Button.new()
	continue_button.text = "Continue"
	continue_button.custom_minimum_size = Vector2(150, 60)
	continue_button.add_theme_font_size_override("font_size", 18)

	# Position continue button where wheel was
	var screen_size = get_viewport().get_visible_rect().size
	var center_pos = Vector2(screen_size.x * 0.5, screen_size.y - 200)  # Same as wheel position
	continue_button.position = center_pos - continue_button.custom_minimum_size * 0.5

	continue_button.pressed.connect(func():
		continue_button.queue_free()
		conversation_finished.emit()
	)
	add_child(continue_button)

func reset_wheel_position():
	# Reset wheel to default position and stop any momentum
	current_angle = 0.0
	target_angle = 0.0
	spin_velocity = 0.0
	selected_option = DialogueManager.DialogueOption.WAIT

	# Stop any running animation
	if animation_tween:
		animation_tween.kill()

	# Update visual state
	update_wheel_rotation()
	update_selection_indicator()

func set_trust_level(level: int):
	trust_level = level
	create_option_segments()  # Recreate segments to add/remove probe option

func update_available_options(available_options: Array):
	# Convert array of strings to our format and filter segments
	current_available_options.clear()
	for option in available_options:
		if option is String:
			current_available_options.append(option)

	print("ConversationWheel: Available options updated to: ", current_available_options)
	create_option_segments_filtered()

func create_option_segments_filtered():
	# Clear existing segments
	for child in segment_container.get_children():
		child.queue_free()
	option_segments.clear()

	if current_available_options.is_empty():
		# Hide wheel entirely when no options available
		wheel_container.visible = false
		selection_indicator.visible = false
		print("ConversationWheel: No options available - hiding wheel")
		return
	else:
		# Show wheel when options are available
		wheel_container.visible = true
		selection_indicator.visible = true

	var angle_step = 360.0 / current_available_options.size()
	var current_angle = 0.0

	# Create segments only for available options
	for option_str in current_available_options:
		var option_data = get_option_data_from_string(option_str)
		if option_data:
			# Update angle to distribute evenly
			option_data["angle"] = current_angle
			var segment = create_option_segment(option_data)
			option_segments.append(segment)
			current_angle += angle_step

func get_option_data_from_string(option_str: String) -> Dictionary:
	match option_str:
		"wait":
			return {"option": DialogueManager.DialogueOption.WAIT, "label": "Wait"}
		"acknowledge":
			return {"option": DialogueManager.DialogueOption.ACKNOWLEDGE, "label": "Acknowledge"}
		"clarify":
			return {"option": DialogueManager.DialogueOption.CLARIFY, "label": "Clarify"}
		"reflect":
			return {"option": DialogueManager.DialogueOption.REFLECT, "label": "Repeat Back"}
		"probe":
			return {"option": DialogueManager.DialogueOption.PROBE, "label": "Probe"}
		_:
			return {}

func update_conversation_state(level: int, choice: String = "", used_options: Array = []):
	conversation_level = level
	level_2_choice = choice
	print("ConversationWheel: State updated - Level: ", level, " Choice: ", choice, " Used options: ", used_options)
	update_progress_indicator()

func update_progress_indicator():
	if not progress_indicator:
		return

	var text = ""
	match conversation_level:
		1:
			text = "Initial Sharing - Listen and respond"
		2:
			text = "First Response - Choose your approach"
		3:
			var remaining = current_available_options.size()
			if level_2_choice != "":
				text = "Deep Listening (%s path) - %d options remaining" % [level_2_choice.capitalize(), remaining]
			else:
				text = "Deep Listening - %d options available" % remaining

	progress_indicator.text = text

func _on_leave_pressed():
	print("ConversationWheel: Leave button pressed")
	conversation_left.emit()