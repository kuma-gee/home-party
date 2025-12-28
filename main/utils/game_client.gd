class_name GameClient
extends Node

signal send_candidate(mid: String, index: int, sdp: String)
signal send_session(type: int, sdp: String)
signal input_received(input: String, value)
signal sent_text(text: String)

var peer = WebRTCPeerConnection.new()
var channel = peer.create_data_channel("inputs", {"negotiated": true, "id": 1})
var logger = KumaLog.new("GameClient")

var inputs = {}
var uuid: String

func _ready():
	peer.ice_candidate_created.connect(self._on_ice_candidate)
	peer.session_description_created.connect(self._on_session)

func get_move():
	return inputs["move"] if inputs.has("move") else Vector2.ZERO

func _on_ice_candidate(mid, index, sdp):
	send_candidate.emit(mid, index, sdp)
	logger.info("Created ICE candidate: mid=%s, index=%d" % [mid, index])

func _on_session(type, sdp):
	peer.set_local_description(type, sdp)
	logger.info("Created session description of type %s" % type)
	send_session.emit(type, sdp)

func _process(_delta):
	peer.poll()
	if channel.get_ready_state() == WebRTCDataChannel.STATE_OPEN:
		while channel.get_available_packet_count() > 0:
			var data = channel.get_packet().get_string_from_utf8()
			logger.debug("Received input: %s" % data)

			var parts = data.split(";")
			if parts.size() == 2:
				var input = parts[0]
				var pressed = parts[1].to_float() == 1.0
				input_received.emit(input, pressed)
			elif parts.size() == 3:
				var input = parts[0]
				var v = Vector2(parts[1].to_float(), parts[2].to_float())
				inputs[input] = v
				input_received.emit(input, v)

func add_ice_candidate(mid: String, index: int, sdp: String):
	peer.add_ice_candidate(mid, index, sdp)
	logger.debug("Added ICE candidate: mid=%s, index=%d" % [mid, index])

func set_session(type: String, sdp: String):
	peer.set_remote_description(type, sdp)
	logger.debug("Set remote session description of type %s" % type)
	
func send_text(text: String):
	channel.put_packet(text.to_utf8_buffer())
	sent_text.emit(text)

func reset():
	inputs = {}
	send_text("")
