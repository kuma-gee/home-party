import { WebRTCClient, type WebRTCConfig } from './webrtc';

// Fallback UUID generator for browsers that don't support crypto.randomUUID()
function generateUUID(): string {
	// Try to use crypto.randomUUID() if available
	if (typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function') {
		try {
			return crypto.randomUUID();
		} catch (e) {
			console.warn('crypto.randomUUID() failed, using fallback');
		}
	}
	
	// Fallback implementation using crypto.getRandomValues() or Math.random()
	if (typeof crypto !== 'undefined' && typeof crypto.getRandomValues === 'function') {
		// Use crypto.getRandomValues for better randomness
		const bytes = new Uint8Array(16);
		crypto.getRandomValues(bytes);
		
		// Set version (4) and variant bits
		bytes[6] = (bytes[6] & 0x0f) | 0x40;
		bytes[8] = (bytes[8] & 0x3f) | 0x80;
		
		// Convert to hex string
		const hexArray = Array.from(bytes, byte => byte.toString(16).padStart(2, '0'));
		return `${hexArray.slice(0, 4).join('')}-${hexArray.slice(4, 6).join('')}-${hexArray.slice(6, 8).join('')}-${hexArray.slice(8, 10).join('')}-${hexArray.slice(10).join('')}`;
	}
	
	// Final fallback using Math.random() (less secure but works everywhere)
	return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
		const r = (Math.random() * 16) | 0;
		const v = c === 'x' ? r : (r & 0x3) | 0x8;
		return v.toString(16);
	});
}

export enum MessageType {
	Id = 0,
	GameClientSession = 1,
	GameClientIceCandidate = 2,
}

export interface Message {
	msg: MessageType;
	[key: string]: any;
}

export interface IdMessage extends Message {
	msg: MessageType.Id;
	id: number;
}

export interface SessionMessage extends Message {
	msg: MessageType.GameClientSession;
	type: string;
	sdp: string;
}

export interface IceCandidateMessage extends Message {
	msg: MessageType.GameClientIceCandidate;
	mid: string;
	index: number;
	sdp: string;
}

export class WebSocketClient {
	private ws: WebSocket | null = null;
	private peerId: number | null = null;
	private reconnectAttempts = 0;
	private maxReconnectAttempts = 5;
	private reconnectDelay = 1000;
	private intentionalDisconnect = false;
	private webrtcClient: WebRTCClient | null = null;
	private playerName: string = '';

	onConnected?: () => void;
	onDisconnected?: () => void;
	onError?: (error: Event) => void;
	onMessage?: (message: Message) => void;
	onIdReceived?: (id: number) => void;
	onWebRTCStateChange?: (state: RTCPeerConnectionState) => void;
	onWebRTCDataChannelOpen?: () => void;

	constructor(private serverIp: string, private port: number = 14412) {}

	setPlayerName(name: string) {
		this.playerName = name;
	}

	connect(): Promise<void> {
		return new Promise((resolve, reject) => {
			try {
				const protocol = window.location.protocol === 'https:' ? 'wss' : 'ws';
				const url = `${protocol}://${this.serverIp}:${this.port}`;
				console.log(`Connecting to WebSocket: ${url}`);
				
				this.intentionalDisconnect = false;
				this.ws = new WebSocket(url);

				this.ws.onopen = () => {
					console.log('WebSocket connected');
					this.reconnectAttempts = 0;
					this.onConnected?.();
					resolve();
				};

				this.ws.onclose = () => {
					console.log('WebSocket disconnected');
					this.onDisconnected?.();
					this.attemptReconnect();
				};

				this.ws.onerror = (error) => {
					console.error('WebSocket error:', error);
					this.onError?.(error);
					reject(error);
				};

				this.ws.onmessage = async (event) => {
					try {
						let messageText: string;
						
						if (typeof event.data === 'string') {
							messageText = event.data;
						} else if (event.data instanceof Blob) {
							// Convert Blob to text
							messageText = await event.data.text();
						} else if (event.data instanceof ArrayBuffer) {
							// Convert ArrayBuffer to text
							const decoder = new TextDecoder('utf-8');
							messageText = decoder.decode(event.data);
						} else {
							console.error('Unknown message data type:', typeof event.data);
							return;
						}
						
						console.log('Message text:', messageText);
						const message = JSON.parse(messageText) as Message;
						console.log('Parsed message:', message);
						this.handleMessage(message);
					} catch (error) {
						console.error('Failed to parse message:', error);
						console.error('Raw event data:', event.data);
					}
				};
			} catch (error) {
				console.error('Failed to create WebSocket:', error);
				reject(error);
			}
		});
	}

	private handleMessage(message: Message) {
		switch (message.msg) {
			case MessageType.Id:
				this.peerId = (message as IdMessage).id;
				console.log(`Received peer ID: ${this.peerId}`);
				this.onIdReceived?.(this.peerId);
				
				// Get or generate client UUID
				let clientId = localStorage.getItem('clientId');
				if (!clientId) {
					clientId = generateUUID();
					localStorage.setItem('clientId', clientId);
					console.log(`Generated new client ID: ${clientId}`);
				} else {
					console.log(`Using existing client ID: ${clientId}`);
				}
				
				// Send back the ID message with player data and client UUID
				this.send({
					msg: MessageType.Id,
					peer_id: this.peerId,
					client_id: clientId,
					name: this.playerName || 'Player ' + this.peerId,
				});

				this.initializeWebRTC();
				break;
			case MessageType.GameClientSession:
				const sessionMsg = message as SessionMessage;
				this.webrtcClient?.setRemoteDescription(sessionMsg.type, sessionMsg.sdp)
					.catch(error => console.error('Failed to set remote description:', error));
				break;
			case MessageType.GameClientIceCandidate:
				const iceMsg = message as IceCandidateMessage;
				this.webrtcClient?.addIceCandidate(iceMsg.mid, iceMsg.index, iceMsg.sdp)
					.catch(error => console.error('Failed to add ICE candidate:', error));
				break;
		}
	}

	private async initializeWebRTC() {
		const webrtcConfig: WebRTCConfig = {
			onConnectionStateChange: (state) => {
				console.log('WebRTC connection state:', state);
				this.onWebRTCStateChange?.(state);
			},
			onDataChannelOpen: () => {
				console.log('WebRTC data channel opened');
				this.onWebRTCDataChannelOpen?.();
			},
			onIceCandidate: (mid, index, sdp) => {
				this.send({
					msg: MessageType.GameClientIceCandidate,
					peer_id: this.peerId,
					mid: mid,
					index: index,
					sdp: sdp,
				});
			},
			onSessionDescription: (type, sdp) => {
				this.send({
					msg: MessageType.GameClientSession,
					peer_id: this.peerId,
					type: type,
					sdp: sdp,
				});
			}
		};

		this.webrtcClient = new WebRTCClient(webrtcConfig);
		await this.webrtcClient.initialize();
        await this.webrtcClient.createOffer();
	}

	private attemptReconnect() {
		if (this.intentionalDisconnect) {
			console.log('Intentional disconnect, not attempting to reconnect');
			return;
		}
		
		if (this.reconnectAttempts < this.maxReconnectAttempts) {
			this.reconnectAttempts++;
			console.log(`Attempting to reconnect (${this.reconnectAttempts}/${this.maxReconnectAttempts})...`);
			setTimeout(() => {
				this.connect().catch((error) => {
					console.error('Reconnection failed:', error);
				});
			}, this.reconnectDelay * this.reconnectAttempts);
		} else {
			console.error('Max reconnection attempts reached');
		}
	}

	send(data: any) {
		if (this.ws && this.ws.readyState === WebSocket.OPEN) {
			const message = JSON.stringify(data);
			console.log('Sending message:', message);
			this.ws.send(message);
		} else {
			console.warn('WebSocket is not connected');
		}
	}

	disconnect() {
		if (this.ws) {
			this.intentionalDisconnect = true;
			this.ws.close();
			this.ws = null;
		}

		// Close WebRTC connection
		if (this.webrtcClient) {
			this.webrtcClient.close();
			this.webrtcClient = null;
		}
	}

	isConnected(): boolean {
		return this.ws !== null && this.ws.readyState === WebSocket.OPEN;
	}

	getPeerId(): number | null {
		return this.peerId;
	}

	getWebRTCClient(): WebRTCClient | null {
		return this.webrtcClient;
	}
}
