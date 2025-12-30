// Export WebSocket client and store for easy imports
export { WebSocketClient, MessageType } from './websocket';
export { connectionStore, isConnected, peerId, webrtcState, webrtcDataChannelOpen, dataChannelMessage, reconnecting, reconnectAttempts } from './store';
export type { Message, IdMessage, SessionMessage, IceCandidateMessage } from './websocket';
