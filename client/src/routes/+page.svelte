<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import { connectionStore, isConnected, peerId } from '$lib/store';
	import { page } from '$app/stores';

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

	.error {
		color: #f44336;
		margin-top: 1rem;
		padding: 0.75rem;
		background-color: #ffebee;
		border-radius: 4px;
		text-align: center;
	}
</style>
