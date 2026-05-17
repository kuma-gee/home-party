<script lang="ts">
	import { connectionStore } from '../store';

	type Skill = 'dash' | 'shield';

	let confirmedSkill = $state<Skill | null>(null);

	function handleSkillConfirm(skill: Skill) {
		if (confirmedSkill !== null) return;
		confirmedSkill = skill;
		connectionStore.sendInput(skill === 'dash' ? 'skill_dash' : 'skill_shield', true);
	}

	function handleSkillReset() {
		confirmedSkill = null;
		connectionStore.sendInput('skill_none', true);
	}
</script>

<div class="skill-select-screen">
	{#if confirmedSkill === null}
		<h2 class="skill-select-title">Choose Your Skill</h2>
		<div class="skill-cards">
			<button
				class="skill-card dash-card"
				onmousedown={() => handleSkillConfirm('dash')}
				ontouchstart={(e) => { e.preventDefault(); handleSkillConfirm('dash'); }}
			>
				<span class="skill-icon">💨</span>
				<span class="skill-name">Dash</span>
			</button>
			<button
				class="skill-card shield-card"
				onmousedown={() => handleSkillConfirm('shield')}
				ontouchstart={(e) => { e.preventDefault(); handleSkillConfirm('shield'); }}
			>
				<span class="skill-icon">🛡️</span>
				<span class="skill-name">Shield</span>
			</button>
		</div>
	{:else}
		<div class="skill-confirmed">
			<div class="confirmed-icon">{confirmedSkill === 'dash' ? '💨' : '🛡️'}</div>
			<h2 class="confirmed-name">{confirmedSkill === 'dash' ? 'Dash' : 'Shield'}</h2>
			<p class="confirmed-label">Ready!</p>
			<p class="confirmed-waiting">Waiting for game to start...</p>
			<button
				class="change-skill-button"
				onmousedown={() => handleSkillReset()}
				ontouchstart={(e) => { e.preventDefault(); handleSkillReset(); }}
			>
				Change Skill
			</button>
		</div>
	{/if}
</div>

<style>
	.skill-select-screen {
		position: fixed;
		top: 0;
		left: 0;
		width: 100vw;
		height: 100vh;
		background: linear-gradient(135deg, #1a0533 0%, #2d1b69 50%, #0d1b4b 100%);
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		padding: 1rem 2rem;
		box-sizing: border-box;
		touch-action: none;
		user-select: none;
		gap: 1.5rem;
	}

	.skill-select-title {
		color: #e8d5ff;
		font-size: clamp(1.25rem, 4vw, 2rem);
		font-weight: 700;
		text-align: center;
		margin: 0;
		text-shadow: 0 0 20px rgba(180, 120, 255, 0.6);
		letter-spacing: 0.05em;
	}

	.skill-cards {
		display: flex;
		gap: clamp(1rem, 3vw, 2rem);
		align-items: center;
		justify-content: center;
		flex: 1;
		max-height: 45vh;
		width: 100%;
	}

	.skill-card {
		width: 40vw;
		max-width: 260px;
		height: 100%;
		max-height: 200px;
		border-radius: 20px;
		border: 3px solid rgba(255, 255, 255, 0.3);
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		gap: 0.75rem;
		cursor: pointer;
		transition: transform 0.15s ease, filter 0.15s ease;
		touch-action: none;
		-webkit-tap-highlight-color: transparent;
	}

	.skill-card:active {
		transform: scale(0.95);
		filter: brightness(1.2);
	}

	.dash-card {
		background: linear-gradient(135deg, #ff6b00 0%, #c0392b 100%);
		box-shadow: 0 8px 32px rgba(255, 80, 0, 0.4);
	}

	.shield-card {
		background: linear-gradient(135deg, #0077b6 0%, #00b4d8 100%);
		box-shadow: 0 8px 32px rgba(0, 150, 200, 0.4);
	}

	.skill-icon {
		font-size: clamp(2.5rem, 8vw, 4rem);
		line-height: 1;
	}

	.skill-name {
		color: white;
		font-size: clamp(1.1rem, 3.5vw, 1.75rem);
		font-weight: 700;
		letter-spacing: 0.05em;
		text-shadow: 0 2px 8px rgba(0, 0, 0, 0.4);
	}

	.skill-confirmed {
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		gap: 1rem;
		animation: fadeIn 0.4s ease-out;
	}

	.confirmed-icon {
		font-size: clamp(4rem, 15vw, 7rem);
		animation: skillPulse 1.5s ease-in-out infinite;
	}

	@keyframes skillPulse {
		0%, 100% { transform: scale(1); }
		50% { transform: scale(1.1); }
	}

	.confirmed-name {
		color: white;
		font-size: clamp(1.5rem, 5vw, 2.5rem);
		font-weight: 700;
		margin: 0;
		text-shadow: 0 0 30px rgba(255, 255, 255, 0.5);
	}

	.confirmed-label {
		color: #a8ff78;
		font-size: clamp(1.1rem, 3.5vw, 1.5rem);
		font-weight: 700;
		margin: 0;
		letter-spacing: 0.1em;
		text-transform: uppercase;
	}

	.confirmed-spinner {
		width: 40px;
		height: 40px;
		border: 3px solid rgba(255, 255, 255, 0.2);
		border-top-color: rgba(255, 255, 255, 0.8);
		border-radius: 50%;
		animation: spin 1s linear infinite;
		margin-top: 0.5rem;
	}

	.confirmed-waiting {
		color: rgba(200, 180, 255, 0.8);
		font-size: clamp(0.85rem, 2.5vw, 1rem);
		margin: 0;
	}

	.change-skill-button {
		margin-top: 0.75rem;
		padding: 0.5rem 1rem;
		border-radius: 12px;
		border: 2px solid rgba(255,255,255,0.12);
		background: rgba(255,255,255,0.06);
		color: #fff;
		font-weight: 700;
		cursor: pointer;
		transition: transform 0.12s ease, background 0.12s ease;
	}

	.change-skill-button:active {
		transform: scale(0.97);
		background: rgba(255,255,255,0.09);
	}

	@keyframes fadeIn {
		from { opacity: 0; }
		to { opacity: 1; }
	}

	@keyframes spin {
		to { transform: rotate(360deg); }
	}

	@media (orientation: landscape) and (max-height: 500px) {
		.skill-select-screen {
			gap: 0.75rem;
			padding: 0.5rem 1.5rem;
		}

		.skill-cards {
			max-height: 38vh;
		}
	}
</style>
