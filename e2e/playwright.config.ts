import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: '.',
  testMatch: '*.test.ts',
  timeout: 60_000,
  expect: {
    timeout: 10_000,
  },
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  workers: 1,
  reporter: [
    ['list'],
    ['html', { outputFolder: '../test-results/playwright-report' }],
  ],
  use: {
    baseURL: 'http://localhost:8484',
    headless: true,
    viewport: { width: 390, height: 844 }, // iPhone 14 size
    actionTimeout: 10_000,
    screenshot: 'only-on-failure',
  },
  globalSetup: require.resolve('./global-setup.ts'),
  globalTeardown: require.resolve('./global-teardown.ts'),
});
