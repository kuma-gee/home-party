import { writable, derived } from 'svelte/store';
import { WebSocketClient, type Message } from './websocket';

export interface ConnectionState {
	connected: boolean;
	peerId: number | null;
	serverIp: string | null;
	error: string | null;
	webrtcState: RTCPeerConnectionState | null;
	webrtcDataChannelOpen: boolean;
}

function createConnectionStore() {
	const { subscribe, set, update } = writable<ConnectionState>({
		connected: false,
		peerId: null,
		serverIp: null,
		error: null,
		webrtcState: null,
		webrtcDataChannelOpen: false,
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
				update(state => ({ ...state, connected: true, serverIp, error: null }));
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

			client.onWebRTCStateChange = (webrtcState: RTCPeerConnectionState) => {
				update(state => ({ ...state, webrtcState }));
			};

			client.onWebRTCDataChannelOpen = () => {
				update(state => ({ ...state, webrtcDataChannelOpen: true }));
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
				webrtcState: null,
				webrtcDataChannelOpen: false,
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

export const webrtcState = derived(
	connectionStore,
	$connectionStore => $connectionStore.webrtcState
);

export const webrtcDataChannelOpen = derived(
	connectionStore,
	$connectionStore => $connectionStore.webrtcDataChannelOpen
);
