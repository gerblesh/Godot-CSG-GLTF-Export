@tool
extends EditorPlugin
var csg_button : Button
var file_dialog : FileDialog
var selected : CSGShape3D

func _enter_tree() -> void:
	csg_button = Button.new()
	file_dialog = FileDialog.new()
	
	csg_button.add_child(file_dialog)
	
	csg_button.pressed.connect(on_pressed)
	file_dialog.file_selected.connect(on_file_selected)
	
	csg_button.hide()
	csg_button.text = "Export CSG as GLB"
	
	file_dialog.add_filter("*.glb")
	file_dialog.title = "Export GLTF to Filesystem"
	
	get_editor_interface().get_selection().selection_changed.connect(selection_changed)
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU,csg_button)

func _exit_tree() -> void:
	# cleanup
	remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU,csg_button)
	csg_button.queue_free()

func selection_changed() -> void:
	var selected_nodes : Array[Node] = get_editor_interface().get_selection().get_selected_nodes()
	var node : Node = selected_nodes[-1]
	if node is CSGShape3D:
		if node.is_root_shape():
			csg_button.show()
			selected = node
			return
	selected = null
	csg_button.hide()

func on_pressed() -> void:
	file_dialog.get_line_edit().text = str(selected.name, ".glb")
	file_dialog.popup_centered_ratio()

func on_file_selected(path : String):
	export_mesh_as_gltf(selected.get_meshes()[-1],path)

func export_mesh_as_gltf(mesh : Mesh, file_path : String) -> int:
	var importer_mesh : ImporterMesh = ImporterMesh.new()
	# taking mesh data from the Mesh resource and transfering it to ImporterMesh
	for surface in mesh.get_surface_count():
		importer_mesh.add_surface(mesh.surface_get_primitive_type(surface),mesh.surface_get_arrays(surface),[],{},mesh.surface_get_material(surface))
	
	var gltf_mesh : GLTFMesh = GLTFMesh.new()
	gltf_mesh.mesh = importer_mesh
	
	# creating the base gltf
	var gltf_doc : GLTFDocument = GLTFDocument.new()
	var gltf_state : GLTFState = GLTFState.new() 
	gltf_state.scene_name = selected.name
	gltf_state.set_meshes([gltf_mesh])
	# adding the mesh node
	var mesh_node : GLTFNode = GLTFNode.new()
	mesh_node.mesh = 0
	gltf_state.set_nodes([mesh_node])
	
	gltf_doc.generate_scene(gltf_state)
	gltf_doc.generate_buffer(gltf_state)
	
	return gltf_doc.write_to_filesystem(gltf_state,file_path)
