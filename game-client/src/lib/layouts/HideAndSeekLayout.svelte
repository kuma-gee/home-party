<script lang="ts">
	import { connectionStore } from '../store';
	import VirtualJoystick from '../VirtualJoystick.svelte';

	let primaryButtonPressed = $state(false);
	let secondaryButtonPressed = $state(false);
	let primaryButtonTouchId: number | null = null;
	let secondaryButtonTouchId: number | null = null;

	// Game state
	let gamePhase = $state<'setup' | 'hunt' | 'found'>('setup');
	let setupTime = $state(8);
	let huntTime = $state(120);
	let selectedProp = $state<string | null>(null);
	let highlightedProp = $state<string | null>(null);

	// Cooldowns
	let distractCooldown = $state(0);
	let swapCooldown = $state(0);
	let swapBlocked = $state(0);

	// Prop positions (received from server)
	interface PropInfo {
		name: string;
		x: number;
		z: number;
	}
	let props = $state<PropInfo[]>([]);

	// Found screen
	let foundMessage = $state('You\'ve been found!');

	function handleJoystickMove(vector: { x: number; y: number }) {
		if (gamePhase === 'hunt') {
			connectionStore.sendMove('move', vector);
		}
	}

	function handleActionButtonTouchStart(event: TouchEvent, action: 'primary' | 'secondary') {
		event.preventDefault();
		const touch = event.changedTouches[0];

		if (action === 'primary' && primaryButtonTouchId === null) {
			primaryButtonTouchId = touch.identifier;
			primaryButtonPressed = true;
			connectionStore.sendInput('action', true);
		} else if (action === 'secondary' && secondaryButtonTouchId === null) {
			secondaryButtonTouchId = touch.identifier;
			secondaryButtonPressed = true;
			connectionStore.sendInput('secondary', true);
		}
	}

	function handleActionButtonTouchEnd(event: TouchEvent, action: 'primary' | 'secondary') {
		event.preventDefault();

		for (let i = 0; i < event.changedTouches.length; i++) {
			const touch = event.changedTouches[i];

			if (action === 'primary' && touch.identifier === primaryButtonTouchId) {
				primaryButtonTouchId = null;
				primaryButtonPressed = false;
				connectionStore.sendInput('action', false);
			} else if (action === 'secondary' && touch.identifier === secondaryButtonTouchId) {
				secondaryButtonTouchId = null;
				secondaryButtonPressed = false;
				connectionStore.sendInput('secondary', false);
			}
		}
	}

	function handleActionButtonMouseDown(action: 'primary' | 'secondary') {
		if (action === 'primary') {
			primaryButtonPressed = true;
			connectionStore.sendInput('action', true);
		} else {
			secondaryButtonPressed = true;
			connectionStore.sendInput('secondary', true);
		}
	}

	function handleActionButtonMouseUp(action: 'primary' | 'secondary') {
		if (action === 'primary') {
			primaryButtonPressed = false;
			connectionStore.sendInput('action', false);
		} else {
			secondaryButtonPressed = false;
			connectionStore.sendInput('secondary', false);
		}
	}

	function formatCooldown(seconds: number): string {
		if (seconds <= 0) return 'Ready';
		return Math.ceil(seconds) + 's';
	}

	function isDistractReady(): boolean {
		return distractCooldown <= 0 && swapBlocked <= 0;
	}

	function isSwapReady(): boolean {
		return swapCooldown <= 0 && swapBlocked <= 0;
	}

	// Listen for server messages (game state updates)
	function handleServerMessage(msg: string) {
		try {
			const data = JSON.parse(msg);
			if (data.type === 'phase') {
				gamePhase = data.phase;
			} else if (data.type === 'props') {
				props = data.props;
			} else if (data.type === 'found') {
				gamePhase = 'found';
				foundMessage = data.message || 'You\'ve been found!';
			} else if (data.type === 'timer') {
				if (gamePhase === 'setup') {
					setupTime = Math.ceil(data.time);
				} else if (gamePhase === 'hunt') {
					huntTime = Math.ceil(data.time);
				}
			} else if (data.type === 'cooldowns') {
				distractCooldown = data.distract || 0;
				swapCooldown = data.swap || 0;
				swapBlocked = data.swap_blocked || 0;
			}
		} catch {
			// Ignore non-JSON messages
		}
	}

	// Subscribe to server messages
	$effect(() => {
		const client = connectionStore.getClient();
		if (client) {
			client.onDataChannelMessage = (msg: string) => {
				handleServerMessage(msg);
			};
		}
	});
</script>

<div class="game-controls">
	{#if gamePhase === 'found'}
		<div class="found-screen">
			<h1>🎯</h1>
			<h2>{foundMessage}</h2>
			<p>Wait for the round to end...</p>
		</div>
	{:else if gamePhase === 'setup'}
		<div class="setup-screen">
			<div class="setup-header">
				<h2>Choose Your Prop</h2>
				<div class="timer">{setupTime}s</div>
			</div>
			
			<div class="prop-map">
				{#each props as prop (prop.name)}
					<div 
						class="prop-dot" 
						class:highlighted={prop.name === highlightedProp}
						class:selected={prop.name === selectedProp}
						style="left: {(prop.x + 3) / 6 * 100}%; top: {(prop.z + 3) / 6 * 100}%;"
					>
						{prop.name}
					</div>
				{/each}
			</div>
			
			<div class="setup-instructions">
				<p>Hold A to highlight, release to select</p>
			</div>
			
			<div class="action-buttons">
				<button
					class="action-btn primary-btn"
					class:pressed={primaryButtonPressed}
					onmousedown={() => handleActionButtonMouseDown('primary')}
					onmouseup={() => handleActionButtonMouseUp('primary')}
					ontouchstart={(e) => handleActionButtonTouchStart(e, 'primary')}
					ontouchend={(e) => handleActionButtonTouchEnd(e, 'primary')}
					ontouchcancel={(e) => handleActionButtonTouchEnd(e, 'primary')}
				>
					A
				</button>
			</div>
		</div>
	{:else}
		<!-- Hunt phase: joystick + A/B buttons with cooldowns -->
		<div class="status-bar">
			<div class="timer">{huntTime}s</div>
		</div>
		
		<div class="cooldown-bar">
			<div class="cooldown-item" class:ready={isDistractReady()} class:on-cooldown={!isDistractReady()}>
				<span class="cooldown-label">Distract</span>
				<span class="cooldown-value">{formatCooldown(distractCooldown)}</span>
				{#if swapBlocked > 0}
					<span class="cooldown-blocked">🔒</span>
				{/if}
			</div>
			<div class="cooldown-item" class:ready={isSwapReady()} class:on-cooldown={!isSwapReady()}>
				<span class="cooldown-label">Swap</span>
				<span class="cooldown-value">{formatCooldown(swapCooldown)}</span>
				{#if swapBlocked > 0}
					<span class="cooldown-blocked">🔒</span>
				{/if}
			</div>
		</div>
		
		<div class="joystick-container-wrapper">
			<VirtualJoystick inputMode="joystick" onmove={(e) => handleJoystickMove(e.detail)} />
		</div>

		<div class="action-buttons">
			<button
				class="action-btn primary-btn"
				class:pressed={primaryButtonPressed}
				class:disabled={!isSwapReady()}
				onmousedown={() => handleActionButtonMouseDown('primary')}
				onmouseup={() => handleActionButtonMouseUp('primary')}
				ontouchstart={(e) => handleActionButtonTouchStart(e, 'primary')}
				ontouchend={(e) => handleActionButtonTouchEnd(e, 'primary')}
				ontouchcancel={(e) => handleActionButtonTouchEnd(e, 'primary')}
			>
				A
			</button>
			<button
				class="action-btn secondary-btn"
				class:pressed={secondaryButtonPressed}
				class:disabled={!isDistractReady()}
				onmousedown={() => handleActionButtonMouseDown('secondary')}
				onmouseup={() => handleActionButtonMouseUp('secondary')}
				ontouchstart={(e) => handleActionButtonTouchStart(e, 'secondary')}
				ontouchend={(e) => handleActionButtonTouchEnd(e, 'secondary')}
				ontouchcancel={(e) => handleActionButtonTouchEnd(e, 'secondary')}
			>
				B
			</button>
		</div>
	{/if}
</div>

<style>
	.game-controls {
		position: fixed;
		top: 0;
		left: 0;
		width: 100vw;
		height: 100vh;
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		display: flex;
		flex-direction: column;
		align-items: center;
		touch-action: none;
		user-select: none;
	}

	.found-screen {
		text-align: center;
		color: white;
		margin-top: 20vh;
	}

	.found-screen h1 {
		font-size: 4rem;
		margin-bottom: 1rem;
	}

	.found-screen h2 {
		font-size: 2rem;
		margin-bottom: 0.5rem;
	}

	.found-screen p {
		font-size: 1rem;
		opacity: 0.7;
	}

	.setup-screen {
		width: 100%;
		height: 100%;
		display: flex;
		flex-direction: column;
		color: white;
	}

	.setup-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		padding: 1rem;
	}

	.setup-header h2 {
		margin: 0;
	}

	.timer {
		font-size: 1.5rem;
		font-weight: bold;
		background: rgba(0, 0, 0, 0.3);
		padding: 0.5rem 1rem;
		border-radius: 8px;
	}

	.prop-map {
		flex: 1;
		position: relative;
		margin: 1rem;
		background: rgba(0, 0, 0, 0.2);
		border-radius: 12px;
		border: 2px solid rgba(255, 255, 255, 0.2);
	}

	.prop-dot {
		position: absolute;
		transform: translate(-50%, -50%);
		width: 40px;
		height: 40px;
		background: rgba(255, 255, 255, 0.3);
		border: 2px solid rgba(255, 255, 255, 0.5);
		border-radius: 50%;
		display: flex;
		align-items: center;
		justify-content: center;
		font-size: 0.5rem;
		color: white;
		transition: all 0.2s;
	}

	.prop-dot.highlighted {
		background: rgba(255, 255, 0, 0.5);
		border-color: yellow;
		transform: translate(-50%, -50%) scale(1.3);
	}

	.prop-dot.selected {
		background: rgba(0, 255, 0, 0.5);
		border-color: lime;
	}

	.setup-instructions {
		text-align: center;
		padding: 0.5rem;
		opacity: 0.7;
	}

	.status-bar {
		position: absolute;
		top: 1rem;
		left: 50%;
		transform: translateX(-50%);
	}

	.cooldown-bar {
		display: flex;
		gap: 1rem;
		padding: 0.5rem 1rem;
		margin-top: 3.5rem;
	}

	.cooldown-item {
		display: flex;
		flex-direction: column;
		align-items: center;
		background: rgba(0, 0, 0, 0.3);
		padding: 0.4rem 0.8rem;
		border-radius: 8px;
		min-width: 80px;
	}

	.cooldown-item.ready {
		background: rgba(76, 175, 80, 0.4);
		border: 1px solid rgba(76, 175, 80, 0.6);
	}

	.cooldown-item.on-cooldown {
		background: rgba(255, 152, 0, 0.3);
		border: 1px solid rgba(255, 152, 0, 0.5);
	}

	.cooldown-label {
		font-size: 0.65rem;
		color: rgba(255, 255, 255, 0.8);
		text-transform: uppercase;
	}

	.cooldown-value {
		font-size: 0.9rem;
		font-weight: bold;
		color: white;
	}

	.cooldown-blocked {
		font-size: 0.7rem;
	}

	.joystick-container-wrapper {
		display: flex;
		align-items: center;
		justify-content: center;
		padding: 1rem;
		flex: 1;
	}

	.action-buttons {
		display: flex;
		gap: 1.5rem;
		align-items: center;
		padding: 2rem;
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

	.action-btn.pressed {
		transform: scale(0.9);
		box-shadow: 0 2px 6px rgba(0, 0, 0, 0.4);
		filter: brightness(1.2);
	}

	.action-btn.disabled {
		opacity: 0.4;
		filter: grayscale(0.5);
	}

	.primary-btn {
		background: linear-gradient(135deg, #5DC15B 0%, #4CAF50 100%);
		width: 90px;
		height: 90px;
	}

	.secondary-btn {
		background: linear-gradient(135deg, #EE4B2B 0%, #C0392B 100%);
	}

	@media (max-width: 768px), (max-height: 450px) {
		.action-btn {
			width: 70px;
			height: 70px;
			font-size: 1.75rem;
		}

		.primary-btn {
			width: 80px;
			height: 80px;
		}
	}
</style>
