extends Node

const PORT := 6008

var tcp := TCPServer.new()
var peers: Array[StreamPeerTCP] = []
var last_snapshot: Dictionary = {}
var last_node_snapshots: Dictionary = {}

func _ready():
	var args = OS.get_cmdline_args()

	if "--no-mcp-bridge" in args:
		print("Godot MCP Bridge: disabled via --no-mcp-bridge")
		return

	if "--mcp-bridge" not in args and not OS.is_debug_build():
		print("Godot MCP Bridge: disabled (pass --mcp-bridge to enable)")
		return

	print("Godot MCP Bridge: enabled via --mcp-bridge")

	var err = tcp.listen(PORT)
	if err != OK:
		push_error("Failed to start MCP bridge")
		return

	print("Godot MCP Bridge listening on ", PORT)


func _process(_delta):
	if tcp.is_connection_available():
		var peer = tcp.take_connection()
		peers.append(peer)

	for peer in peers:
		if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			continue
		if peer.get_available_bytes() <= 0:
			continue

		var request = peer.get_utf8_string(
			peer.get_available_bytes()
		)
		if request.is_empty():
			continue

		var json = JSON.parse_string(request)
		if json == null:
			continue

		var response = handle_request(json)
		peer.put_utf8_string(JSON.stringify(response))


func handle_request(data: Dictionary):
	var command = data.get("command", "")
	var payload = data.get("payload", {})

	match command:
		"get_scene_tree":
			return get_scene_tree_data()

		"get_node":
			return get_node_info(payload.get("path", ""))

		"get_properties":
			return get_properties(payload.get("path", ""))

		"call_method":
			return call_node_method(
				payload.get("path", ""),
				payload.get("method", ""),
				payload.get("args", [])
			)

		"list_nodes_by_type":
			return { "results": find_nodes_by_type(get_tree().root, payload.get("type", ""))}

		"find_node":
			return find_node_by_name(
				payload.get("name", ""),
				payload.get("contains", false),
				null,
				payload.get("type", "")
			)

		"ping":
			return {"ok": true}

		"take_snapshot":
			return take_snapshot()

		"get_diff":
			return get_diff()

		"get_node_snapshot":
			return get_node_snapshot(payload.get("path", ""))

		"get_node_diff":
			return get_node_diff(payload.get("path", ""))

		"take_screenshot":
			return take_screenshot(payload.get("path", ""))

	return {
		"error": "unknown command"
	}


func take_screenshot(save_path: String) -> Dictionary:
	if save_path.is_empty():
		save_path = "user://screenshots/godot_capture.png"

	var dir := DirAccess.open("user://")
	if dir:
		dir.make_dir_recursive("screenshots")

	var viewport = get_viewport()
	if viewport == null:
		return {"error": "no viewport available"}

	var texture = viewport.get_texture()
	if texture == null:
		return {"error": "no texture available"}

	var image = texture.get_image()
	if image == null:
		return {"error": "failed to capture image from viewport"}

	var err = image.save_png(save_path)
	if err != OK:
		return {"error": "failed to save PNG: " + error_string(err)}

	var abs_path = ProjectSettings.globalize_path(save_path)
	return {
		"status": "ok",
		"path": abs_path,
		"size": [image.get_width(), image.get_height()]
	}


func serialize_node(node: Node) -> Dictionary:
	var children := []

	for child in node.get_children():
		children.append(
			serialize_node(child)
		)

	return {
		"name": node.name,
		"path": str(node.get_path()),
		"type": node.get_class(),
		"children": children
	}


func serialize_node_detailed(node: Node) -> Dictionary:
	var children := []

	for child in node.get_children():
		children.append({
			"name": child.name,
			"path": str(child.get_path()),
			"type": child.get_class()
		})

	var result := {
		"name": node.name,
		"path": str(node.get_path()),
		"type": node.get_class(),
		"children": children
	}

	if node is Node3D:
		result["position"] = [node.position.x, node.position.y, node.position.z]
		result["rotation"] = [node.rotation.x, node.rotation.y, node.rotation.z]
		result["scale"] = [node.scale.x, node.scale.y, node.scale.z]
		result["global_position"] = [node.global_position.x, node.global_position.y, node.global_position.z]
		result["global_rotation"] = [node.global_rotation.x, node.global_rotation.y, node.global_rotation.z]
		result["global_scale"] = [node.global_scale.x, node.global_scale.y, node.global_scale.z]
		result["transform"] = {
			"origin": [node.transform.origin.x, node.transform.origin.y, node.transform.origin.z],
			"basis": {
				"x": [node.transform.basis.x.x, node.transform.basis.x.y, node.transform.basis.x.z],
				"y": [node.transform.basis.y.x, node.transform.basis.y.y, node.transform.basis.y.z],
				"z": [node.transform.basis.z.x, node.transform.basis.z.y, node.transform.basis.z.z]
			}
		}
	elif node is Node2D:
		result["position"] = [node.position.x, node.position.y]
		result["rotation"] = node.rotation
		result["scale"] = [node.scale.x, node.scale.y]
		result["global_position"] = [node.global_position.x, node.global_position.y]
		result["global_rotation"] = node.global_rotation
		result["global_scale"] = [node.global_scale.x, node.global_scale.y]
		result["transform"] = {
			"origin": [node.transform.origin.x, node.transform.origin.y],
			"rotation": node.transform.get_rotation(),
			"scale": [node.transform.get_scale().x, node.transform.get_scale().y]
		}

	var props := {}
	for prop in node.get_property_list():
		var name := prop.name as String
		if name in ["position", "rotation", "scale", "global_position", "global_rotation", "global_scale", "transform"]:
			continue
		var value = node.get(name)
		if value is Object:
			continue
		props[name] = value

	result["properties"] = props
	return result


func get_scene_tree_data():
	return serialize_node(get_tree().root)


func get_node_info(path: String):
	var node = get_node_or_null(path)
	if node == null:
		return { "error": "node not found" }

	return {
		"name": node.name,
		"path": str(node.get_path()),
		"type": node.get_class()
	}


func get_properties(path: String):
	var node = get_node_or_null(path)

	if node == null:
		return { "error": "node not found" }

	var result := {}

	for prop in node.get_property_list():
		var property_name = prop.name

		var value = node.get(property_name)

		if value is Object:
			continue

		result[property_name] = value

	return result


func call_node_method(path: String, method: String, args: Array):
	var node = get_node_or_null(path)

	if node == null:
		return { "error": "node not found" }

	if not node.has_method(method):
		return { "error": "method not found" }

	var result = node.callv(method, args)
	return { "result": result }


func find_node_by_name(name: String, contains: bool = false, from: Node = null, type: String = "") -> Dictionary:
	var tree_data = get_scene_tree_data()
	return _find_in_json(tree_data, name, contains, type)


func _find_in_json(data: Dictionary, name: String, contains: bool, type: String) -> Dictionary:
	var type_match = type.is_empty() or data.get("type", "") == type
	if type_match and ((not contains and data.get("name", "") == name) or (contains and name in data.get("name", ""))):
		return {"path": data.get("path", "")}

	for child in data.get("children", []):
		var result = _find_in_json(child, name, contains, type)
		if result.has("path"):
			return result

	return {"error": "node not found"}


func find_nodes_by_type(node: Node, type_name: String, results := []):
	if node.is_class(type_name):
		results.append(
			str(node.get_path())
		)

	for child in node.get_children():
		find_nodes_by_type(
			child,
			type_name,
			results
		)

	return results


func collect_all_paths(node: Node, paths := {}) -> Dictionary:
	paths[str(node.get_path())] = node.get_class()
	for child in node.get_children():
		collect_all_paths(child, paths)
	return paths


func take_snapshot():
	last_snapshot = collect_all_paths(get_tree().root)
	return {"status": "ok", "node_count": last_snapshot.size()}


func get_diff():
	if last_snapshot.is_empty():
		return {"error": "no snapshot taken yet"}

	var current := collect_all_paths(get_tree().root)
	var added := []
	var removed := []
	var changed := []

	for path in current:
		if path not in last_snapshot:
			added.append(path)
		elif current[path] != last_snapshot[path]:
			changed.append(path)

	for path in last_snapshot:
		if path not in current:
			removed.append(path)

	return {
		"added": added,
		"removed": removed,
		"changed": changed
	}


func get_node_snapshot(path: String) -> Dictionary:
	var node = get_node_or_null(path)
	if node == null:
		return {"error": "node not found"}

	var snapshot = serialize_node_detailed(node)
	last_node_snapshots[path] = snapshot
	return snapshot


func get_node_diff(path: String) -> Dictionary:
	if path not in last_node_snapshots:
		return {"error": "no snapshot taken for this node"}

	var node = get_node_or_null(path)
	if node == null:
		return {"error": "node not found"}

	var current = serialize_node_detailed(node)
	var previous = last_node_snapshots[path]

	var added := []
	var removed := []
	var changed := []

	for key in current:
		if key == "children":
			continue
		if key == "properties":
			var prev_props: Dictionary = previous.get("properties", {})
			var curr_props: Dictionary = current.get("properties", {})
			for prop in curr_props:
				if prop not in prev_props:
					added.append("properties." + prop)
				elif curr_props[prop] != prev_props[prop]:
					changed.append("properties." + prop)
			for prop in prev_props:
				if prop not in curr_props:
					removed.append("properties." + prop)
			continue
		if key not in previous:
			added.append(key)
		elif current[key] != previous[key]:
			changed.append(key)

	for key in previous:
		if key not in current and key != "properties":
			removed.append(key)

	return {
		"added": added,
		"removed": removed,
		"changed": changed
	}
