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
		} else {
			// Prefill with current domain/hostname
			serverIp = window.location.hostname || 'localhost';
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

	function handleButtonDown(input: string) {
		sendTestInput(input, true);
	}

	function handleButtonUp(input: string) {
		sendTestInput(input, false);
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
		<!-- Connection Status Badge -->
		<div class="status-corner">
			<div class="status-indicator" class:connected={$webrtcDataChannelOpen}>
				{#if $webrtcDataChannelOpen}
					<span class="status-dot"></span>
					<span class="status-text">Connected</span>
				{:else}
					<span class="status-text">Connecting...</span>
				{/if}
			</div>
			<button onclick={handleDisconnect} class="disconnect-icon" title="Disconnect">✕</button>
		</div>

		{#if $webrtcDataChannelOpen}
			<!-- Game Controls -->
			<div class="game-controls">
				<!-- Joystick (Bottom Left) -->
				<div class="joystick-container-wrapper">
					<VirtualJoystick onMove={handleJoystickMove} />
				</div>

				<!-- Action Buttons (Bottom Right) -->
				<div class="action-buttons">
					<button 
						class="action-btn secondary-btn"
						ontouchstart={() => handleButtonDown('action2')}
						ontouchend={() => handleButtonUp('action2')}
						onmousedown={() => handleButtonDown('action2')}
						onmouseup={() => handleButtonUp('action2')}
					>
						B
					</button>
					<button 
						class="action-btn primary-btn"
						ontouchstart={() => handleButtonDown('action')}
						ontouchend={() => handleButtonUp('action')}
						onmousedown={() => handleButtonDown('action')}
						onmouseup={() => handleButtonUp('action')}
					>
						A
					</button>
				</div>
			</div>
		{/if}
	{/if}
</div>

<style>
	.container {
		width: 100vw;
		height: 100vh;
		margin: 0;
		padding: 0;
		font-family: system-ui, -apple-system, sans-serif;
		position: relative;
		overflow: hidden;
	}

	h1 {
		text-align: center;
		color: #333;
		margin: 2rem 0;
		padding: 0 2rem;
	}

	h2 {
		color: #555;
		margin-bottom: 1rem;
	}

	/* Connection Form Styles */
	.connection-form {
		max-width: 400px;
		margin: 2rem auto;
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

	.error {
		color: #f44336;
		margin-top: 1rem;
		padding: 0.75rem;
		background-color: #ffebee;
		border-radius: 4px;
		text-align: center;
	}

	/* Game Controls - Full Screen Layout */
	.game-controls {
		position: fixed;
		top: 0;
		left: 0;
		width: 100vw;
		height: 100vh;
		display: flex;
		align-items: flex-end;
		justify-content: space-between;
		padding: 2rem;
		box-sizing: border-box;
		touch-action: none;
		user-select: none;
	}

	/* Status Corner Badge */
	.status-corner {
		position: fixed;
		top: 1rem;
		right: 1rem;
		display: flex;
		align-items: center;
		gap: 0.5rem;
		z-index: 100;
	}

	.status-indicator {
		display: flex;
		align-items: center;
		gap: 0.5rem;
		background: rgba(0, 0, 0, 0.6);
		backdrop-filter: blur(10px);
		padding: 0.5rem 1rem;
		border-radius: 20px;
		color: white;
		font-size: 0.875rem;
		font-weight: 500;
	}

	.status-indicator.connected {
		background: rgba(76, 175, 80, 0.8);
	}

	.status-dot {
		width: 8px;
		height: 8px;
		background: #4CAF50;
		border-radius: 50%;
		animation: pulse 2s infinite;
	}

	@keyframes pulse {
		0%, 100% {
			opacity: 1;
		}
		50% {
			opacity: 0.5;
		}
	}

	.disconnect-icon {
		width: 36px;
		height: 36px;
		padding: 0;
		background: rgba(244, 67, 54, 0.9);
		border-radius: 50%;
		display: flex;
		align-items: center;
		justify-content: center;
		font-size: 1.25rem;
		line-height: 1;
		transition: all 0.2s;
	}

	.disconnect-icon:hover {
		background: rgba(244, 67, 54, 1);
		transform: scale(1.1);
	}

	/* Joystick Container */
	.joystick-container-wrapper {
		display: flex;
		align-items: center;
		justify-content: center;
		padding: 1rem;
	}

	/* Action Buttons */
	.action-buttons {
		display: flex;
		gap: 1.5rem;
		align-items: center;
	}

	.action-btn {
		width: 80px;
		height: 80px;
		border-radius: 50%;
		border: 4px solid rgba(255, 255, 255, 0.3);
		font-size: 2rem;
		font-weight: 700;
		display: flex;
		align-items: center;
		justify-content: center;
		box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
		transition: all 0.15s ease;
		touch-action: none;
		user-select: none;
		-webkit-tap-highlight-color: transparent;
	}

	.action-btn:active {
		transform: scale(0.9);
		box-shadow: 0 2px 6px rgba(0, 0, 0, 0.4);
	}

	.primary-btn {
		background: linear-gradient(135deg, #FF6B6B 0%, #EE5A6F 100%);
		width: 90px;
		height: 90px;
	}

	.secondary-btn {
		background: linear-gradient(135deg, #4ECDC4 0%, #44A08D 100%);
	}

	/* Mobile Optimizations */
	@media (max-width: 768px) {
		.game-controls {
			padding: 1.5rem;
		}

		.action-btn {
			width: 70px;
			height: 70px;
			font-size: 1.75rem;
		}

		.primary-btn {
			width: 80px;
			height: 80px;
		}

		.status-corner {
			top: 0.75rem;
			right: 0.75rem;
		}

		.status-text {
			display: none;
		}

		.status-indicator {
			padding: 0.5rem;
		}
	}

	@media (max-height: 600px) {
		.game-controls {
			padding: 1rem;
		}

		.action-btn {
			width: 60px;
			height: 60px;
			font-size: 1.5rem;
		}

		.primary-btn {
			width: 70px;
			height: 70px;
		}
	}
</style>
