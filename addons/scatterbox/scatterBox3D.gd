@tool
extends Node3D
class_name ScatterBox3D

@export var meshes: Array[Mesh]
@export var mesh_materials: Array[Material]

@export var scenes: Array[PackedScene]


@export var deleteAll := false:
	get: return deleteAll
	set(value):
		if(value):
			delete_obj()
		deleteAll = false

#guhhh
@export var refresh_btn := false:
	get: return refresh_btn
	set(value):
		if(value):
			refresh()
		refresh_btn = false


#if the models/objects need collisions
@export var enable_collisions := false:
	get: return enable_collisions
	set(enable_collisions):
		pass


@export var offset_position := Vector3(0, 0, 0):
	get: return offset_position
	set(value):
		offset_position = value.clamp(Vector3.ONE * -100.0, Vector3.ONE * 100.0)
		_update()


var show_debug_area := true
var _debug_draw_instance : MeshInstance3D


var multiMeshes = []


var draw_pointer : Node3D
var object_parent : Node3D

var is_drawing = true

## The number of instances to generate.
@export_range(0, 10000, 1) var count := 100:
	get: return count
	set(value):
		count = value
		_update()

@export var placement_size := Vector3(10.0, 10.0, 10.0):
	get: return placement_size
	set(value):
		placement_size = value.clamp(Vector3.ONE * 0.01, Vector3.ONE * 100.0)
		_update()

@export_group("Random Size")

## The minimum random size for each instance.
@export var min_random_size := Vector3(0.75, 0.75, 0.75):
	get: return min_random_size
	set(value):
		min_random_size = value.clamp(Vector3.ONE * 0.01, Vector3.ONE * 100.0)
		_update()

## The maximum random size for each instance.
@export var max_random_size := Vector3(1.25, 1.25, 1.25):
	get: return max_random_size
	set(value):
		max_random_size = value.clamp(Vector3.ONE * 0.01, Vector3.ONE * 100.0)
		_update()

@export_group("Random Rotation")

## Rotate each instance by a random amount between
## [code]-random_rotation[/code] and +[code]random_rotation[/code].
@export var random_rotation := Vector3(0.0, 0.0, 0.0):
	get: return random_rotation
	set(value):
		random_rotation = value.clamp(Vector3.ONE * 0.00, Vector3.ONE * 180.0)
		_update()

var _rng := RandomNumberGenerator.new()

@onready var _space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state

var current_color : Color


func refresh():
	multiMeshes = []
	
	for i in object_parent.get_children():
		multiMeshes.append(i)
	
	if multiMeshes == []:
		for mesh in meshes:
			var newMultimeshInst = MultiMeshInstance3D.new()
			object_parent.add_child(newMultimeshInst)
			newMultimeshInst.global_transform.origin = object_parent.global_transform.origin
			newMultimeshInst.set_owner(get_tree().edited_scene_root)
			
			var newMultimesh = MultiMesh.new()
			newMultimesh.transform_format = MultiMesh.TRANSFORM_3D
			newMultimeshInst.multimesh = newMultimesh
			newMultimesh.mesh = mesh
	
	for i in range(meshes.size()):
		var newMultimesh = object_parent.get_child(i)
		newMultimesh.multimesh.mesh.surface_set_material(0, mesh_materials[i])


# Called when the node enters the scene tree for the first time.
func _ready():
	_rng.randomize()
	
	current_color = Color(0.0, 0.0, 1.0, 0.0784313725)
	
	#get the subnodes
	draw_pointer = get_node_or_null("DrawPointer")
	object_parent = get_node_or_null("ObjectParent")
	
	#create them if they don't exist
	if(draw_pointer == null):
		draw_pointer = Node3D.new()
		draw_pointer.name = "DrawPointer"
		add_child(draw_pointer)
		draw_pointer.global_transform.origin = global_transform.origin
		draw_pointer.set_owner(get_tree().edited_scene_root)
	
	if(object_parent == null):
		object_parent = Node3D.new()
		object_parent.name = "ObjectParent"
		add_child(object_parent)
		object_parent.set_owner(self)
		object_parent.global_transform.origin = global_transform.origin
		object_parent.set_owner(get_tree().edited_scene_root)
	
	refresh()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Engine.is_editor_hint():
		if show_debug_area:
			_create_debug_area()
		else:
			_delete_debug_area()
	else:
		set_notify_transform(false)
		set_ignore_transform_notification(true)
	
	_update()



func move_to_mouse(camera, mouse: Vector2):
	var start = camera.project_ray_origin(mouse)
	var end = start + camera.project_ray_normal(mouse) * 1000
	var result = _space.intersect_ray(PhysicsRayQueryParameters3D.create(start, end))
	
	if result.is_empty(): 
		return false
	
	draw_pointer.global_transform.origin = result.position
	if(is_drawing):
		scatter_obj()
	else:
		erase_obj()
	return true


func toggle_drawing():
	is_drawing = !is_drawing
	
	#change the colour of the draw box
	if(is_drawing):
		current_color = Color(0.0, 0.0, 1.0, 0.0784313725)
	else:
		current_color = Color(1.0, 1.0, 1.0, 0.0784313725)
	
	return is_drawing


func _delete_debug_area() -> void:
	if _debug_draw_instance != null && _debug_draw_instance.is_inside_tree():
		_debug_draw_instance.queue_free()
		_debug_draw_instance = null


func _create_debug_area() -> void:
	_delete_debug_area()
	_debug_draw_instance = MeshInstance3D.new()
	
	var material := StandardMaterial3D.new()
	_debug_draw_instance.material_override = material
	
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	material.albedo_color = current_color 
		
	material.no_depth_test = true
	
	var mesh: Mesh
	mesh = BoxMesh.new()
	
	_debug_draw_instance.mesh = mesh
	_debug_draw_instance.visible = show_debug_area
	
	if(draw_pointer != null):
		draw_pointer.add_child(_debug_draw_instance)
		_update_debug_area_size()


func _update_debug_area_size() -> void:
	if _debug_draw_instance != null && _debug_draw_instance.is_inside_tree():
		_debug_draw_instance.mesh.size = placement_size


func _update() -> void:
	if !_space: return
	#scatter()
	
	if Engine.is_editor_hint():
		_update_debug_area_size()



func grow_box():
	placement_size += Vector3(0.5, 0.5, 0.5)
	_update_debug_area_size()

func shrink_box():
	placement_size -= Vector3(0.5, 0.5, 0.5)
	placement_size.x = clamp(placement_size.x, 0, placement_size.x)
	placement_size.y = clamp(placement_size.y, 0, placement_size.y)
	placement_size.z = clamp(placement_size.z, 0, placement_size.z)
	_update_debug_area_size()

func scatter_obj():
	for i in range(count):
		var pos := draw_pointer.global_position
		
		pos += Vector3(
			_rng.randf_range(-placement_size.x / 2.0, placement_size.x / 2.0),
			0.0,
			_rng.randf_range(-placement_size.z / 2.0, placement_size.z / 2.0))
		
		pos = pos + Vector3(
				_rng.randf_range(min_random_size.x, max_random_size.x),
				_rng.randf_range(min_random_size.y, max_random_size.y),
				_rng.randf_range(min_random_size.z, max_random_size.z))
		
		
		var t := Transform3D()
		t.origin = pos
		
		t.origin += offset_position
		
		t.basis = t.basis.scaled(Vector3(
			_rng.randf_range(min_random_size.x, max_random_size.x),
			_rng.randf_range(min_random_size.y, max_random_size.y),
			_rng.randf_range(min_random_size.z, max_random_size.z)))\
			.rotated(Vector3.RIGHT, deg_to_rad(_rng.randf_range(-random_rotation.x, random_rotation.x)))\
			.rotated(Vector3.UP, deg_to_rad(_rng.randf_range(-random_rotation.y, random_rotation.y)))\
			.rotated(Vector3.FORWARD, deg_to_rad(_rng.randf_range(-random_rotation.z, random_rotation.z)))
		
		
		var rand_mesh = _rng.randi_range(0, meshes.size()-1)
		
		var multimeshInst = multiMeshes[rand_mesh]
		var multiMesh = multimeshInst.multimesh
		
		var transforms = []
		for oldT in multiMesh.instance_count:
			transforms.append(multiMesh.get_instance_transform(oldT))
		
		multiMesh.instance_count += 1
		
		for oldT in multiMesh.instance_count-1:
			multiMesh.set_instance_transform(oldT, transforms[oldT])
		
		multiMesh.set_instance_transform(multiMesh.instance_count-1, t)


func erase_obj():
	var pos := draw_pointer.global_position
	
	var start_pos = pos 
	start_pos -= Vector3(placement_size.x/2, placement_size.y/2, placement_size.z/2)
	
	var box = AABB(start_pos, placement_size)
	
	for mesh_num in range(multiMeshes.size()):
		var multimeshInst = multiMeshes[mesh_num]
		var multiMesh = multimeshInst.multimesh
		
		var transforms = []
		
		for oldT in multiMesh.instance_count:
			var cur_t = multiMesh.get_instance_transform(oldT)
			
			if(box.has_point(cur_t.origin)):
				continue
			else:
				transforms.append(cur_t)
		
		multiMesh.instance_count = transforms.size()
			
		for oldT in multiMesh.instance_count-1:
			multiMesh.set_instance_transform(oldT, transforms[oldT])


func delete_obj():
	for i in object_parent.get_children():
		i.queue_free()
	refresh()


