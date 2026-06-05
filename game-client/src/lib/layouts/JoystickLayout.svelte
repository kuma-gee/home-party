<script lang="ts">
	import { connectionStore } from '../store';
	import VirtualJoystick from '../VirtualJoystick.svelte';

	interface Props {
		inputLayout: string;
	}

	let { inputLayout }: Props = $props();

	let primaryButtonPressed = $state(false);
	let secondaryButtonPressed = $state(false);

	let primaryButtonTouchId: number | null = null;
	let secondaryButtonTouchId: number | null = null;

	function handleJoystickMove(vector: { x: number; y: number }) {
		connectionStore.sendMove('move', vector);
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
</script>

<div class="game-controls">
	<div class="joystick-container-wrapper">
		<VirtualJoystick inputMode={inputLayout} onmove={(e) => handleJoystickMove(e.detail)} />
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
		<button
			class="action-btn secondary-btn"
			class:pressed={secondaryButtonPressed}
			onmousedown={() => handleActionButtonMouseDown('secondary')}
			onmouseup={() => handleActionButtonMouseUp('secondary')}
			ontouchstart={(e) => handleActionButtonTouchStart(e, 'secondary')}
			ontouchend={(e) => handleActionButtonTouchEnd(e, 'secondary')}
			ontouchcancel={(e) => handleActionButtonTouchEnd(e, 'secondary')}
		>
			B
		</button>
	</div>
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
		align-items: flex-end;
		justify-content: space-between;
		padding: 2rem;
		box-sizing: border-box;
		touch-action: none;
		user-select: none;
	}

	.joystick-container-wrapper {
		display: flex;
		align-items: center;
		justify-content: center;
		padding: 1rem;
	}

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

	.action-btn.pressed {
		transform: scale(0.9);
		box-shadow: 0 2px 6px rgba(0, 0, 0, 0.4);
		filter: brightness(1.2);
	}

	.action-btn:active {
		transform: scale(0.9);
		box-shadow: 0 2px 6px rgba(0, 0, 0, 0.4);
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
	}

	@media (orientation: landscape) and (max-height: 500px) {
		.game-controls {
			padding: 1rem 2rem;
		}

		.action-btn {
			width: 65px;
			height: 65px;
			font-size: 1.5rem;
		}

		.primary-btn {
			width: 75px;
			height: 75px;
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
