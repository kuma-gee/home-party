<script lang="ts">
	import { connectionStore, serverMessage } from '../store';
	import { onMount } from 'svelte';

	let inputText = $state('');
	let submitted = $state(false);
	let submittedCount = $state(0);
	let maxSubmissions = $state(3);
	let mode = $state<'submit' | 'guess'>('submit');
	let feedback = $state<'correct' | 'incorrect' | null>(null);
	let message = $state('');
	let feedbackTimer: number | null = null;

	onMount(() => {
		const unsubscribe = serverMessage.subscribe((msg) => {
			if (!msg || !msg.text) return;

			if (msg.text.startsWith('word_ack;ok')) {
				const parts = msg.text.split(';');
				mode = 'submit';
				submittedCount = Number(parts[2] ?? submittedCount + 1);
				maxSubmissions = Number(parts[3] ?? maxSubmissions);
				submitted = submittedCount >= maxSubmissions;
				message = '';
				inputText = '';
			} else if (msg.text.startsWith('word_ack;limit')) {
				const parts = msg.text.split(';');
				mode = 'submit';
				maxSubmissions = Number(parts[2] ?? maxSubmissions);
				submitted = true;
				message = `Maximum ${maxSubmissions} words submitted.`;
				inputText = '';
			} else if (msg.text === 'word_ack;duplicate') {
				message = 'There is already a similar word. Try another.';
				inputText = '';
			} else if (msg.text === 'word_ack;invalid') {
				message = 'Invalid word! Use 3-20 alphanumeric characters.';
				inputText = '';
			} else if (msg.text === 'word_ack;correct') {
				showFeedback('correct');
				inputText = '';
			} else if (msg.text === 'word_ack;incorrect') {
				showFeedback('incorrect');
				inputText = '';
			} else if (msg.text === 'word_ack;reset') {
				console.log('Resetting word input state');
				mode = 'guess';
				submitted = false;
				submittedCount = 0;
				maxSubmissions = 3;
				feedback = null;
				message = '';
				inputText = '';
			}
		});

		return () => {
			unsubscribe();
			if (feedbackTimer !== null) clearTimeout(feedbackTimer);
		};
	});

	function showFeedback(type: 'correct' | 'incorrect') {
		feedback = type;
		if (feedbackTimer !== null) clearTimeout(feedbackTimer);
		feedbackTimer = window.setTimeout(() => {
			feedback = null;
			feedbackTimer = null;
		}, 800);
	}

	function handleSubmit() {
		if (inputText.trim().length === 0) return;
		message = '';
		connectionStore.sendText(`word;${inputText.trim()}`);
	}

	function handleKeydown(e: KeyboardEvent) {
		if (e.key === 'Enter') {
			e.preventDefault();
			handleSubmit();
		}
	}
</script>

<div
	class="word-input-container"
	class:correct-flash={feedback === 'correct'}
	class:incorrect-flash={feedback === 'incorrect'}
>
	{#if submitted}
		<div class="submitted-state">
			<div class="checkmark-icon">✓</div>
			<h2>{submittedCount} / {maxSubmissions} Words Submitted!</h2>
			<p>Waiting for others and VR player to start...</p>
		</div>
	{:else}
		<div class="form-container">
			<h2>{mode === 'submit' ? 'Enter Word' : 'Enter Guess'}</h2>
			<p class="instructions">
				{mode === 'submit'
					? `Submit up to ${maxSubmissions} words (${submittedCount} submitted)`
					: 'Type your guess and submit'}
			</p>

			<div class="input-group">
				<input
					type="text"
					bind:value={inputText}
					onkeydown={handleKeydown}
					placeholder="Type here..."
					autocomplete="off"
					autocorrect="off"
					autocapitalize="off"
					spellcheck="false"
				/>
				<button onclick={handleSubmit} disabled={inputText.trim().length === 0}>
					Submit
				</button>
			</div>

			{#if message}
				<div class="message-banner">{message}</div>
			{/if}
		</div>
	{/if}

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
	.word-input-container {
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

	.word-input-container.correct-flash {
		background: linear-gradient(135deg, #5DC15B 0%, #4CAF50 100%);
	}

	.word-input-container.incorrect-flash {
		background: linear-gradient(135deg, #EE4B2B 0%, #C0392B 100%);
	}

	.submitted-state {
		text-align: center;
		color: white;
	}

	.checkmark-icon {
		width: 100px;
		height: 100px;
		border-radius: 50%;
		background: linear-gradient(135deg, #5DC15B 0%, #4CAF50 100%);
		display: flex;
		align-items: center;
		justify-content: center;
		font-size: 4rem;
		margin: 0 auto 2rem;
		animation: pop 0.4s ease-out;
	}

	@keyframes pop {
		0% { transform: scale(0); }
		50% { transform: scale(1.2); }
		100% { transform: scale(1); }
	}

	.submitted-state h2 {
		color: white;
		font-size: 2rem;
		margin-bottom: 1rem;
	}

	.submitted-state p {
		color: rgba(255, 255, 255, 0.85);
		font-size: 1.25rem;
	}

	.form-container {
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
	}

	.instructions {
		color: #666;
		margin: 0 0 2rem;
		font-size: 1rem;
	}

	.input-group {
		display: flex;
		gap: 0.75rem;
		margin-bottom: 1rem;
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

	.message-banner {
		background: #ffebee;
		color: #c62828;
		padding: 0.75rem 1rem;
		border-radius: 8px;
		font-weight: 500;
		text-align: center;
		animation: shake 0.3s ease-out;
	}

	@keyframes shake {
		0%, 100% { transform: translateX(0); }
		25% { transform: translateX(-10px); }
		75% { transform: translateX(10px); }
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
		0% { opacity: 0; transform: scale(0.8); }
		50% { opacity: 1; transform: scale(1); }
		100% { opacity: 0; transform: scale(0.8); }
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
		.form-container {
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
