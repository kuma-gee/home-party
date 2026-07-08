<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import { connectionStore, isConnected, inputLayout, webrtcDataChannelOpen, reconnecting, reconnectAttempts, blocked } from '../lib/store';
	import JoystickLayout from '../lib/layouts/JoystickLayout.svelte';
	import WordInputLayout from '../lib/layouts/WordInputLayout.svelte';

	let serverIp = $state('');
	let connecting = $state(false);
	let errorMessage = $state('');
	let isFullscreen = $state(false);
	let showFullscreenButton = $state(false);

	async function requestFullscreen() {
		try {
			const elem = document.documentElement;
			if (elem.requestFullscreen) {
				await elem.requestFullscreen();
			} else if ((elem as any).webkitRequestFullscreen) {
				await (elem as any).webkitRequestFullscreen();
			} else if ((elem as any).mozRequestFullScreen) {
				await (elem as any).mozRequestFullScreen();
			} else if ((elem as any).msRequestFullscreen) {
				await (elem as any).msRequestFullscreen();
			}
			isFullscreen = true;
			showFullscreenButton = false;
		} catch (error) {
			console.error('Failed to enter fullscreen:', error);
			showFullscreenButton = true;
		}
	}

	function handleFullscreenChange() {
		isFullscreen = !!(document.fullscreenElement ||
			(document as any).webkitFullscreenElement ||
			(document as any).mozFullScreenElement ||
			(document as any).msFullscreenElement);

		if (!isFullscreen && $webrtcDataChannelOpen) {
			showFullscreenButton = true;
		}
	}

	onMount(() => {
		const urlParams = new URLSearchParams(window.location.search);
		const ipParam = urlParams.get('ip');
		if (ipParam) {
			serverIp = ipParam;
			handleConnect();
		} else {
			serverIp = window.location.hostname || 'localhost';
		}

		document.addEventListener('fullscreenchange', handleFullscreenChange);
		document.addEventListener('webkitfullscreenchange', handleFullscreenChange);
		document.addEventListener('mozfullscreenchange', handleFullscreenChange);
		document.addEventListener('MSFullscreenChange', handleFullscreenChange);

		if (screen.orientation && (screen.orientation as any).lock) {
			(screen.orientation as any).lock('landscape').catch((err: any) => {
				console.log('Orientation lock not supported or failed:', err);
			});
		}
	});

	onDestroy(() => {
		connectionStore.disconnect();

		document.removeEventListener('fullscreenchange', handleFullscreenChange);
		document.removeEventListener('webkitfullscreenchange', handleFullscreenChange);
		document.removeEventListener('mozfullscreenchange', handleFullscreenChange);
		document.removeEventListener('MSFullscreenChange', handleFullscreenChange);
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
			await requestFullscreen();
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
</script>

<div class="container">
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

			<button onclick={handleConnect} disabled={connecting || !serverIp || $reconnecting}>
				{connecting ? 'Connecting...' : $reconnecting ? 'Reconnecting...' : 'Connect'}
			</button>

			{#if errorMessage}
				<p class="error">{errorMessage}</p>
			{/if}
		</div>
	{:else if $blocked}
		<div class="blocked-screen">
			<div class="blocked-content">
				<div class="blocked-icon">🚫</div>
				<h2>Game Already Started</h2>
				<p>This game is in progress. Wait for the next round to join.</p>
				<button onclick={handleDisconnect} class="cancel-btn">Disconnect</button>
			</div>
		</div>
	{:else}
		{#if $webrtcDataChannelOpen}
			<div class="status-corner">
				<button onclick={handleDisconnect} class="disconnect-icon" title="Disconnect">✕</button>
				{#if showFullscreenButton}
					<button onclick={requestFullscreen} class="fullscreen-icon" title="Enter Fullscreen">⛶</button>
				{/if}
			</div>

		{#if $inputLayout == 'guess'}
			<WordInputLayout />
		{:else}
			<JoystickLayout inputLayout={$inputLayout} />
		{/if}
		{:else}
			<div class="connecting-screen">
				<div class="connecting-content">
					<div class="spinner"></div>
					<h2>{$reconnecting ? 'Reconnecting...' : 'Connecting...'}</h2>
					{#if $reconnecting}
						<p class="reconnect-attempts">
							Attempt {$reconnectAttempts.current} of {$reconnectAttempts.max}
						</p>
					{/if}
					<button onclick={handleDisconnect} class="cancel-btn">Cancel</button>
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

	h2 {
		color: #555;
		margin-bottom: 1rem;
	}

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

	.connecting-screen {
		position: fixed;
		top: 0;
		left: 0;
		width: 100vw;
		height: 100vh;
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		display: flex;
		align-items: center;
		justify-content: center;
		padding: 2rem;
		box-sizing: border-box;
	}

	.connecting-content {
		background: rgba(255, 255, 255, 0.95);
		border-radius: 16px;
		padding: 3rem 2rem;
		max-width: 400px;
		width: 100%;
		text-align: center;
		box-shadow: 0 8px 32px rgba(0, 0, 0, 0.2);
	}

	.spinner {
		width: 60px;
		height: 60px;
		border: 4px solid rgba(102, 126, 234, 0.2);
		border-top-color: #667eea;
		border-radius: 50%;
		animation: spin 1s linear infinite;
		margin: 0 auto 2rem;
	}

	@keyframes spin {
		to { transform: rotate(360deg); }
	}

	.connecting-content h2 {
		color: #333;
		margin-bottom: 2rem;
		font-size: 1.5rem;
	}

	.blocked-screen {
		position: fixed;
		top: 0;
		left: 0;
		width: 100vw;
		height: 100vh;
		background: linear-gradient(135deg, #eb5757 0%, #7a1f1f 100%);
		display: flex;
		align-items: center;
		justify-content: center;
		padding: 2rem;
		box-sizing: border-box;
	}

	.blocked-content {
		background: rgba(255, 255, 255, 0.95);
		border-radius: 16px;
		padding: 3rem 2rem;
		max-width: 400px;
		width: 100%;
		text-align: center;
		box-shadow: 0 8px 32px rgba(0, 0, 0, 0.2);
	}

	.blocked-icon {
		font-size: 4rem;
		margin-bottom: 1.5rem;
	}

	.blocked-content h2 {
		color: #333;
		margin-bottom: 1rem;
		font-size: 1.5rem;
	}

	.blocked-content p {
		color: #666;
		margin-bottom: 2rem;
	}

	.cancel-btn {
		background-color: #f44336;
		max-width: 200px;
		margin: 0 auto;
	}

	.cancel-btn:hover {
		background-color: #da190b;
	}

	.status-corner {
		position: fixed;
		top: 1rem;
		right: 1rem;
		display: flex;
		align-items: center;
		gap: 0.5rem;
		z-index: 100;
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

	.fullscreen-icon {
		width: 36px;
		height: 36px;
		padding: 0;
		background: rgba(33, 150, 243, 0.9);
		border-radius: 50%;
		display: flex;
		align-items: center;
		justify-content: center;
		font-size: 1.25rem;
		line-height: 1;
		transition: all 0.2s;
	}

	.fullscreen-icon:hover {
		background: rgba(33, 150, 243, 1);
		transform: scale(1.1);
	}

	.reconnect-attempts {
		color: #ff9800;
		font-size: 1rem;
		font-weight: 600;
		margin: -0.5rem 0 1.5rem;
	}

	@media (max-width: 768px), (max-height: 450px) {
		.status-corner {
			top: 0.75rem;
			right: 0.75rem;
		}
	}

	@media (orientation: landscape) and (max-height: 500px) {
		.status-corner {
			top: 0.5rem;
			right: 0.5rem;
		}
	}
</style>
