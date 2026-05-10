import { defineConfig, devices } from "@playwright/test";

const PORT = process.env.PORT ?? "3000";

/**
 * Minimal Playwright config for the VETO web client.
 *
 * - Two projects: desktop Chrome and mobile Safari (mobile RTL is the
 *   primary citizen experience).
 * - Spawns the production server itself so devs don't have to remember
 *   to start it; reuses an existing one when present.
 * - Honours `NEXT_PUBLIC_CALL_V2` so the spec always lands on `_v2`.
 */
export default defineConfig({
  testDir: "./specs",
  timeout: 30_000,
  expect: { timeout: 5_000 },
  retries: process.env.CI ? 2 : 0,
  reporter: process.env.CI ? "github" : "list",
  use: {
    baseURL: process.env.E2E_BASE_URL ?? `http://localhost:${PORT}`,
    trace: "on-first-retry",
    video: "retain-on-failure",
  },
  webServer: process.env.E2E_BASE_URL
    ? undefined
    : {
        command: `npm run start`,
        port: Number(PORT),
        reuseExistingServer: !process.env.CI,
        timeout: 120_000,
        env: {
          NEXT_PUBLIC_CALL_V2: "1",
        },
      },
  projects: [
    {
      name: "chromium-desktop",
      use: { ...devices["Desktop Chrome"], locale: "he-IL" },
    },
    {
      name: "webkit-mobile",
      use: { ...devices["iPhone 14"], locale: "he-IL" },
    },
  ],
});
