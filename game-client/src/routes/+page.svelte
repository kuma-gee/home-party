<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import { connectionStore, isConnected, inputLayout, webrtcState, webrtcDataChannelOpen, reconnecting, reconnectAttempts } from '../lib/store';
	import JoystickLayout from '../lib/layouts/JoystickLayout.svelte';
	import SkillSelectLayout from '../lib/layouts/SkillSelectLayout.svelte';

	let serverIp = $state('');
	let connecting = $state(false);
	let errorMessage = $state('');
	let isFullscreen = $state(false);
	let showFullscreenButton = $state(false);
	let playerName = $state('');

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

		const savedName = localStorage.getItem('playerName');
		if (savedName) {
			playerName = savedName;
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

		if (!playerName.trim()) {
			errorMessage = 'Please enter your name';
			return;
		}

		connecting = true;
		errorMessage = '';

		try {
			localStorage.setItem('playerName', playerName.trim());
			await connectionStore.connect(serverIp, playerName.trim());
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
				<label for="player-name">Your Name:</label>
				<input
					id="player-name"
					type="text"
					bind:value={playerName}
					placeholder="Enter your name"
					disabled={connecting}
					maxlength="20"
				/>
			</div>
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

			<button onclick={handleConnect} disabled={connecting || !serverIp || !playerName || $reconnecting}>
				{connecting ? 'Connecting...' : $reconnecting ? 'Reconnecting...' : 'Connect'}
			</button>

			{#if errorMessage}
				<p class="error">{errorMessage}</p>
			{/if}

			{#if $reconnecting}
				<div class="reconnect-indicator">
					<div class="spinner-small"></div>
					<p class="reconnect-text">
						Attempting to reconnect ({$reconnectAttempts.current}/{$reconnectAttempts.max})...
					</p>
				</div>
			{/if}
		</div>
	{:else}
		{#if $webrtcDataChannelOpen}
			<div class="status-corner">
				<div class="status-indicator connected">
					<span class="status-dot"></span>
					<span class="status-text">Connected</span>
				</div>
				<button onclick={handleDisconnect} class="disconnect-icon" title="Disconnect">✕</button>
				{#if showFullscreenButton}
					<button onclick={requestFullscreen} class="fullscreen-icon" title="Enter Fullscreen">⛶</button>
				{/if}
			</div>

			{#if $inputLayout === 'skill_select'}
				<SkillSelectLayout />
			{:else}
				<JoystickLayout inputLayout={$inputLayout} />
			{/if}
		{:else}
			<div class="connecting-screen">
				<div class="connecting-content">
					<div class="spinner"></div>
					<h2>{$reconnecting ? 'Reconnecting to Game Server' : 'Connecting to Game Server'}</h2>
					{#if $reconnecting}
						<p class="reconnect-attempts">
							Attempt {$reconnectAttempts.current} of {$reconnectAttempts.max}
						</p>
					{/if}
					<div class="connection-steps">
						<div class="step" class:active={$isConnected}>
							<span class="step-icon">{$isConnected ? '✓' : '○'}</span>
							<span class="step-text">WebSocket Connection</span>
						</div>
						<div class="step" class:active={$webrtcState === 'connected'}>
							<span class="step-icon">{$webrtcState === 'connected' ? '✓' : '○'}</span>
							<span class="step-text">WebRTC Connection</span>
						</div>
						<div class="step" class:active={$webrtcDataChannelOpen}>
							<span class="step-icon">{$webrtcDataChannelOpen ? '✓' : '○'}</span>
							<span class="step-text">Data Channel</span>
						</div>
					</div>
					<p class="connecting-hint">{$reconnecting ? 'Please wait while we try to reconnect...' : 'Please wait...'}</p>
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

	.connection-steps {
		display: flex;
		flex-direction: column;
		gap: 1rem;
		margin-bottom: 2rem;
		text-align: left;
	}

	.step {
		display: flex;
		align-items: center;
		gap: 1rem;
		padding: 0.75rem;
		border-radius: 8px;
		background: rgba(0, 0, 0, 0.05);
		transition: all 0.3s ease;
	}

	.step.active {
		background: rgba(76, 175, 80, 0.15);
	}

	.step-icon {
		width: 24px;
		height: 24px;
		border-radius: 50%;
		display: flex;
		align-items: center;
		justify-content: center;
		font-size: 0.875rem;
		font-weight: 700;
		background: rgba(0, 0, 0, 0.1);
		color: #666;
		flex-shrink: 0;
	}

	.step.active .step-icon {
		background: #4CAF50;
		color: white;
	}

	.step-text {
		flex: 1;
		color: #666;
		font-size: 0.95rem;
	}

	.step.active .step-text {
		color: #333;
		font-weight: 600;
	}

	.connecting-hint {
		color: #666;
		font-size: 0.9rem;
		margin-bottom: 1.5rem;
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
		0%, 100% { opacity: 1; }
		50% { opacity: 0.5; }
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

	.reconnect-indicator {
		display: flex;
		align-items: center;
		justify-content: center;
		gap: 0.75rem;
		margin-top: 1rem;
		padding: 0.75rem;
		background-color: #fff3cd;
		border: 1px solid #ffc107;
		border-radius: 4px;
		color: #856404;
	}

	.spinner-small {
		width: 20px;
		height: 20px;
		border: 3px solid rgba(255, 193, 7, 0.3);
		border-top-color: #ffc107;
		border-radius: 50%;
		animation: spin 1s linear infinite;
	}

	.reconnect-text {
		margin: 0;
		font-size: 0.9rem;
		font-weight: 500;
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

		.status-text {
			display: none;
		}

		.status-indicator {
			padding: 0.5rem;
		}
	}

	@media (orientation: landscape) and (max-height: 500px) {
		.status-corner {
			top: 0.5rem;
			right: 0.5rem;
		}
	}
</style>
