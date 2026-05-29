import { test, expect, type Route } from "@playwright/test";

/**
 * Task #197: end-to-end coverage for the persisted referee filter
 * (Task #175).
 *
 * Task #175 made the rebuild-history and re-roll-history referee
 * filters survive a page reload by mirroring the active selection
 * into localStorage:
 *
 *   - rebuild history → `lean-rebuild-history-referee-filter`
 *   - re-roll history → `lean-checkpoint-reroll-history-referee-filter`
 *
 * There was no automated test pinning this, so a future refactor
 * could silently drop the persistence. This spec drives both panels
 * end-to-end:
 *
 *   1. Mocks the two history endpoints with multi-referee fixtures so
 *      each `<select>` renders real options.
 *   2. Picks a referee in both selects, reloads the page, and asserts
 *      the selection (and the corresponding localStorage key) survive.
 *   3. Clicks "clear" on both, reloads again, and asserts the filter
 *      is back to "all" with the localStorage key removed.
 *
 * Everything the dashboard polls that this spec does not assert
 * against (integrity, alerts) is short-circuited via `page.route` so
 * the test does not depend on real api-server state and runs cleanly
 * under the managed CI harness.
 */

const REBUILD_HISTORY_URL = "**/api/lean/verify/history*";
const REROLL_HISTORY_URL = "**/api/ledger/checkpoint/reroll/history*";
const INTEGRITY_URL = "**/api/ledger/integrity*";
const ALERTS_URL = "**/api/lean/ledger-alerts*";

const REBUILD_HISTORY_FILTER_KEY = "lean-rebuild-history-referee-filter";
const REROLL_HISTORY_FILTER_KEY =
  "lean-checkpoint-reroll-history-referee-filter";

const REBUILD_REFEREE = "alice";
const REROLL_REFEREE = "carol";

function rebuildHistoryPayload(): Record<string, unknown> {
  return {
    capacity: 20,
    entries: [
      {
        timestamp: new Date("2026-05-28T01:00:00Z").toISOString(),
        durationMs: 1111,
        exitCode: 0,
        ok: true,
        error: null,
        streamed: false,
        refereeName: REBUILD_REFEREE,
      },
      {
        timestamp: new Date("2026-05-28T02:00:00Z").toISOString(),
        durationMs: 2222,
        exitCode: 1,
        ok: false,
        error: "boom",
        streamed: true,
        refereeName: "bob",
      },
    ],
  };
}

function rerollHistoryPayload(): Record<string, unknown> {
  return {
    capacity: 20,
    entries: [
      {
        timestamp: new Date("2026-05-28T03:00:00Z").toISOString(),
        durationMs: 3333,
        exitCode: 0,
        ok: true,
        error: null,
        refereeName: REROLL_REFEREE,
        ip: "203.0.113.7",
      },
      {
        timestamp: new Date("2026-05-28T04:00:00Z").toISOString(),
        durationMs: 4444,
        exitCode: 0,
        ok: true,
        error: null,
        refereeName: "dave",
        ip: "203.0.113.8",
      },
    ],
  };
}

function integrityPayload(): Record<string, unknown> {
  return {
    ok: true,
    monitor: {
      running: true,
      intervalSeconds: 300,
      lastTickAt: new Date().toISOString(),
      lastTickAgeSeconds: 1,
      lastResult: "ok",
      lastErrorMessage: null,
      monitorStalled: false,
      stallAgeSeconds: 0,
      stallThresholdSeconds: 900,
    },
    sealedPrefix: { size: 100, sha: "a".repeat(64) },
    liveFile: { size: 200, sha: "b".repeat(64), prefixMatch: true },
    checkpointAge: { seconds: 1, stale: false },
    checkpointStale: false,
    checkpointStaleThresholdSeconds: 2592000,
    sidecar: {
      status: "ok",
      lastOkAt: new Date().toISOString(),
      lastCheckedAt: new Date().toISOString(),
      writableMode: null,
      acknowledgedAt: null,
      payloadSha: null,
    },
    sidecarSecretStrictMode: false,
  };
}

test.describe("dashboard: persisted referee filter (task #197)", () => {
  test("rebuild + re-roll referee filters survive a reload and clear wipes the persisted value", async ({
    page,
  }) => {
    await page.route(INTEGRITY_URL, async (route: Route) => {
      await route.fulfill({
        status: 200,
        headers: { "content-type": "application/json" },
        body: JSON.stringify(integrityPayload()),
      });
    });

    await page.route(ALERTS_URL, async (route: Route) => {
      await route.fulfill({
        status: 200,
        headers: { "content-type": "application/json" },
        body: JSON.stringify({
          alerts: [],
          fileExists: false,
          totalLines: 0,
          truncated: false,
          rotation: 0,
          availableRotations: [],
          ackGcDropped: 0,
        }),
      });
    });

    await page.route(REBUILD_HISTORY_URL, async (route: Route) => {
      await route.fulfill({
        status: 200,
        headers: { "content-type": "application/json" },
        body: JSON.stringify(rebuildHistoryPayload()),
      });
    });

    await page.route(REROLL_HISTORY_URL, async (route: Route) => {
      await route.fulfill({
        status: 200,
        headers: { "content-type": "application/json" },
        body: JSON.stringify(rerollHistoryPayload()),
      });
    });

    await page.goto("/");

    const rebuildSelect = page.locator(
      '[data-testid="select-rebuild-history-referee-filter"]',
    );
    const rerollSelect = page.locator(
      '[data-testid="select-checkpoint-reroll-history-referee-filter"]',
    );

    // Both panels render and start at "all" (empty value).
    await expect(rebuildSelect).toBeVisible();
    await expect(rerollSelect).toBeVisible();
    await expect(rebuildSelect).toHaveValue("");
    await expect(rerollSelect).toHaveValue("");

    // Pick a referee in each panel.
    await rebuildSelect.selectOption(REBUILD_REFEREE);
    await rerollSelect.selectOption(REROLL_REFEREE);
    await expect(rebuildSelect).toHaveValue(REBUILD_REFEREE);
    await expect(rerollSelect).toHaveValue(REROLL_REFEREE);

    // The selection should be mirrored into localStorage.
    await expect
      .poll(() =>
        page.evaluate(
          (k) => window.localStorage.getItem(k),
          REBUILD_HISTORY_FILTER_KEY,
        ),
      )
      .toBe(REBUILD_REFEREE);
    await expect
      .poll(() =>
        page.evaluate(
          (k) => window.localStorage.getItem(k),
          REROLL_HISTORY_FILTER_KEY,
        ),
      )
      .toBe(REROLL_REFEREE);

    // Reload — the persisted filter must still be active.
    await page.reload();
    await expect(rebuildSelect).toHaveValue(REBUILD_REFEREE);
    await expect(rerollSelect).toHaveValue(REROLL_REFEREE);

    // Clear both filters.
    await page
      .locator('[data-testid="button-rebuild-history-clear-filter"]')
      .click();
    await page
      .locator('[data-testid="button-checkpoint-reroll-history-clear-filter"]')
      .click();
    await expect(rebuildSelect).toHaveValue("");
    await expect(rerollSelect).toHaveValue("");

    // The persisted values must be wiped.
    await expect
      .poll(() =>
        page.evaluate(
          (k) => window.localStorage.getItem(k),
          REBUILD_HISTORY_FILTER_KEY,
        ),
      )
      .toBeNull();
    await expect
      .poll(() =>
        page.evaluate(
          (k) => window.localStorage.getItem(k),
          REROLL_HISTORY_FILTER_KEY,
        ),
      )
      .toBeNull();

    // And a subsequent reload returns to "all".
    await page.reload();
    await expect(rebuildSelect).toHaveValue("");
    await expect(rerollSelect).toHaveValue("");
  });
});
