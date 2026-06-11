extends Node

const PORT := 6008

var tcp := TCPServer.new()
var peers: Array[StreamPeerTCP] = []

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
		"ping":
			return {"ok": true}

	return {
		"error": "unknown command"
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
