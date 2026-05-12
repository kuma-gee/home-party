<script lang="ts">
	import { onMount, onDestroy } from 'svelte';

	interface Props {
		onmove?: (event: CustomEvent<{ x: number; y: number }>) => void;
		deadzone?: number;
		maxDistance?: number;
		inputMode?: 'joystick' | 'buttons';
		buttonStrength?: number;
	}

	let { onmove, deadzone = 10, maxDistance = 75, inputMode = 'joystick', buttonStrength = 1 }: Props = $props();

	let baseElement = $state<HTMLDivElement | null>(null);
	let tipElement = $state<HTMLDivElement | null>(null);
	let touchIndex: number | null = null;
	let isPressed = $state(false);
	let output = $state({ x: 0, y: 0 });

	let tipX = $state(0);
	let tipY = $state(0);
	let upPressed = $state(false);
	let downPressed = $state(false);
	let leftPressed = $state(false);
	let rightPressed = $state(false);

	function dispatchMove(vector: { x: number; y: number }) {
		if (onmove) {
			onmove(new CustomEvent('move', { detail: vector }) as any);
		}
	}

	function handleTouchStart(event: TouchEvent) {
		if (touchIndex !== null) return;
		if (!baseElement) return;

		const rect = baseElement.getBoundingClientRect();
		
		// Find the first touch that is within joystick area
		for (let i = 0; i < event.touches.length; i++) {
			const touch = event.touches[i];
			
			// Check if touch is within joystick area
			if (
				touch.clientX >= rect.left &&
				touch.clientX <= rect.right &&
				touch.clientY >= rect.top &&
				touch.clientY <= rect.bottom
			) {
				touchIndex = touch.identifier;
				updateJoystick(touch.clientX, touch.clientY);
				event.preventDefault();
				break;
			}
		}
	}

	function handleTouchMove(event: TouchEvent) {
		if (touchIndex === null) return;

		for (let i = 0; i < event.touches.length; i++) {
			const touch = event.touches[i];
			if (touch.identifier === touchIndex) {
				updateJoystick(touch.clientX, touch.clientY);
				event.preventDefault();
				break;
			}
		}
	}

	function handleTouchEnd(event: TouchEvent) {
		if (touchIndex === null) return;

		for (let i = 0; i < event.changedTouches.length; i++) {
			const touch = event.changedTouches[i];
			if (touch.identifier === touchIndex) {
				reset();
				event.preventDefault();
				break;
			}
		}
	}

	function handleMouseDown(event: MouseEvent) {
		if (touchIndex !== null) return;
		
		touchIndex = -1; // Use -1 for mouse
		updateJoystick(event.clientX, event.clientY);
		event.preventDefault();
	}

	function handleMouseMove(event: MouseEvent) {
		if (touchIndex !== -1) return;
		
		updateJoystick(event.clientX, event.clientY);
		event.preventDefault();
	}

	function handleMouseUp(event: MouseEvent) {
		if (touchIndex !== -1) return;
		
		reset();
		event.preventDefault();
	}

	function updateJoystick(clientX: number, clientY: number) {
		if (!baseElement) return;

		const baseRect = baseElement.getBoundingClientRect();
		const centerX = baseRect.left + baseRect.width / 2;
		const centerY = baseRect.top + baseRect.height / 2;

		let deltaX = clientX - centerX;
		let deltaY = clientY - centerY;

		// Limit to max distance
		const distance = Math.sqrt(deltaX * deltaX + deltaY * deltaY);
		if (distance > maxDistance) {
			deltaX = (deltaX / distance) * maxDistance;
			deltaY = (deltaY / distance) * maxDistance;
		}

		// Update tip position
		tipX = deltaX;
		tipY = deltaY;

		// Calculate output
		if (distance > deadzone) {
			isPressed = true;
			const effectiveDistance = distance - deadzone;
			const effectiveMax = maxDistance - deadzone;
			const normalizedDistance = Math.min(effectiveDistance / effectiveMax, 1);
			const clampedDistance = Math.min(distance, maxDistance);

			output = {
				x: (deltaX / clampedDistance) * normalizedDistance,
				y: (deltaY / clampedDistance) * normalizedDistance
			};
			
			dispatchMove(output);
		} else {
			isPressed = false;
			output = { x: 0, y: 0 };
			dispatchMove(output);
		}
	}

	function reset() {
		touchIndex = null;
		isPressed = false;
		output = { x: 0, y: 0 };
		tipX = 0;
		tipY = 0;
		upPressed = false;
		downPressed = false;
		leftPressed = false;
		rightPressed = false;
		dispatchMove({ x: 0, y: 0 });
	}

	function updateButtonsOutput() {
		let x = (rightPressed ? 1 : 0) - (leftPressed ? 1 : 0);
		let y = (downPressed ? 1 : 0) - (upPressed ? 1 : 0);

		if (x !== 0 && y !== 0) {
			const invSqrt2 = 1 / Math.sqrt(2);
			x *= invSqrt2;
			y *= invSqrt2;
		}

		x *= buttonStrength;
		y *= buttonStrength;

		output = { x, y };
		isPressed = x !== 0 || y !== 0;
		tipX = x * maxDistance;
		tipY = y * maxDistance;
		dispatchMove(output);
	}

	function setDirectionPressed(direction: 'up' | 'down' | 'left' | 'right', pressed: boolean) {
		if (direction === 'up') upPressed = pressed;
		if (direction === 'down') downPressed = pressed;
		if (direction === 'left') leftPressed = pressed;
		if (direction === 'right') rightPressed = pressed;
		updateButtonsOutput();
	}

	function handleButtonDown(direction: 'up' | 'down' | 'left' | 'right', event: Event) {
		setDirectionPressed(direction, true);
		event.preventDefault();
	}

	function handleButtonUp(direction: 'up' | 'down' | 'left' | 'right', event: Event) {
		setDirectionPressed(direction, false);
		event.preventDefault();
	}

	onMount(() => {
		// Add global event listeners for mouse
		window.addEventListener('mousemove', handleMouseMove);
		window.addEventListener('mouseup', handleMouseUp);
	});

	$effect(() => {
		if (inputMode !== 'joystick' || !baseElement) {
			return;
		}

		const el = baseElement;

		// Add touch event listeners with passive: false to allow preventDefault
		el.addEventListener('touchstart', handleTouchStart, { passive: false });
		el.addEventListener('touchmove', handleTouchMove, { passive: false });
		el.addEventListener('touchend', handleTouchEnd, { passive: false });
		el.addEventListener('touchcancel', handleTouchEnd, { passive: false });

		return () => {
			el.removeEventListener('touchstart', handleTouchStart);
			el.removeEventListener('touchmove', handleTouchMove);
			el.removeEventListener('touchend', handleTouchEnd);
			el.removeEventListener('touchcancel', handleTouchEnd);
		};
	});

	onDestroy(() => {
		// Remove mouse event listeners
		window.removeEventListener('mousemove', handleMouseMove);
		window.removeEventListener('mouseup', handleMouseUp);
	});
</script>

<div class="joystick-container">
	{#if inputMode === 'buttons'}
		<div class="movement-buttons">
			<button
				type="button"
				class="move-btn up"
				class:pressed={upPressed}
				onmousedown={(e) => handleButtonDown('up', e)}
				onmouseup={(e) => handleButtonUp('up', e)}
				onmouseleave={(e) => handleButtonUp('up', e)}
				ontouchstart={(e) => handleButtonDown('up', e)}
				ontouchend={(e) => handleButtonUp('up', e)}
				ontouchcancel={(e) => handleButtonUp('up', e)}
			>▲</button>
			<button
				type="button"
				class="move-btn left"
				class:pressed={leftPressed}
				onmousedown={(e) => handleButtonDown('left', e)}
				onmouseup={(e) => handleButtonUp('left', e)}
				onmouseleave={(e) => handleButtonUp('left', e)}
				ontouchstart={(e) => handleButtonDown('left', e)}
				ontouchend={(e) => handleButtonUp('left', e)}
				ontouchcancel={(e) => handleButtonUp('left', e)}
			>◀</button>
			<button
				type="button"
				class="move-btn right"
				class:pressed={rightPressed}
				onmousedown={(e) => handleButtonDown('right', e)}
				onmouseup={(e) => handleButtonUp('right', e)}
				onmouseleave={(e) => handleButtonUp('right', e)}
				ontouchstart={(e) => handleButtonDown('right', e)}
				ontouchend={(e) => handleButtonUp('right', e)}
				ontouchcancel={(e) => handleButtonUp('right', e)}
			>▶</button>
			<button
				type="button"
				class="move-btn down"
				class:pressed={downPressed}
				onmousedown={(e) => handleButtonDown('down', e)}
				onmouseup={(e) => handleButtonUp('down', e)}
				onmouseleave={(e) => handleButtonUp('down', e)}
				ontouchstart={(e) => handleButtonDown('down', e)}
				ontouchend={(e) => handleButtonUp('down', e)}
				ontouchcancel={(e) => handleButtonUp('down', e)}
			>▼</button>
		</div>
	{:else}
		<div
			class="joystick-base"
			bind:this={baseElement}
			role="button"
			tabindex="0"
			onmousedown={handleMouseDown}
		>
			<div
				class="joystick-tip"
				class:pressed={isPressed}
				bind:this={tipElement}
				style="transform: translate({tipX}px, {tipY}px)"
			></div>
		</div>
	{/if}
</div>

<style>
	.joystick-container {
		position: relative;
		width: 150px;
		height: 150px;
		display: flex;
		align-items: center;
		justify-content: center;
		touch-action: none;
		user-select: none;
	}

	.joystick-base {
		position: relative;
		width: 150px;
		height: 150px;
		background: rgba(200, 200, 200, 0.4);
		border: 3px solid rgba(100, 100, 100, 0.6);
		border-radius: 50%;
		display: flex;
		align-items: center;
		justify-content: center;
		cursor: pointer;
		touch-action: none;
	}

	.joystick-tip {
		position: absolute;
		width: 60px;
		height: 60px;
		background: rgba(33, 150, 243, 0.8);
		border: 3px solid rgba(25, 118, 210, 0.9);
		border-radius: 50%;
		transition: background-color 0.1s;
		pointer-events: none;
		will-change: transform;
	}

	.joystick-tip.pressed {
		background: rgba(25, 118, 210, 0.9);
	}

	.movement-buttons {
		position: relative;
		width: 150px;
		height: 150px;
	}

	.move-btn {
		position: absolute;
		width: 52px;
		height: 52px;
		border-radius: 12px;
		border: 2px solid rgba(100, 100, 100, 0.6);
		background: rgba(200, 200, 200, 0.4);
		color: rgba(20, 20, 20, 0.9);
		font-size: 20px;
		font-weight: 700;
		cursor: pointer;
		touch-action: none;
		user-select: none;
	}

	.move-btn.pressed {
		background: rgba(33, 150, 243, 0.8);
		border-color: rgba(25, 118, 210, 0.9);
		color: white;
	}

	.move-btn.up {
		top: 0;
		left: 50%;
		transform: translateX(-50%);
	}

	.move-btn.left {
		top: 50%;
		left: 0;
		transform: translateY(-50%);
	}

	.move-btn.right {
		top: 50%;
		right: 0;
		transform: translateY(-50%);
	}

	.move-btn.down {
		bottom: 0;
		left: 50%;
		transform: translateX(-50%);
	}
</style>
