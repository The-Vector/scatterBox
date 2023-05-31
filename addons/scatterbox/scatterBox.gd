@tool
extends Node3D
class_name ScatterBox


#delete all of the meshes/objects 
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

#how far the mesh/object is from the gound
@export var offset_position := Vector3(0, 0, 0):
	get: return offset_position
	set(value):
		offset_position = value.clamp(Vector3.ONE * -100.0, Vector3.ONE * 100.0)
		_update_debug_area_size()


var show_debug_area := true
var _debug_draw_instance : MeshInstance3D

var draw_pointer : Node3D
var object_parent : Node3D

var is_drawing = true


## The number of instances to generate.
@export_range(0, 1000, 1) var count := 1:
	get: return count
	set(value):
		count = value
		_update_debug_area_size()

#the size of the draw box
@export var placement_size := Vector3(10.0, 10.0, 10.0):
	get: return placement_size
	set(value):
		placement_size = value.clamp(Vector3.ONE * 0.01, Vector3.ONE * 100.0)
		_update_debug_area_size()


@export_group("Random Size")

## The minimum random size for each instance.
@export var min_random_size := Vector3(0.75, 0.75, 0.75):
	get: return min_random_size
	set(value):
		min_random_size = value.clamp(Vector3.ONE * 0.01, Vector3.ONE * 100.0)
		_update_debug_area_size()

## The maximum random size for each instance.
@export var max_random_size := Vector3(1.25, 1.25, 1.25):
	get: return max_random_size
	set(value):
		max_random_size = value.clamp(Vector3.ONE * 0.01, Vector3.ONE * 100.0)
		_update_debug_area_size()


@export_group("Random Rotation")

## Rotate each instance by a random amount between
## [code]-random_rotation[/code] and +[code]random_rotation[/code].
@export var random_rotation := Vector3(0.0, 0.0, 0.0):
	get: return random_rotation
	set(value):
		random_rotation = value.clamp(Vector3.ONE * 0.00, Vector3.ONE * 180.0)
		_update_debug_area_size()


var _rng := RandomNumberGenerator.new()

@onready var _space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state

var current_color : Color

#if the node is currently selected
var selected = false

#refresh the nodes
#useful for the mesh scatter
#as you need the meshinstances to be generated before adding anything to them
func refresh():
	pass


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



#move the draw box to the mouse position
func move_to_mouse(camera, mouse: Vector2):
	var start = camera.project_ray_origin(mouse)
	var end = start + camera.project_ray_normal(mouse) * 1000
	var result = _space.intersect_ray(PhysicsRayQueryParameters3D.create(start, end))
	
	if result.is_empty(): 
		return false
	
	var t := Transform3D()
	t.origin = result.position
		
	t.origin += offset_position
		
	#align mesh with floor nomral
	t.basis = Basis(result.normal.cross(global_transform.basis.z),
			result.normal,
			global_transform.basis.x.cross(result.normal),
		).orthonormalized()
	
	draw_pointer.basis = t.basis
	
	draw_pointer.global_transform.origin = result.position
	return true


func select():
	selected = true
	_create_debug_area()
	_update_debug_area()

func deselect():
	selected = false
	is_drawing = true
	_delete_debug_area()


func draw():
	if(is_drawing):
		scatter_obj()
	else:
		erase_obj()


#toggle draw and erase mode
func toggle_drawing():
	is_drawing = !is_drawing
	#change the colour of the draw box
	_update_debug_area()
	
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


func _update_debug_area() -> void:
	if(is_drawing):
		current_color = Color(0.0, 0.0, 1.0, 0.0784313725)
	else:
		current_color = Color(1.0, 1.0, 1.0, 0.0784313725)
	
	_debug_draw_instance.material_override.albedo_color = current_color


func _update_debug_area_size() -> void:
	if _debug_draw_instance != null && _debug_draw_instance.is_inside_tree():
		_debug_draw_instance.mesh.size = placement_size



func grow_box():
	placement_size += Vector3(0.5, 0.5, 0.5)
	_update_debug_area_size()

func shrink_box():
	placement_size -= Vector3(0.5, 0.5, 0.5)
	placement_size.x = clamp(placement_size.x, 0, placement_size.x)
	placement_size.y = clamp(placement_size.y, 0, placement_size.y)
	placement_size.z = clamp(placement_size.z, 0, placement_size.z)
	_update_debug_area_size()


#virtual method
func scatter_obj():
	pass


#virtual method
func erase_obj():
	pass


#delete all the created/painted objects
func delete_obj():
	for i in object_parent.get_children():
		i.queue_free()
	refresh()


