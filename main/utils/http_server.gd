extends Node

## Simple HTTP server that serves static files from a directory
## Useful for serving the Godot web export to local players

signal server_started(port: int)
signal server_stopped()
signal client_connected(peer_id: int)
signal client_disconnected(peer_id: int)

@export var port: int = 8484
@export var serve_directory: String = "build/web"
@export var auto_start: bool = true

var tcp_server: TCPServer
var clients: Array[StreamPeerTCP] = []
var is_running: bool = false

const MIME_TYPES = {
	"html": "text/html",
	"htm": "text/html",
	"css": "text/css",
	"js": "application/javascript",
	"json": "application/json",
	"png": "image/png",
	"jpg": "image/jpeg",
	"jpeg": "image/jpeg",
	"gif": "image/gif",
	"svg": "image/svg+xml",
	"ico": "image/x-icon",
	"wasm": "application/wasm",
	"pck": "application/octet-stream",
	"txt": "text/plain",
	"xml": "application/xml",
	"pdf": "application/pdf",
	"mp3": "audio/mpeg",
	"mp4": "video/mp4",
	"woff": "font/woff",
	"woff2": "font/woff2",
	"ttf": "font/ttf",
}

func _ready() -> void:
	if auto_start:
		start_server()

func _process(_delta: float) -> void:
	if not is_running:
		return
	
	# Accept new connections
	if tcp_server.is_connection_available():
		var peer = tcp_server.take_connection()
		clients.append(peer)
		client_connected.emit(peer.get_instance_id())
	
	# Process existing clients
	var i = 0
	while i < clients.size():
		var client = clients[i]
		
		if client.get_status() == StreamPeerTCP.STATUS_NONE or \
		   client.get_status() == StreamPeerTCP.STATUS_ERROR:
			client_disconnected.emit(client.get_instance_id())
			clients.remove_at(i)
			continue
		
		if client.get_available_bytes() > 0:
			_handle_client_request(client)
			# Close connection after handling request (HTTP/1.0 style)
			clients.remove_at(i)
			continue
		
		i += 1

func start_server(custom_port: int = -1) -> Error:
	if is_running:
		push_warning("HTTP Server already running")
		return ERR_ALREADY_IN_USE
	
	if custom_port > 0:
		port = custom_port
	
	tcp_server = TCPServer.new()
	var err = tcp_server.listen(port)
	
	if err != OK:
		push_error("Failed to start HTTP server on port %d: %s" % [port, error_string(err)])
		return err
	
	is_running = true
	server_started.emit(port)
	print("HTTP Server started on port %d, serving directory: %s" % [port, serve_directory])
	return OK

func stop_server() -> void:
	if not is_running:
		return
	
	# Close all client connections
	for client in clients:
		client.disconnect_from_host()
	clients.clear()
	
	# Stop the server
	tcp_server.stop()
	is_running = false
	server_stopped.emit()
	print("HTTP Server stopped")

func _handle_client_request(client: StreamPeerTCP) -> void:
	var request = client.get_utf8_string(client.get_available_bytes())
	var lines = request.split("\r\n")
	
	if lines.is_empty():
		_send_response(client, 400, "Bad Request", "text/plain")
		return
	
	# Parse request line (e.g., "GET /index.html HTTP/1.1")
	var request_line = lines[0].split(" ")
	if request_line.size() < 2:
		_send_response(client, 400, "Bad Request", "text/plain")
		return
	
	var method = request_line[0]
	var path = request_line[1]
	
	# Only support GET requests
	if method != "GET":
		_send_response(client, 405, "Method Not Allowed", "text/plain")
		return
	
	# Decode URL and remove query parameters
	if path.contains("?"):
		path = path.split("?")[0]
	
	# Default to index.html for root path
	if path == "/" or path == "":
		path = "/index.html"
	
	# Remove leading slash for file path
	if path.begins_with("/"):
		path = path.substr(1)
	
	# Serve the file
	_serve_file(client, path)

func _serve_file(client: StreamPeerTCP, relative_path: String) -> void:
	# Security: prevent directory traversal
	if relative_path.contains(".."):
		_send_response(client, 403, "Forbidden", "text/plain")
		return
	
	# Build full path
	var base_path = serve_directory
	if not base_path.ends_with("/"):
		base_path += "/"
	
	var full_path = base_path + relative_path
	
	# Check if file exists
	if not FileAccess.file_exists(full_path):
		_send_response(client, 404, "Not Found", "text/plain", "File not found: " + relative_path)
		return
	
	# Read file
	var file = FileAccess.open(full_path, FileAccess.READ)
	if file == null:
		_send_response(client, 500, "Internal Server Error", "text/plain", "Failed to read file")
		return
	
	var content = file.get_buffer(file.get_length())
	file.close()
	
	# Determine MIME type
	var extension = relative_path.get_extension().to_lower()
	var mime_type = MIME_TYPES.get(extension, "application/octet-stream")
	
	# Send response
	_send_file_response(client, 200, "OK", mime_type, content)

func _send_response(client: StreamPeerTCP, code: int, status: String, content_type: String, body: String = "") -> void:
	var body_bytes = body.to_utf8_buffer()
	_send_file_response(client, code, status, content_type, body_bytes)

func _send_file_response(client: StreamPeerTCP, code: int, status: String, content_type: String, body: PackedByteArray) -> void:
	var response = "HTTP/1.1 %d %s\r\n" % [code, status]
	response += "Content-Type: %s\r\n" % content_type
	response += "Content-Length: %d\r\n" % body.size()
	response += "Connection: close\r\n"
	response += "Cross-Origin-Opener-Policy: same-origin\r\n"
	response += "Cross-Origin-Embedder-Policy: require-corp\r\n"
	response += "Access-Control-Allow-Origin: *\r\n"
	response += "\r\n"

	# Send headers
	client.put_data(response.to_utf8_buffer())
	
	# Send body
	if body.size() > 0:
		client.put_data(body)

func _exit_tree() -> void:
	stop_server()
