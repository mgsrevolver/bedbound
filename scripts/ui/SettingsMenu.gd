extends Control
class_name SettingsMenu

signal settings_closed

@onready var background_panel: Panel = $BackgroundPanel
@onready var title_label: Label = $Title
@onready var settings_container: VBoxContainer = $SettingsContainer
@onready var close_button: Button = $CloseButton

# Settings values
var text_speed: float = 0.03  # Seconds per character
var dialogue_text_size: int = 18
var ui_scale: float = 1.0
var high_contrast_mode: bool = false
var show_debug_overlay: bool = false
var enable_audio: bool = true

# UI elements
var text_speed_slider: HSlider
var text_size_slider: HSlider
var ui_scale_slider: HSlider
var contrast_check: CheckBox
var debug_check: CheckBox
var audio_check: CheckBox

func _ready():
	close_button.pressed.connect(_on_close_pressed)
	load_settings()
	build_settings_ui()

func build_settings_ui():
	"""Create all settings controls"""
	# Clear existing
	for child in settings_container.get_children():
		child.queue_free()

	# === TEXT SPEED ===
	var speed_label = Label.new()
	speed_label.text = "Text Speed"
	speed_label.add_theme_font_size_override("font_size", 18)
	settings_container.add_child(speed_label)

	var speed_container = HBoxContainer.new()
	settings_container.add_child(speed_container)

	text_speed_slider = HSlider.new()
	text_speed_slider.min_value = 0.01
	text_speed_slider.max_value = 0.1
	text_speed_slider.step = 0.01
	text_speed_slider.value = text_speed
	text_speed_slider.custom_minimum_size = Vector2(300, 30)
	text_speed_slider.value_changed.connect(_on_text_speed_changed)
	speed_container.add_child(text_speed_slider)

	var speed_value_label = Label.new()
	speed_value_label.text = get_speed_description(text_speed)
	speed_value_label.custom_minimum_size = Vector2(100, 30)
	speed_container.add_child(speed_value_label)
	text_speed_slider.set_meta("value_label", speed_value_label)

	add_spacer()

	# === TEXT SIZE ===
	var size_label = Label.new()
	size_label.text = "Dialogue Text Size"
	size_label.add_theme_font_size_override("font_size", 18)
	settings_container.add_child(size_label)

	var size_container = HBoxContainer.new()
	settings_container.add_child(size_container)

	text_size_slider = HSlider.new()
	text_size_slider.min_value = 14
	text_size_slider.max_value = 28
	text_size_slider.step = 2
	text_size_slider.value = dialogue_text_size
	text_size_slider.custom_minimum_size = Vector2(300, 30)
	text_size_slider.value_changed.connect(_on_text_size_changed)
	size_container.add_child(text_size_slider)

	var size_value_label = Label.new()
	size_value_label.text = str(dialogue_text_size) + "px"
	size_value_label.custom_minimum_size = Vector2(100, 30)
	size_container.add_child(size_value_label)
	text_size_slider.set_meta("value_label", size_value_label)

	add_spacer()

	# === UI SCALE ===
	var scale_label = Label.new()
	scale_label.text = "UI Scale (requires restart)"
	scale_label.add_theme_font_size_override("font_size", 18)
	settings_container.add_child(scale_label)

	var scale_container = HBoxContainer.new()
	settings_container.add_child(scale_container)

	ui_scale_slider = HSlider.new()
	ui_scale_slider.min_value = 0.8
	ui_scale_slider.max_value = 1.5
	ui_scale_slider.step = 0.1
	ui_scale_slider.value = ui_scale
	ui_scale_slider.custom_minimum_size = Vector2(300, 30)
	ui_scale_slider.value_changed.connect(_on_ui_scale_changed)
	scale_container.add_child(ui_scale_slider)

	var scale_value_label = Label.new()
	scale_value_label.text = str(int(ui_scale * 100)) + "%"
	scale_value_label.custom_minimum_size = Vector2(100, 30)
	scale_container.add_child(scale_value_label)
	ui_scale_slider.set_meta("value_label", scale_value_label)

	add_spacer()

	# === HIGH CONTRAST MODE ===
	var contrast_container = HBoxContainer.new()
	settings_container.add_child(contrast_container)

	contrast_check = CheckBox.new()
	contrast_check.button_pressed = high_contrast_mode
	contrast_check.toggled.connect(_on_contrast_toggled)
	contrast_container.add_child(contrast_check)

	var contrast_label = Label.new()
	contrast_label.text = "High Contrast Mode (for visibility)"
	contrast_label.add_theme_font_size_override("font_size", 16)
	contrast_container.add_child(contrast_label)

	add_spacer()

	# === DEBUG OVERLAY ===
	var debug_container = HBoxContainer.new()
	settings_container.add_child(debug_container)

	debug_check = CheckBox.new()
	debug_check.button_pressed = show_debug_overlay
	debug_check.toggled.connect(_on_debug_toggled)
	debug_container.add_child(debug_check)

	var debug_label = Label.new()
	debug_label.text = "Show Debug Overlay"
	debug_label.add_theme_font_size_override("font_size", 16)
	debug_container.add_child(debug_label)

	add_spacer()

	# === AUDIO ===
	var audio_container = HBoxContainer.new()
	settings_container.add_child(audio_container)

	audio_check = CheckBox.new()
	audio_check.button_pressed = enable_audio
	audio_check.toggled.connect(_on_audio_toggled)
	audio_container.add_child(audio_check)

	var audio_label = Label.new()
	audio_label.text = "Enable Audio Feedback"
	audio_label.add_theme_font_size_override("font_size", 16)
	audio_container.add_child(audio_label)

	add_spacer()
	add_spacer()

	# === RESET TO DEFAULTS ===
	var reset_button = Button.new()
	reset_button.text = "Reset to Defaults"
	reset_button.custom_minimum_size = Vector2(200, 40)
	reset_button.pressed.connect(_on_reset_pressed)
	settings_container.add_child(reset_button)

func add_spacer():
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	settings_container.add_child(spacer)

func get_speed_description(speed: float) -> String:
	if speed <= 0.02:
		return "Very Fast"
	elif speed <= 0.04:
		return "Fast"
	elif speed <= 0.06:
		return "Normal"
	elif speed <= 0.08:
		return "Slow"
	else:
		return "Very Slow"

func _on_text_speed_changed(value: float):
	text_speed = value
	var label = text_speed_slider.get_meta("value_label")
	if label:
		label.text = get_speed_description(value)
	save_settings()

func _on_text_size_changed(value: float):
	dialogue_text_size = int(value)
	var label = text_size_slider.get_meta("value_label")
	if label:
		label.text = str(dialogue_text_size) + "px"
	save_settings()

func _on_ui_scale_changed(value: float):
	ui_scale = value
	var label = ui_scale_slider.get_meta("value_label")
	if label:
		label.text = str(int(ui_scale * 100)) + "%"
	save_settings()

func _on_contrast_toggled(toggled_on: bool):
	high_contrast_mode = toggled_on
	apply_contrast_mode()
	save_settings()

func _on_debug_toggled(toggled_on: bool):
	show_debug_overlay = toggled_on
	save_settings()

func _on_audio_toggled(toggled_on: bool):
	enable_audio = toggled_on
	save_settings()

func _on_reset_pressed():
	text_speed = 0.03
	dialogue_text_size = 18
	ui_scale = 1.0
	high_contrast_mode = false
	show_debug_overlay = false
	enable_audio = true
	save_settings()
	build_settings_ui()

func apply_contrast_mode():
	"""Apply high contrast theme if enabled"""
	if high_contrast_mode:
		# Make UI elements more visible
		# This would be expanded to affect all UI
		pass

func save_settings():
	"""Save settings to file"""
	var config = ConfigFile.new()
	config.set_value("display", "text_speed", text_speed)
	config.set_value("display", "dialogue_text_size", dialogue_text_size)
	config.set_value("display", "ui_scale", ui_scale)
	config.set_value("display", "high_contrast_mode", high_contrast_mode)
	config.set_value("display", "show_debug_overlay", show_debug_overlay)
	config.set_value("audio", "enable_audio", enable_audio)
	config.save("user://settings.cfg")

func load_settings():
	"""Load settings from file"""
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err != OK:
		return  # Use defaults

	text_speed = config.get_value("display", "text_speed", 0.03)
	dialogue_text_size = config.get_value("display", "dialogue_text_size", 18)
	ui_scale = config.get_value("display", "ui_scale", 1.0)
	high_contrast_mode = config.get_value("display", "high_contrast_mode", false)
	show_debug_overlay = config.get_value("display", "show_debug_overlay", false)
	enable_audio = config.get_value("audio", "enable_audio", true)

# Getters for other systems to access settings
func get_text_speed() -> float:
	return text_speed

func get_dialogue_text_size() -> int:
	return dialogue_text_size

func is_high_contrast() -> bool:
	return high_contrast_mode

func is_debug_enabled() -> bool:
	return show_debug_overlay

func is_audio_enabled() -> bool:
	return enable_audio

func _on_close_pressed():
	settings_closed.emit()
	queue_free()

func _input(event):
	if event.is_action_pressed("ui_cancel"):  # ESC key
		_on_close_pressed()
		accept_event()