extends VBoxContainer

@export var qr_code: TextureRect
@export var url_label: Label

func _ready() -> void:
	var ip = get_ip_address()
	var url = "%s:%d" % [ip, HttpServer.port]
	url_label.text = url
	
	var code = QRCodeRect.QRCode.new()
	code.put_byte(url.to_utf8_buffer())
	qr_code.texture = ImageTexture.create_from_image(code.generate_image(4, Color.WHITE, Color.BLACK, 1))

func get_ip_address():
	for ip in IP.get_local_addresses():
		if ip.contains(":"): continue
		if ip.begins_with("127"): continue
		if ip.begins_with("172"): continue
		
		return ip
	
	return "127.0.0.1"
