<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import { connectionStore, isConnected, peerId, webrtcState, webrtcDataChannelOpen } from '$lib/store';
	import { page } from '$app/stores';
	import VirtualJoystick from '$lib/VirtualJoystick.svelte';

	let serverIp = $state('');
	let connecting = $state(false);
	let errorMessage = $state('');

	onMount(() => {
		// Get server IP from URL parameters
		const urlParams = new URLSearchParams(window.location.search);
		const ipParam = urlParams.get('ip');
		if (ipParam) {
			serverIp = ipParam;
			// Auto-connect if IP is provided in URL
			handleConnect();
		}
	});

	onDestroy(() => {
		connectionStore.disconnect();
	});

	async function handleConnect() {
		if (!serverIp) {
			errorMessage = 'Please enter a server IP address';
			return;
		}

		connecting = true;
		errorMessage = '';

		try {
			await connectionStore.connect(serverIp);
		} catch (error) {
			errorMessage = 'Failed to connect to server';
			console.error(error);
		} finally {
			connecting = false;
		}
	}

	function handleDisconnect() {
		connectionStore.disconnect();
		errorMessage = '';
	}

	function sendTestInput(input: string, pressed: boolean) {
		connectionStore.sendInput(input, pressed);
	}

	function handleButtonPress(input: string) {
		sendTestInput(input, true);
		setTimeout(() => sendTestInput(input, false), 100);
	}

	function handleJoystickMove(vector: { x: number; y: number }) {
		connectionStore.sendMove('move', vector);
	}


</script>

<div class="container">
	<h1>Home Party Game Client</h1>

	{#if !$isConnected}
		<div class="connection-form">
			<h2>Connect to Game Server</h2>
			<div class="input-group">
				<label for="server-ip">Server IP Address:</label>
				<input
					id="server-ip"
					type="text"
					bind:value={serverIp}
					placeholder="192.168.1.100"
					disabled={connecting}
				/>
			</div>

			<button onclick={handleConnect} disabled={connecting || !serverIp}>
				{connecting ? 'Connecting...' : 'Connect'}
			</button>

			{#if errorMessage}
				<p class="error">{errorMessage}</p>
			{/if}
		</div>
	{:else}
		<div class="connected-info">
			<h2>Connected to Server</h2>
			<p><strong>Server IP:</strong> {serverIp}</p>
			<p><strong>Your Player ID:</strong> {$peerId ?? 'Waiting...'}</p>
			<p><strong>WebRTC State:</strong> <span class="status-badge status-{$webrtcState}">{$webrtcState ?? 'initializing'}</span></p>
			<p><strong>Data Channel:</strong> <span class="status-badge status-{$webrtcDataChannelOpen ? 'open' : 'closed'}">{$webrtcDataChannelOpen ? 'Open' : 'Closed'}</span></p>
			
			{#if $webrtcDataChannelOpen}
				<div class="controls-section">
					<h3>Test Controls</h3>
					<div class="button-grid">
						<button onclick={() => handleButtonPress('jump')} class="control-btn">
							Jump
						</button>
						<button onclick={() => handleButtonPress('action')} class="control-btn">
							Action
						</button>
						<button onclick={() => handleButtonPress('interact')} class="control-btn">
							Interact
						</button>
						<button onclick={() => handleButtonPress('menu')} class="control-btn">
							Menu
						</button>
					</div>

					<div class="joystick-section">
						<h4>Movement</h4>
						<VirtualJoystick onMove={handleJoystickMove} />
					</div>
				</div>
			{/if}

			<button onclick={handleDisconnect} class="disconnect-btn">Disconnect</button>
		</div>
	{/if}
</div>

<style>
	.container {
		max-width: 600px;
		margin: 0 auto;
		padding: 2rem;
		font-family: system-ui, -apple-system, sans-serif;
	}

	h1 {
		text-align: center;
		color: #333;
		margin-bottom: 2rem;
	}

	h2 {
		color: #555;
		margin-bottom: 1rem;
	}

	.connection-form,
	.connected-info {
		background: #f5f5f5;
		padding: 2rem;
		border-radius: 8px;
		box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
	}

	.input-group {
		margin-bottom: 1.5rem;
	}

	label {
		display: block;
		margin-bottom: 0.5rem;
		font-weight: 500;
		color: #555;
	}

	input {
		width: 100%;
		padding: 0.75rem;
		font-size: 1rem;
		border: 2px solid #ddd;
		border-radius: 4px;
		box-sizing: border-box;
	}

	input:focus {
		outline: none;
		border-color: #4CAF50;
	}

	input:disabled {
		background-color: #e9e9e9;
		cursor: not-allowed;
	}

	button {
		width: 100%;
		padding: 0.75rem;
		font-size: 1rem;
		font-weight: 600;
		color: white;
		background-color: #4CAF50;
		border: none;
		border-radius: 4px;
		cursor: pointer;
		transition: background-color 0.3s;
	}

	button:hover:not(:disabled) {
		background-color: #45a049;
	}

	button:disabled {
		background-color: #cccccc;
		cursor: not-allowed;
	}

	.disconnect-btn {
		background-color: #f44336;
		margin-top: 1rem;
	}

	.disconnect-btn:hover {
		background-color: #da190b;
	}

	.connected-info p {
		margin: 0.5rem 0;
		font-size: 1.1rem;
	}

	.status-badge {
		padding: 0.25rem 0.75rem;
		border-radius: 12px;
		font-size: 0.9rem;
		font-weight: 600;
		text-transform: uppercase;
	}

	.status-connected,
	.status-open {
		background-color: #4CAF50;
		color: white;
	}

	.status-connecting,
	.status-new {
		background-color: #2196F3;
		color: white;
	}

	.status-disconnected,
	.status-closed,
	.status-failed {
		background-color: #f44336;
		color: white;
	}

	.controls-section {
		margin: 2rem 0 1rem;
		padding: 1.5rem;
		background: white;
		border-radius: 8px;
		border: 2px solid #4CAF50;
	}

	.controls-section h3 {
		margin: 0 0 1rem 0;
		color: #333;
		text-align: center;
	}

	.joystick-section {
		margin-top: 2rem;
		padding-top: 1.5rem;
		border-top: 2px solid #e0e0e0;
		display: flex;
		flex-direction: column;
		align-items: center;
	}

	.joystick-section h4 {
		margin: 0 0 1rem 0;
		color: #555;
		font-size: 1rem;
		font-weight: 600;
	}

	.button-grid {
		display: grid;
		grid-template-columns: repeat(2, 1fr);
		gap: 1rem;
	}

	.control-btn {
		background-color: #2196F3;
		padding: 1.5rem;
		font-size: 1.1rem;
		font-weight: 700;
		transition: all 0.2s;
	}

	.control-btn:hover {
		background-color: #1976D2;
		transform: scale(1.05);
	}

	.control-btn:active {
		transform: scale(0.95);
	}

	.error {
		color: #f44336;
		margin-top: 1rem;
		padding: 0.75rem;
		background-color: #ffebee;
		border-radius: 4px;
		text-align: center;
	}
</style>
