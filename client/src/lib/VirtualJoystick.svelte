<script lang="ts">
	import { onMount, onDestroy } from 'svelte';

	interface Props {
		onMove?: (vector: { x: number; y: number }) => void;
		deadzone?: number;
		maxDistance?: number;
	}

	let { onMove = () => {}, deadzone = 10, maxDistance = 75 }: Props = $props();

	let baseElement: HTMLDivElement;
	let tipElement: HTMLDivElement;
	let touchIndex: number | null = null;
	let isPressed = $state(false);
	let output = $state({ x: 0, y: 0 });

	let tipX = $state(0);
	let tipY = $state(0);

	function handleTouchStart(event: TouchEvent) {
		if (touchIndex !== null) return;

		const touch = event.touches[0];
		const rect = baseElement.getBoundingClientRect();
		
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
			
			output = {
				x: (deltaX / distance) * normalizedDistance,
				y: (deltaY / distance) * normalizedDistance
			};
			
			onMove(output);
		} else {
			isPressed = false;
			output = { x: 0, y: 0 };
			onMove(output);
		}
	}

	function reset() {
		touchIndex = null;
		isPressed = false;
		output = { x: 0, y: 0 };
		tipX = 0;
		tipY = 0;
		onMove({ x: 0, y: 0 });
	}

	onMount(() => {
		// Add touch event listeners with passive: false to allow preventDefault
		baseElement.addEventListener('touchstart', handleTouchStart, { passive: false });
		baseElement.addEventListener('touchmove', handleTouchMove, { passive: false });
		baseElement.addEventListener('touchend', handleTouchEnd, { passive: false });
		baseElement.addEventListener('touchcancel', handleTouchEnd, { passive: false });
		
		// Add global event listeners for mouse
		window.addEventListener('mousemove', handleMouseMove);
		window.addEventListener('mouseup', handleMouseUp);
	});

	onDestroy(() => {
		// Remove touch event listeners
		if (baseElement) {
			baseElement.removeEventListener('touchstart', handleTouchStart);
			baseElement.removeEventListener('touchmove', handleTouchMove);
			baseElement.removeEventListener('touchend', handleTouchEnd);
			baseElement.removeEventListener('touchcancel', handleTouchEnd);
		}
		
		// Remove mouse event listeners
		window.removeEventListener('mousemove', handleMouseMove);
		window.removeEventListener('mouseup', handleMouseUp);
	});
</script>

<div class="joystick-container">
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

	@media (max-width: 768px) {
		.joystick-container {
			width: 120px;
			height: 120px;
		}

		.joystick-base {
			width: 120px;
			height: 120px;
		}

		.joystick-tip {
			width: 50px;
			height: 50px;
		}
	}
</style>
