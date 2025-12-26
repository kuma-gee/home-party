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

	onConnected?: () => void;
	onDisconnected?: () => void;
	onError?: (error: Event) => void;
	onMessage?: (message: Message) => void;
	onIdReceived?: (id: number) => void;

	constructor(private serverIp: string, private port: number = 14412) {}

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
						console.log('WebSocket message received:', event);
						
						// Handle different data types (string, Blob, ArrayBuffer)
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
					clientId = crypto.randomUUID();
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
					name: 'Player ' + this.peerId,
				});
				break;
			case MessageType.GameClientSession:
			case MessageType.GameClientIceCandidate:
				this.onMessage?.(message);
				break;
		}
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
	}

	isConnected(): boolean {
		return this.ws !== null && this.ws.readyState === WebSocket.OPEN;
	}

	getPeerId(): number | null {
		return this.peerId;
	}
}
