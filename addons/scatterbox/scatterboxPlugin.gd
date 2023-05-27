@tool
extends EditorPlugin


var selection = get_editor_interface().get_selection()
var undo_redo = get_undo_redo()

var selected_node

var mouse_down = false
var can_move_selection = true


func _enter_tree():
	# Initialization of the plugin goes here.
	add_custom_type("ScatterBox3D", "Node3D", preload("scatterBox3D.gd"), preload("scatterbox3D.png"))
	
	selection.selection_changed.connect(_on_selection_changed)
	
	InputMap.add_action("PlaceTerrain")
	var ev = InputEventKey.new()
	ev.keycode = KEY_C
	InputMap.action_add_event("PlaceTerrain", ev)
	
	undo_redo.create_action("Scatter Objects")
	undo_redo.add_do_method(ScatterBox3D, "scatter")
	undo_redo.add_undo_method(ScatterBox3D, "undo_scatter")
	undo_redo.commit_action()
	

func _exit_tree():
	# Clean-up of the plugin goes here.
	remove_custom_type("ScatterBox3D")
	InputMap.action_erase_events("PlaceTerrain")


func _on_selection_changed():
	pass


func _handles(object):
	if (object is ScatterBox3D):
		selected_node = object
		return true
	return false


func _forward_3d_gui_input(viewport_camera, event):
	var captured_event = false
	
	#if ctrl held/pressed dont do anything
	if(event is InputEventKey):
		if(event.keycode == KEY_ALT):
			if(event.pressed):
				can_move_selection = false
			else:
				can_move_selection = true
		if(event.keycode == KEY_E):
			if(event.pressed and selected_node != null):
				selected_node.toggle_drawing()
	
	
	if(can_move_selection):
		if(event is InputEventMouseButton):
			if(event.button_index == MOUSE_BUTTON_LEFT):
				if(event.pressed == false):
					mouse_down = false
					captured_event = true
				else:
					mouse_down = true
					var res = move_object_to_mouse(viewport_camera, selected_node, event.position)
					captured_event = res
					
		if event is InputEventMouseMotion and mouse_down:
			if(selected_node != null):
				move_object_to_mouse(viewport_camera, selected_node, event.position)
				captured_event = true
	
	return captured_event



func move_object_to_mouse(camera, object, mouse_pos):
	object.move_to_mouse(camera, mouse_pos)


