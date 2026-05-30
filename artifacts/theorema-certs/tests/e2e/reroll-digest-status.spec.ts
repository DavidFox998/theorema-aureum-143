import { test, expect, type Route, type Page } from "@playwright/test";

/**
 * Task #223: end-to-end coverage for the re-roll digest status panel.
 *
 * Task #198 made the daily re-roll digest short-circuit (logging "no
 * sinks configured, digest disabled") when neither
 * MORNINGSTAR_ALERT_WEBHOOK_URL nor MORNINGSTAR_ALERT_EMAIL_TO is set —
 * a state only visible in the server logs. Task #223 surfaces the
 * digest's effective state on `GET /api/ledger/integrity` under
 * `rerollDigest` and renders it on the dashboard so operators can tell
 * a running digest from one disabled by interval vs. silently disabled
 * for want of an alert sink. The resolver itself is unit-tested in
 * `artifacts/api-server/src/lib/rerollDigest.test.ts`; this spec covers
 * the dashboard rendering path.
 *
 * Strategy mirrors `ledger-verifier-not-running.spec.ts`: drive the
 * dashboard through the global proxy and mock `/api/ledger/integrity`
 * so we can pin `rerollDigest.state` per test (the real state is
 * env-derived at api-server boot and cannot be hand-seeded from
 * outside the process).
 *
 * Selectors under test (see `src/pages/dashboard.tsx`):
 *   - `[data-testid="text-reroll-digest"]` carries
 *     `data-digest-state="enabled"|"disabled_interval_off"|"disabled_no_sink"`
 *   - `[data-testid="text-reroll-digest-cadence"]` /
 *     `[data-testid="text-reroll-digest-window"]` only render when enabled
 */

const LEDGER_INTEGRITY_URL = "**/api/ledger/integrity*";

type RerollDigest = {
  state: "enabled" | "disabled_interval_off" | "disabled_no_sink";
  intervalSeconds: number | null;
  windowHours: number | null;
};

function buildLedgerIntegrityBody(rerollDigest: RerollDigest) {
  const nowIso = new Date().toISOString();
  const zeroSha =
    "0000000000000000000000000000000000000000000000000000000000000000";
  return {
    status: "ok",
    failureMode: null,
    reason: null,
    checkpointSize: 1024,
    checkpointSha: zeroSha,
    liveSize: 1024,
    livePrefixSha: zeroSha,
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
    monitor: {
      enabled: false,
      intervalSeconds: null,
      lastTickAt: null,
      lastAlertedFailureMode: null,
      lastAcknowledgedAlertId: null,
      watchdogState: null,
      watchdogLastFiredAt: null,
    },
    rerollDigest,
  };
}

async function gotoWithDigest(page: Page, rerollDigest: RerollDigest) {
  await page.route(LEDGER_INTEGRITY_URL, async (route: Route) => {
    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify(buildLedgerIntegrityBody(rerollDigest)),
    });
  });
  await page.goto("/");
}

test.describe("dashboard: re-roll digest status panel", () => {
  test("enabled state shows the cadence and digest window", async ({
    page,
  }) => {
    await gotoWithDigest(page, {
      state: "enabled",
      intervalSeconds: 86400,
      windowHours: 24,
    });
    const panel = page.locator('[data-testid="text-reroll-digest"]');
    await expect(panel).toBeVisible();
    await expect(panel).toHaveAttribute("data-digest-state", "enabled");
    await expect(panel).toContainText("enabled");
    await expect(
      page.locator('[data-testid="text-reroll-digest-cadence"]'),
    ).toContainText("1d");
    await expect(
      page.locator('[data-testid="text-reroll-digest-window"]'),
    ).toContainText("24h");
  });

  test("no-sink state is amber, names the fix, and drops the cadence pills", async ({
    page,
  }) => {
    // The misconfiguration case operators must be able to distinguish:
    // interval live but no alert sink, so the digest silently never runs.
    await gotoWithDigest(page, {
      state: "disabled_no_sink",
      intervalSeconds: null,
      windowHours: null,
    });
    const panel = page.locator('[data-testid="text-reroll-digest"]');
    await expect(panel).toBeVisible();
    await expect(panel).toHaveAttribute(
      "data-digest-state",
      "disabled_no_sink",
    );
    await expect(panel).toContainText("disabled");
    await expect(panel).toContainText("no alert sink");
    await expect(
      page.locator('[data-testid="text-reroll-digest-cadence"]'),
    ).toHaveCount(0);
  });

  test("interval-off state reads as a deliberate opt-out, not a misconfig", async ({
    page,
  }) => {
    await gotoWithDigest(page, {
      state: "disabled_interval_off",
      intervalSeconds: null,
      windowHours: null,
    });
    const panel = page.locator('[data-testid="text-reroll-digest"]');
    await expect(panel).toBeVisible();
    await expect(panel).toHaveAttribute(
      "data-digest-state",
      "disabled_interval_off",
    );
    await expect(panel).toContainText("disabled");
    await expect(panel).toContainText(
      "MORNINGSTAR_REROLL_DIGEST_INTERVAL_SECONDS=off",
    );
    // Must NOT read like the fixable no-sink case.
    await expect(panel).not.toContainText("no alert sink");
  });
});
