@tool
extends EditorPlugin


var selection = get_editor_interface().get_selection()

var selected_node

var mouse_down = false
var can_move_selection = true

var erase_button : CheckBox = null


func _enter_tree():
	# Initialization of the plugin goes here.
	add_custom_type("ScatterMesh3D", "ScatterBox", preload("scatterMesh3D.gd"), preload("scatterbox3D.png"))
	add_custom_type("ScatterScene3D", "ScatterBox", preload("scatterScene3D.gd"), preload("scatterbox3D.png"))
	
	selection.selection_changed.connect(_on_selection_changed)
	
	InputMap.add_action("PlaceTerrain")
	var ev = InputEventKey.new()
	ev.keycode = KEY_C
	InputMap.action_add_event("PlaceTerrain", ev)
	
	add_erase_button()



func _exit_tree():
	# Clean-up of the plugin
	remove_custom_type("ScatterMesh3D")
	remove_custom_type("ScatterScene3D")
	
	InputMap.action_erase_events("PlaceTerrain")
	remove_erase_button()


func _make_visible(visible):
	if visible:
		selected_node.selected = true
		add_erase_button()
	else:
		remove_erase_button()


func add_erase_button():
	if erase_button != null:
		return
	
	erase_button = CheckBox.new()
	erase_button.text = "Erase: "
	erase_button.connect("toggled", toggle_drawing)
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, erase_button)


func remove_erase_button():
	if erase_button == null:
		return
	
	remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, erase_button)
	erase_button.queue_free()
	erase_button = null


#when selecting another node hide the draw box
func _on_selection_changed():
	if(selected_node != null):
		#reset the current node
		selected_node.deselect()
		selected_node = null
		erase_button.button_pressed = false


#if the current node is a scatterbox get the custom keybinds/actions
func _handles(object):
	if (object is ScatterBox):
		selected_node = object
		selected_node.select()
		return true
	
	return false


#get the inputs
func _forward_3d_gui_input(viewport_camera, event):
	var captured_event = false
	
	#if alt held/pressed dont do anything
	if(event is InputEventKey):
		if(event.keycode == KEY_ALT):
			if(event.pressed):
				can_move_selection = false
				return false
			
			else:
				can_move_selection = true
		
		#E switches between erase and draw modes
		if(event.keycode == KEY_E):
			if(event.pressed):
				erase_button.button_pressed = !erase_button.button_pressed
	
	#scroll wheel to change the size of the draw bow
	if(event is InputEventMouseButton and selected_node != null and can_move_selection):
		if(event.button_index == 4):
			selected_node.grow_box()
			captured_event = true
		if(event.button_index == 5):
			selected_node.shrink_box()
			captured_event = true
	
	#mouse stuff
	if(can_move_selection and selected_node != null):
		if(event is InputEventMouseButton):
			if(event.button_index == MOUSE_BUTTON_LEFT):
				if(event.pressed == false):
					mouse_down = false
					captured_event = true
				else:
					mouse_down = true
					
		
		if event is InputEventMouseMotion:
			if(mouse_down):
				if(selected_node != null):
					move_object_to_mouse(viewport_camera, selected_node, event.position)
					selected_node.draw()
					captured_event = true
			else:
				var res = move_object_to_mouse(viewport_camera, selected_node, event.position)
				captured_event = res
		
	
	return captured_event


func toggle_drawing(_toggle = false):
	if(selected_node != null):
		var res = selected_node.toggle_drawing()


func move_object_to_mouse(camera, object, mouse_pos):
	object.move_to_mouse(camera, mouse_pos)


