extends Camera2D

const MIN_ZOOM = 0.5
const MAX_ZOOM = 3.0
const ZOOM_SPEED_WHEEL = 0.1
const ZOOM_SPEED_PINCH = 0.02
const SMOOTH_ZOOM_SPEED = 10.0

var target_zoom: Vector2 = Vector2(2, 2)
var initial_distance: float = 0.0
var initial_zoom: Vector2 = Vector2.ZERO
var touch_points: Dictionary = {}

func _ready():
	zoom = Vector2(2, 2)
	target_zoom = zoom

func _unhandled_input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_points[event.index] = event.position
		else:
			touch_points.erase(event.index)

		if touch_points.size() == 2:
			var touches = touch_points.values()
			initial_distance = touches[0].distance_to(touches[1])
			initial_zoom = zoom

	elif event is InputEventScreenDrag:
		if event.index in touch_points:
			touch_points[event.index] = event.position

		if touch_points.size() == 2:
			var touches = touch_points.values()
			var current_distance = touches[0].distance_to(touches[1])

			if initial_distance > 0:
				var zoom_factor = current_distance / initial_distance
				var new_zoom = initial_zoom * zoom_factor
				new_zoom.x = clamp(new_zoom.x, MIN_ZOOM, MAX_ZOOM)
				new_zoom.y = clamp(new_zoom.y, MIN_ZOOM, MAX_ZOOM)
				target_zoom = new_zoom

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			var new_zoom = target_zoom + Vector2(ZOOM_SPEED_WHEEL, ZOOM_SPEED_WHEEL)
			new_zoom.x = clamp(new_zoom.x, MIN_ZOOM, MAX_ZOOM)
			new_zoom.y = clamp(new_zoom.y, MIN_ZOOM, MAX_ZOOM)
			target_zoom = new_zoom
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var new_zoom = target_zoom - Vector2(ZOOM_SPEED_WHEEL, ZOOM_SPEED_WHEEL)
			new_zoom.x = clamp(new_zoom.x, MIN_ZOOM, MAX_ZOOM)
			new_zoom.y = clamp(new_zoom.y, MIN_ZOOM, MAX_ZOOM)
			target_zoom = new_zoom

func _process(delta):
	if zoom != target_zoom:
		zoom = zoom.lerp(target_zoom, SMOOTH_ZOOM_SPEED * delta)