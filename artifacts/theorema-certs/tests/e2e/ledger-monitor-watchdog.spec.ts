import { test, expect, type Route } from "@playwright/test";

/**
 * Task #128: end-to-end coverage for the "WATCHDOG FIRED — MONITOR STALLED"
 * red badge added to the Ledger Integrity card.
 *
 * Task #113 added an in-process watchdog that pushes a `monitor_stalled`
 * alert when no integrity tick has completed in 2× the configured
 * monitor interval. Task #128 then surfaces that state in the dashboard
 * via two new fields on `GET /api/ledger/integrity` → `monitor`:
 * `watchdogState` (`ok` | `stalled` | null) and `watchdogLastFiredAt`
 * (ISO-8601 | null). This spec mocks the endpoint so we can flip those
 * fields deterministically without driving the real watchdog timer.
 *
 * Selectors / copy under test:
 *   - `[data-testid="text-ledger-monitor-watchdog"]` carries
 *     `data-watchdog-state="ok"|"stalled"` and
 *     `data-watchdog-fired-at` with the ISO timestamp (or "").
 *   - Red badge fires when `watchdogState === "stalled"`; copy starts
 *     with "watchdog fired — monitor stalled".
 *   - Amber recovered-recently badge fires when `watchdogState === "ok"`
 *     but `watchdogLastFiredAt` is set; copy starts with
 *     "watchdog recovered".
 *   - Nothing renders when `watchdogState === "ok"` and
 *     `watchdogLastFiredAt === null` (the steady-state healthy case).
 */

const LEDGER_INTEGRITY_URL = "**/api/ledger/integrity*";

type WatchdogOverrides = {
  watchdogState: "ok" | "stalled" | null;
  watchdogLastFiredAt: string | null;
};

function buildLedgerIntegrityBody(overrides: WatchdogOverrides) {
  const nowIso = new Date().toISOString();
  return {
    status: "ok",
    failureMode: null,
    reason: null,
    checkpointSize: 1024,
    checkpointSha:
      "0000000000000000000000000000000000000000000000000000000000000000",
    liveSize: 1024,
    livePrefixSha:
      "0000000000000000000000000000000000000000000000000000000000000000",
    growthBytes: 0,
    checkedAt: nowIso,
    ledgerLastModified: nowIso,
    ledgerPath: "data/hits.txt",
    checkpointPath: "data/hits.txt.checkpoint",
    lastOkAt: nowIso,
    lastOkAgeSeconds: 5,
    lastCheckedAt: nowIso,
    lastCheckedAgeSeconds: 5,
    staleThresholdSeconds: 1800,
    stale: false,
    checkedStaleThresholdSeconds: 600,
    checkedStale: false,
    checkpointLastModified: nowIso,
    checkpointAgeSeconds: 100,
    checkpointCoverageRatio: 1,
    checkpointStaleThresholdSeconds: 2592000,
    checkpointStale: false,
    lastOkSidecarStatus: "ok",
    lastOkSidecarStatusAcknowledgedAt: null,
    monitor: {
      enabled: true,
      intervalSeconds: 300,
      lastTickAt: nowIso,
      lastAlertedFailureMode: null,
      lastAcknowledgedAlertId: null,
      watchdogState: overrides.watchdogState,
      watchdogLastFiredAt: overrides.watchdogLastFiredAt,
    },
  };
}

async function installLedgerIntegrityMock(
  page: import("@playwright/test").Page,
  overridesRef: { current: WatchdogOverrides },
) {
  await page.route(LEDGER_INTEGRITY_URL, async (route: Route) => {
    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify(buildLedgerIntegrityBody(overridesRef.current)),
    });
  });
}

test.describe("dashboard: ledger monitor watchdog badge", () => {
  test("renders red 'WATCHDOG FIRED' badge when stalled, amber recovered badge after recovery, and nothing in the steady-state healthy case", async ({
    page,
  }) => {
    const firedAt = new Date(Date.now() - 30_000).toISOString();
    const overridesRef: { current: WatchdogOverrides } = {
      current: {
        watchdogState: "stalled",
        watchdogLastFiredAt: firedAt,
      },
    };

    await installLedgerIntegrityMock(page, overridesRef);

    // Stalled path.
    await page.goto("/");

    const watchdogBlock = page.locator(
      '[data-testid="text-ledger-monitor-watchdog"]',
    );
    await expect(watchdogBlock).toBeVisible();
    await expect(watchdogBlock).toHaveAttribute(
      "data-watchdog-state",
      "stalled",
    );
    await expect(watchdogBlock).toHaveAttribute(
      "data-watchdog-fired-at",
      firedAt,
    );
    await expect(watchdogBlock).toContainText(
      "watchdog fired — monitor stalled",
    );

    // Recovered path: state goes back to ok but the last-fired
    // timestamp is sticky, so the amber recovered badge stays up.
    overridesRef.current = {
      watchdogState: "ok",
      watchdogLastFiredAt: firedAt,
    };
    await page.reload();

    await expect(watchdogBlock).toBeVisible();
    await expect(watchdogBlock).toHaveAttribute(
      "data-watchdog-state",
      "ok",
    );
    await expect(watchdogBlock).toContainText("watchdog recovered");

    // Steady-state healthy path: never fired in this process — the
    // whole block stays out of the DOM.
    overridesRef.current = {
      watchdogState: "ok",
      watchdogLastFiredAt: null,
    };
    await page.reload();

    await expect(
      page.locator('[data-testid="text-ledger-monitor-watchdog"]'),
    ).toHaveCount(0);
  });
});
