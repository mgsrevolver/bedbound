class_name ObjectPool
extends Node

var pool_scene: PackedScene
var available_objects: Array = []
var active_objects: Array = []
var initial_size: int
var max_size: int

func initialize(scene: PackedScene, initial: int = 5, maximum: int = 20):
	pool_scene = scene
	initial_size = initial
	max_size = maximum
	name = "ObjectPool"

	for i in range(initial_size):
		create_pooled_object()

func create_pooled_object() -> Node:
	var obj = pool_scene.instantiate()
	obj.set_process(false)
	obj.set_physics_process(false)
	obj.visible = false
	available_objects.append(obj)
	add_child(obj)
	return obj

func get_object() -> Node:
	var obj: Node = null

	if available_objects.is_empty():
		if active_objects.size() < max_size:
			obj = create_pooled_object()
			available_objects.erase(obj)
		else:
			push_warning("ObjectPool: Maximum pool size reached")
			return null
	else:
		obj = available_objects.pop_back()

	active_objects.append(obj)
	obj.set_process(true)
	obj.set_physics_process(true)
	obj.visible = true

	if obj.has_method("reset"):
		obj.reset()

	return obj

func return_object(obj: Node):
	if not obj in active_objects:
		return

	active_objects.erase(obj)
	available_objects.append(obj)

	obj.set_process(false)
	obj.set_physics_process(false)
	obj.visible = false

	if obj.has_method("cleanup"):
		obj.cleanup()

func get_active_count() -> int:
	return active_objects.size()

func get_available_count() -> int:
	return available_objects.size()

func clear_pool():
	for obj in active_objects + available_objects:
		obj.queue_free()

	active_objects.clear()
	available_objects.clear()