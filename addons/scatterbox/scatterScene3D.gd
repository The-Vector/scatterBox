@tool
extends ScatterBox
class_name ScatterScene3D

@export var scenes: Array[PackedScene]




func refresh():
	pass


func scatter_obj():
	for i in range(count):
		var pos := draw_pointer.global_position
		
		pos += Vector3(
			_rng.randf_range(-placement_size.x / 2.0, placement_size.x / 2.0),
			0,
			_rng.randf_range(-placement_size.z / 2.0, placement_size.z / 2.0))
		
		pos = pos + Vector3(
				_rng.randf_range(min_random_size.x, max_random_size.x),
				0,
				_rng.randf_range(min_random_size.z, max_random_size.z))
		
		
		var startPos = pos
		startPos.y += placement_size.y
		var endPos = pos
		endPos.y -= placement_size.y
		
		var ray = PhysicsRayQueryParameters3D.create(startPos, endPos)
		
		var hit = _space.intersect_ray(ray)
		
		if(hit.is_empty()): continue
		
		var t := Transform3D()
		t.origin = hit.position
		t.origin += offset_position
		
		#https://kidscancode.org/godot_recipes/3.x/3d/3d_align_surface/index.html
		t.basis.y = hit.normal
		t.basis.x = -t.basis.z.cross(hit.normal)
		t.basis = t.basis.orthonormalized()
		
		
		t.basis = t.basis.scaled(Vector3(
			_rng.randf_range(min_random_size.x, max_random_size.x),
			_rng.randf_range(min_random_size.y, max_random_size.y),
			_rng.randf_range(min_random_size.z, max_random_size.z)))\
			.rotated(Vector3.RIGHT, deg_to_rad(_rng.randf_range(-random_rotation.x, random_rotation.x)))\
			.rotated(Vector3.UP, deg_to_rad(_rng.randf_range(-random_rotation.y, random_rotation.y)))\
			.rotated(Vector3.FORWARD, deg_to_rad(_rng.randf_range(-random_rotation.z, random_rotation.z)))
		
		
		var rand_scene = _rng.randi_range(0, scenes.size()-1)
		
		var scene_inst = scenes[rand_scene].instantiate()
		scene_inst.global_transform = t
		
		object_parent.add_child(scene_inst)
		scene_inst.set_owner(get_tree().edited_scene_root)


func erase_obj():
	var pos := draw_pointer.global_position
	
	var start_pos = pos 
	start_pos -= Vector3(placement_size.x/2, placement_size.y/2, placement_size.z/2)
	
	var box = AABB(start_pos, placement_size)
	
	for child in object_parent.get_children():
		if(box.has_point(child.global_transform.origin)):
			child.queue_free()

