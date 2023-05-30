@tool
extends ScatterBox
class_name ScatterMesh3D

@export var meshes: Array[Mesh]
@export var mesh_materials: Array[Material]


var multiMeshes = []



func refresh():
	multiMeshes = []
	
	for i in object_parent.get_children():
		multiMeshes.append(i)
	
	#create the two multimeshes 
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


func scatter_obj():
	for i in range(count):
		var pos := draw_pointer.global_position
		
		#get a random position in the drawing box
		pos += Vector3(
			_rng.randf_range(-placement_size.x / 2.0, placement_size.x / 2.0),
			0,
			_rng.randf_range(-placement_size.z / 2.0, placement_size.z / 2.0))
		
		pos = pos + Vector3(
				_rng.randf_range(min_random_size.x, max_random_size.x),
				0,
				_rng.randf_range(min_random_size.z, max_random_size.z))
		
		#make a raycast to align the mesh to the floor
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
		
		#apply a random rotation and scaling
		t.basis = t.basis.scaled(Vector3(
			_rng.randf_range(min_random_size.x, max_random_size.x),
			_rng.randf_range(min_random_size.y, max_random_size.y),
			_rng.randf_range(min_random_size.z, max_random_size.z)))\
			.rotated(Vector3.RIGHT, deg_to_rad(_rng.randf_range(-random_rotation.x, random_rotation.x)))\
			.rotated(Vector3.UP, deg_to_rad(_rng.randf_range(-random_rotation.y, random_rotation.y)))\
			.rotated(Vector3.FORWARD, deg_to_rad(_rng.randf_range(-random_rotation.z, random_rotation.z)))
		
		#get a random mesh
		var rand_mesh = _rng.randi_range(0, meshes.size()-1)
		
		#get the correct multimesh 
		#as each one stores one mesh
		var multimeshInst = multiMeshes[rand_mesh]
		var multiMesh = multimeshInst.multimesh
		
		#save all the old transforms
		var transforms = []
		for oldT in multiMesh.instance_count:
			transforms.append(multiMesh.get_instance_transform(oldT))
		
		#editing the instance count resets the buffer
		multiMesh.instance_count += 1
		
		#add all the old instance transforms back
		for oldT in multiMesh.instance_count-1:
			multiMesh.set_instance_transform(oldT, transforms[oldT])
		
		#set the new instance transform
		multiMesh.set_instance_transform(multiMesh.instance_count-1, t)


func erase_obj():
	var pos := draw_pointer.global_position
	
	var start_pos = pos 
	start_pos -= Vector3(placement_size.x/2, placement_size.y/2, placement_size.z/2)
	
	var box = AABB(start_pos, placement_size)
	
	#see if any of the multimeshes is in the bounding box
	for mesh_num in range(multiMeshes.size()):
		var multimeshInst = multiMeshes[mesh_num]
		var multiMesh = multimeshInst.multimesh
		
		var transforms = []
		
		#save instances that are outside the box
		for oldT in multiMesh.instance_count:
			var cur_t = multiMesh.get_instance_transform(oldT)
			
			if(box.has_point(cur_t.origin)):
				continue
			else:
				transforms.append(cur_t)
		
		#update the instance count
		multiMesh.instance_count = transforms.size()
		
		#update the instances
		for oldT in multiMesh.instance_count-1:
			multiMesh.set_instance_transform(oldT, transforms[oldT])

