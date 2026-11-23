@tool
extends EditorScript

const SAVE_FOLDER = "res://shared_collisions/"

func _run() -> void:
	var root = get_scene()
	if not root:
		printerr("Open main.tscn in the editor first!")
		return
		
	DirAccess.make_dir_recursive_absolute(SAVE_FOLDER)
	var shared_shapes: Dictionary = {}
	var updated_count = 0
	
	_process_node(root, shared_shapes, updated_count)
	print("Done! Deduplicated collisions into ", shared_shapes.size(), " shared files.")

func _process_node(node: Node, shared_shapes: Dictionary, count: int) -> void:
	if node is MeshInstance3D and node.mesh != null:
		var mesh_id = node.mesh.get_instance_id()
		
		for child in node.get_children():
			if child is StaticBody3D:
				for subchild in child.get_children():
					if subchild is CollisionShape3D and subchild.shape != null:
						if not shared_shapes.has(mesh_id):
							var clean_name = node.mesh.resource_name
							if clean_name == "":
								clean_name = "shape_" + str(mesh_id)
							var path = SAVE_FOLDER + clean_name.validate_filename() + ".res"
							ResourceSaver.save(subchild.shape, path)
							shared_shapes[mesh_id] = load(path)
						
						subchild.shape = shared_shapes[mesh_id]
						count += 1
						
	for child in node.get_children():
		_process_node(child, shared_shapes, count)
