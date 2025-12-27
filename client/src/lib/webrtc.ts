export interface WebRTCConfig {
	onConnectionStateChange?: (state: RTCPeerConnectionState) => void;
	onDataChannelOpen?: () => void;
	onDataChannelClose?: () => void;
	onDataChannelMessage?: (data: MessageEvent<any>) => void;
	onIceCandidate?: (mid: string | null, index: number | null, sdp: string) => void;
	onSessionDescription?: (type: string, sdp: string) => void;
}

export class WebRTCClient {
	private peerConnection: RTCPeerConnection | null = null;
	private dataChannel: RTCDataChannel | null = null;
	private config: WebRTCConfig;

	constructor(config: WebRTCConfig = {}) {
		this.config = config;
	}

	async initialize() {
		this.peerConnection = new RTCPeerConnection();

		// Set up event handlers
		this.peerConnection.onicecandidate = (event) => {
			if (event.candidate) {
				console.log('ICE candidate created:', event.candidate);
				this.config.onIceCandidate?.(
					event.candidate.sdpMid,
					event.candidate.sdpMLineIndex,
					event.candidate.candidate
				);
			}
		};

		this.peerConnection.onconnectionstatechange = () => {
			const state = this.peerConnection?.connectionState;
			console.log('Connection state changed:', state);
			if (state) {
				this.config.onConnectionStateChange?.(state);
			}
		};

		this.peerConnection.ondatachannel = (event) => {
			console.log('Data channel received:', event.channel.label);
			this.setupDataChannel(event.channel);
		};

		// Create data channel for inputs (negotiated channel with id=1)
		this.dataChannel = this.peerConnection.createDataChannel('inputs', {
			negotiated: true,
			id: 1
		});

		this.setupDataChannel(this.dataChannel);

		console.log('WebRTC initialized');
	}

	private setupDataChannel(channel: RTCDataChannel) {
		this.dataChannel = channel;

		this.dataChannel.onopen = () => {
			console.log('Data channel opened');
			this.config.onDataChannelOpen?.();
		};

		this.dataChannel.onclose = () => {
			console.log('Data channel closed');
			this.config.onDataChannelClose?.();
		};

		this.dataChannel.onmessage = (event) => {
			console.log('Data channel message received:', event.data);
			this.config.onDataChannelMessage?.(event);
		};

		this.dataChannel.onerror = (error) => {
			console.error('Data channel error:', error);
		};
	}

	async createOffer() {
		if (!this.peerConnection) {
			throw new Error('Peer connection not initialized');
		}

		const offer = await this.peerConnection.createOffer();
		await this.peerConnection.setLocalDescription(offer);

		console.log('Offer created:', offer);
		this.config.onSessionDescription?.(offer.type, offer.sdp || '');
	}

	async setRemoteDescription(type: string, sdp: string) {
		if (!this.peerConnection) {
			throw new Error('Peer connection not initialized');
		}

		console.log('Setting remote description:', type);
		await this.peerConnection.setRemoteDescription({
			type: type as RTCSdpType,
			sdp: sdp
		});
	}

	async addIceCandidate(mid: string, index: number, sdp: string) {
		if (!this.peerConnection) {
			throw new Error('Peer connection not initialized');
		}

		console.log('Adding ICE candidate:', { mid, index, sdp });
		const candidate = new RTCIceCandidate({
			sdpMid: mid,
			sdpMLineIndex: index,
			candidate: sdp
		});

		await this.peerConnection.addIceCandidate(candidate);
	}

	sendInput(input: string, pressed: boolean) {
		if (!this.dataChannel || this.dataChannel.readyState !== 'open') {
			console.warn('Data channel is not open');
			return;
		}

		const data = `${input};${pressed ? 1 : 0}`;
		this.dataChannel.send(data);
	}

	sendMove(input: string, vector: { x: number; y: number }) {
		if (!this.dataChannel || this.dataChannel.readyState !== 'open') {
			console.warn('Data channel is not open');
			return;
		}

		const data = `${input};${vector.x.toFixed(2)};${vector.y.toFixed(2)}`;
		this.dataChannel.send(data);
	}

	getConnectionState(): RTCPeerConnectionState | null {
		return this.peerConnection?.connectionState || null;
	}

	isDataChannelOpen(): boolean {
		return this.dataChannel?.readyState === 'open';
	}

	close() {
		if (this.dataChannel) {
			this.dataChannel.close();
			this.dataChannel = null;
		}

		if (this.peerConnection) {
			this.peerConnection.close();
			this.peerConnection = null;
		}

		console.log('WebRTC connection closed');
	}
}
