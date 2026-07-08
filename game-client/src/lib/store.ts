import { writable, derived } from 'svelte/store';
import { WebSocketClient, type Message } from './websocket';

export interface ConnectionState {
	connected: boolean;
	peerId: number | null;
	serverIp: string | null;
	error: string | null;
	inputLayout: string;
	webrtcState: RTCPeerConnectionState | null;
	webrtcDataChannelOpen: boolean;
	reconnecting: boolean;
	reconnectAttempts: number;
	maxReconnectAttempts: number;
	serverMessage: string | null;
	blocked: boolean;
}

function createConnectionStore() {
	const { subscribe, set, update } = writable<ConnectionState>({
		connected: false,
		peerId: null,
		serverIp: null,
		error: null,
		inputLayout: 'joystick',
		webrtcState: null,
		webrtcDataChannelOpen: false,
		reconnecting: false,
		reconnectAttempts: 0,
		maxReconnectAttempts: 5,
		serverMessage: null,
		blocked: false,
	});

	let client: WebSocketClient | null = null;

	return {
		subscribe,
		connect: async (serverIp: string) => {
			if (client) {
				client.disconnect();
			}

			client = new WebSocketClient(serverIp);

			client.onConnected = () => {
				update(state => ({ ...state, connected: true, serverIp, error: null, blocked: false }));
			};

			client.onBlocked = () => {
				update(state => ({ ...state, blocked: true }));
			};

			client.onDisconnected = () => {
				update(state => ({ 
					...state, 
					connected: false,
					webrtcState: null,
					webrtcDataChannelOpen: false,
				}));
			};

			client.onError = (error) => {
				update(state => ({ ...state, error: 'Connection error occurred' }));
			};

			client.onIdReceived = (id: number) => {
				update(state => ({ ...state, peerId: id }));
			};

			client.onInputLayoutReceived = (layout: string) => {
				update(state => ({ ...state, inputLayout: layout }));
			};

			client.onDataChannelMessage = (message: string) => {
				update(state => ({ ...state, serverMessage: message }));
			};

			client.onWebRTCStateChange = (webrtcState: RTCPeerConnectionState) => {
				update(state => ({ ...state, webrtcState }));
			};

			client.onWebRTCDataChannelOpen = () => {
				update(state => ({ ...state, webrtcDataChannelOpen: true }));
			};

			client.onReconnecting = (isReconnecting: boolean, attempts: number, maxAttempts: number) => {
				update(state => ({ 
					...state, 
					reconnecting: isReconnecting, 
					reconnectAttempts: attempts,
					maxReconnectAttempts: maxAttempts 
				}));
			};

			try {
				await client.connect();
			} catch (error) {
				update(state => ({ ...state, error: 'Failed to connect to server' }));
				throw error;
			}
		},
		disconnect: () => {
			if (client) {
				client.disconnect();
				client = null;
			}
			set({
				connected: false,
				peerId: null,
				serverIp: null,
				error: null,
				inputLayout: 'joystick',
				webrtcState: null,
				webrtcDataChannelOpen: false,
				reconnecting: false,
				reconnectAttempts: 0,
				maxReconnectAttempts: 5,
				serverMessage: null,
				blocked: false,
			});
		},
		send: (data: any) => {
			if (client) {
				client.send(data);
			}
		},
		sendInput: (input: string, pressed: boolean) => {
			const webrtc = client?.getWebRTCClient();
			if (webrtc) {
				webrtc.sendInput(input, pressed);
			}
		},
		sendMove: (input: string, vector: { x: number; y: number }) => {
			const webrtc = client?.getWebRTCClient();
			if (webrtc) {
				webrtc.sendMove(input, vector);
			}
		},
		sendText: (text: string) => {
			const webrtc = client?.getWebRTCClient();
			if (webrtc) {
				webrtc.sendText(text);
			}
		},
		getClient: () => client,
	};
}

export const connectionStore = createConnectionStore();

export const isConnected = derived(
	connectionStore,
	$connectionStore => $connectionStore.connected
);

export const peerId = derived(
	connectionStore,
	$connectionStore => $connectionStore.peerId
);

export const inputLayout = derived(
	connectionStore,
	$connectionStore => $connectionStore.inputLayout
);

export const webrtcState = derived(
	connectionStore,
	$connectionStore => $connectionStore.webrtcState
);

export const webrtcDataChannelOpen = derived(
	connectionStore,
	$connectionStore => $connectionStore.webrtcDataChannelOpen
);

export const reconnecting = derived(
	connectionStore,
	$connectionStore => $connectionStore.reconnecting
);

export const reconnectAttempts = derived(
	connectionStore,
	$connectionStore => ({ 
		current: $connectionStore.reconnectAttempts, 
		max: $connectionStore.maxReconnectAttempts 
	})
);

export const serverMessage = derived(
	connectionStore,
	$connectionStore => {
		const msg = $connectionStore.serverMessage;
		return msg === null ? null : { text: msg };
	}
);

export const blocked = derived(
	connectionStore,
	$connectionStore => $connectionStore.blocked
);
