/**
 * Utility for adding randomised delays in E2E tests to simulate realistic
 * human interaction timing (thinking, typing, reaction delays).
 */

/**
 * Wait a random amount of time within [minMs, maxMs].
 * Each call produces a different duration so test runs have varied timing.
 */
export function randomDelay(minMs = 300, maxMs = 1500): Promise<void> {
  const ms = Math.floor(Math.random() * (maxMs - minMs + 1)) + minMs;
  return new Promise((r) => setTimeout(r, ms));
}
