<script lang="ts">
	import { connectionStore, serverMessage } from '../store';
	import { onMount } from 'svelte';

	let wordInput = $state('');
	let errorMessage = $state('');
	let submitted = $state(false);
	let charCount = $derived(wordInput.length);
	let isValid = $derived(charCount >= 3 && charCount <= 20 && /^[a-zA-Z0-9]+$/.test(wordInput));

	onMount(() => {
		const unsubscribe = serverMessage.subscribe((msg) => {
			if (!msg) return;

			if (msg === 'word_ack;ok') {
				submitted = true;
				errorMessage = '';
				wordInput = '';
			} else if (msg === 'word_ack;duplicate') {
				errorMessage = 'There is already a similar word. Try another.';
				wordInput = '';
			} else if (msg === 'word_ack;invalid') {
				errorMessage = 'Invalid word! Use 3-20 alphanumeric characters.';
				wordInput = '';
			}
		});

		return unsubscribe;
	});

	function handleSubmit() {
		if (!isValid) {
			errorMessage = 'Word must be 3-20 alphanumeric characters';
			return;
		}

		errorMessage = '';
		connectionStore.sendText(`word;${wordInput}`);
	}

	function handleInput(e: Event) {
		const target = e.target as HTMLInputElement;
		wordInput = target.value;
		errorMessage = '';
	}
</script>

<div class="word-submit-container">
	{#if submitted}
		<div class="submitted-state">
			<div class="checkmark">✓</div>
			<h2>Word Submitted!</h2>
			<p>Waiting for others and VR player to start...</p>
		</div>
	{:else}
		<div class="form-container">
			<h2>Submit Your Word</h2>
			<p class="instructions">Enter a word for the VR player to draw</p>

			<div class="input-wrapper">
				<input
					type="text"
					bind:value={wordInput}
					oninput={handleInput}
					placeholder="Your word..."
					maxlength="20"
					autocomplete="off"
					autocorrect="off"
					autocapitalize="off"
					spellcheck="false"
					class:invalid={wordInput.length > 0 && !isValid}
				/>
				<div class="char-counter" class:warning={charCount > 20 || (charCount > 0 && charCount < 3)}>
					{charCount}/20
				</div>
			</div>

			{#if errorMessage}
				<div class="error-banner">{errorMessage}</div>
			{/if}

			<button onclick={handleSubmit} disabled={!isValid} class="submit-btn">
				Submit Word
			</button>

			<div class="requirements">
				<p>Requirements:</p>
				<ul>
					<li class:met={charCount >= 3}>• At least 3 characters</li>
					<li class:met={charCount <= 20}>• No more than 20 characters</li>
					<li class:met={/^[a-zA-Z0-9]*$/.test(wordInput)}>• Letters and numbers only</li>
				</ul>
			</div>
		</div>
	{/if}
</div>

<style>
	.word-submit-container {
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

	.submitted-state {
		text-align: center;
		color: white;
	}

	.checkmark {
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
		0% {
			transform: scale(0);
		}
		50% {
			transform: scale(1.2);
		}
		100% {
			transform: scale(1);
		}
	}

	.submitted-state h2 {
		font-size: 2rem;
		margin-bottom: 1rem;
	}

	.submitted-state p {
		font-size: 1.25rem;
		opacity: 0.9;
	}

	.form-container {
		background: rgba(255, 255, 255, 0.95);
		border-radius: 16px;
		padding: 2.5rem;
		max-width: 500px;
		width: 100%;
		box-shadow: 0 8px 32px rgba(0, 0, 0, 0.2);
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

	.input-wrapper {
		position: relative;
		margin-bottom: 1rem;
	}

	input {
		width: 100%;
		padding: 1rem;
		padding-right: 4rem;
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

	input.invalid {
		border-color: #f44336;
	}

	.char-counter {
		position: absolute;
		right: 1rem;
		top: 50%;
		transform: translateY(-50%);
		color: #999;
		font-size: 0.9rem;
		font-weight: 600;
	}

	.char-counter.warning {
		color: #ff9800;
	}

	.error-banner {
		background: #ffebee;
		color: #c62828;
		padding: 0.75rem 1rem;
		border-radius: 8px;
		margin-bottom: 1rem;
		font-weight: 500;
		text-align: center;
		animation: shake 0.3s ease-out;
	}

	@keyframes shake {
		0%, 100% {
			transform: translateX(0);
		}
		25% {
			transform: translateX(-10px);
		}
		75% {
			transform: translateX(10px);
		}
	}

	.submit-btn {
		width: 100%;
		padding: 1rem;
		font-size: 1.25rem;
		font-weight: 600;
		color: white;
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		border: none;
		border-radius: 8px;
		cursor: pointer;
		transition: all 0.2s;
		margin-bottom: 1.5rem;
	}

	.submit-btn:hover:not(:disabled) {
		transform: translateY(-2px);
		box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
	}

	.submit-btn:active:not(:disabled) {
		transform: translateY(0);
	}

	.submit-btn:disabled {
		background: #cccccc;
		cursor: not-allowed;
	}

	.requirements {
		background: #f5f5f5;
		padding: 1rem;
		border-radius: 8px;
	}

	.requirements p {
		margin: 0 0 0.5rem;
		color: #333;
		font-weight: 600;
		font-size: 0.9rem;
	}

	.requirements ul {
		list-style: none;
		padding: 0;
		margin: 0;
	}

	.requirements li {
		color: #999;
		padding: 0.25rem 0;
		font-size: 0.9rem;
		transition: color 0.2s;
	}

	.requirements li.met {
		color: #4CAF50;
		font-weight: 600;
	}

	@media (max-width: 768px) {
		.form-container {
			padding: 2rem;
		}

		h2 {
			font-size: 1.75rem;
		}

		input {
			font-size: 1.1rem;
		}
	}
</style>
