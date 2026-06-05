<script lang="ts">
	import { connectionStore, serverMessage } from '../store';
	import { onMount } from 'svelte';

	let guessInput = $state('');
	let feedback = $state<'correct' | 'incorrect' | null>(null);
	let feedbackTimer: number | null = null;

	onMount(() => {
		const unsubscribe = serverMessage.subscribe((msg) => {
			if (!msg) return;

			if (msg === 'guess_ack;correct') {
				showFeedback('correct');
				guessInput = '';
			} else if (msg === 'guess_ack;incorrect') {
				showFeedback('incorrect');
				guessInput = '';
			}
		});

		return () => {
			unsubscribe();
			if (feedbackTimer !== null) {
				clearTimeout(feedbackTimer);
			}
		};
	});

	function showFeedback(type: 'correct' | 'incorrect') {
		feedback = type;
		if (feedbackTimer !== null) {
			clearTimeout(feedbackTimer);
		}
		feedbackTimer = window.setTimeout(() => {
			feedback = null;
			feedbackTimer = null;
		}, 800);
	}

	function handleSubmit() {
		if (guessInput.trim().length === 0) return;
		connectionStore.sendText(`guess;${guessInput.trim()}`);
	}

	function handleKeydown(e: KeyboardEvent) {
		if (e.key === 'Enter') {
			e.preventDefault();
			handleSubmit();
		}
	}
</script>

<div class="guess-container" class:correct-flash={feedback === 'correct'} class:incorrect-flash={feedback === 'incorrect'}>
	<div class="guess-form">
		<h2>What is it?</h2>
		<p class="hint">Watch the screen and type your guess!</p>

		<div class="input-group">
			<input
				type="text"
				bind:value={guessInput}
				onkeydown={handleKeydown}
				placeholder="Type your guess..."
				autocomplete="off"
				autocorrect="off"
				autocapitalize="off"
				spellcheck="false"
			/>
			<button onclick={handleSubmit} disabled={guessInput.trim().length === 0}>
				Submit
			</button>
		</div>

		<div class="tips">
			<p>💡 Tips:</p>
			<ul>
				<li>Guess as fast as you can for more points!</li>
				<li>You can guess multiple times</li>
				<li>Watch the shared screen for the drawing</li>
			</ul>
		</div>
	</div>

	{#if feedback === 'correct'}
		<div class="feedback-overlay correct">
			<div class="feedback-icon">✓</div>
			<p>Correct!</p>
		</div>
	{:else if feedback === 'incorrect'}
		<div class="feedback-overlay incorrect">
			<div class="feedback-icon">✗</div>
			<p>Try Again</p>
		</div>
	{/if}
</div>

<style>
	.guess-container {
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
		transition: background 0.3s ease;
	}

	.guess-container.correct-flash {
		background: linear-gradient(135deg, #5DC15B 0%, #4CAF50 100%);
	}

	.guess-container.incorrect-flash {
		background: linear-gradient(135deg, #EE4B2B 0%, #C0392B 100%);
	}

	.guess-form {
		background: rgba(255, 255, 255, 0.95);
		border-radius: 16px;
		padding: 2.5rem;
		max-width: 500px;
		width: 100%;
		box-shadow: 0 8px 32px rgba(0, 0, 0, 0.2);
		position: relative;
		z-index: 1;
	}

	h2 {
		color: #333;
		margin: 0 0 0.5rem;
		font-size: 2rem;
		text-align: center;
	}

	.hint {
		color: #666;
		margin: 0 0 2rem;
		font-size: 1rem;
		text-align: center;
	}

	.input-group {
		display: flex;
		gap: 0.75rem;
		margin-bottom: 2rem;
	}

	input {
		flex: 1;
		padding: 1rem;
		font-size: 1.25rem;
		border: 2px solid #ddd;
		border-radius: 8px;
		box-sizing: border-box;
		transition: border-color 0.2s;
	}

	input:focus {
		outline: none;
		border-color: #667eea;
	}

	button {
		padding: 1rem 2rem;
		font-size: 1.25rem;
		font-weight: 600;
		color: white;
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		border: none;
		border-radius: 8px;
		cursor: pointer;
		transition: all 0.2s;
		white-space: nowrap;
	}

	button:hover:not(:disabled) {
		transform: translateY(-2px);
		box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
	}

	button:active:not(:disabled) {
		transform: translateY(0);
	}

	button:disabled {
		background: #cccccc;
		cursor: not-allowed;
		opacity: 0.6;
	}

	.tips {
		background: #f5f5f5;
		padding: 1rem;
		border-radius: 8px;
	}

	.tips p {
		margin: 0 0 0.5rem;
		color: #333;
		font-weight: 600;
		font-size: 0.9rem;
	}

	.tips ul {
		list-style: none;
		padding: 0;
		margin: 0;
	}

	.tips li {
		color: #666;
		padding: 0.25rem 0;
		font-size: 0.9rem;
	}

	.feedback-overlay {
		position: fixed;
		top: 0;
		left: 0;
		width: 100vw;
		height: 100vh;
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		z-index: 10;
		animation: fadeInOut 0.8s ease-out;
		pointer-events: none;
	}

	@keyframes fadeInOut {
		0% {
			opacity: 0;
			transform: scale(0.8);
		}
		50% {
			opacity: 1;
			transform: scale(1);
		}
		100% {
			opacity: 0;
			transform: scale(0.8);
		}
	}

	.feedback-icon {
		width: 120px;
		height: 120px;
		border-radius: 50%;
		display: flex;
		align-items: center;
		justify-content: center;
		font-size: 5rem;
		color: white;
		margin-bottom: 1rem;
	}

	.feedback-overlay.correct .feedback-icon {
		background: rgba(76, 175, 80, 0.9);
	}

	.feedback-overlay.incorrect .feedback-icon {
		background: rgba(244, 67, 54, 0.9);
	}

	.feedback-overlay p {
		color: white;
		font-size: 2rem;
		font-weight: 700;
		text-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
	}

	@media (max-width: 768px) {
		.guess-form {
			padding: 2rem;
		}

		h2 {
			font-size: 1.75rem;
		}

		.input-group {
			flex-direction: column;
		}

		input {
			font-size: 1.1rem;
		}

		button {
			font-size: 1.1rem;
		}
	}
</style>
