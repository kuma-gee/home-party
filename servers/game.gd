extends Node3D

const URL = "https://kuma-gee.com/home-party"

@export var start_game_btn: Button
@export var qr_code: TextureRect
@export var url_label: Label
@onready var lobby_server: LobbyServer = $LobbyServer

func _ready() -> void:
	start_game_btn.pressed.connect(_on_start_game)
	var ip = get_ip_address()
	lobby_server.create_server(ip)
	
	var url = "%s?ip=%s" % [URL, ip]
	url_label.text = url
	
	var code = QRCodeRect.QRCode.new()
	code.put_byte(url.to_utf8_buffer())
	qr_code.texture = ImageTexture.create_from_image(code.generate_image(4, Color.WHITE, Color.BLACK, 1))
	
func _on_start_game():
	pass

func get_ip_address():
	for ip in IP.get_local_addresses():
		if ip.contains(":"): continue
		if ip.begins_with("127"): continue
		if ip.begins_with("172"): continue
		
		return ip
	
	return "127.0.0.1"
