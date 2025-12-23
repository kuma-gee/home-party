class_name GameClient
extends Node

var peer = WebRTCPeerConnection.new()
var channel = peer.create_data_channel("inputs", {"negotiated": true, "id": 1})
var logger = KumaLog.new("WebRtcClient")

#func _process(_delta):
	#peer.poll()
	#if channel.get_ready_state() == WebRTCDataChannel.STATE_OPEN:
		#while channel.get_available_packet_count() > 0:
			#print(String(get_path()), " received: ", channel.get_packet().get_string_from_utf8())

func send_message(message):
	channel.put_packet(message.to_utf8_buffer())
