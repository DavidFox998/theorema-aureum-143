import { test, expect, type Route } from "@playwright/test";

/**
 * Task #161: end-to-end coverage for the "subject as row header" +
 * "MONITOR" badge added to the Recent ledger alerts panel.
 *
 * Task #144 added distinct human-readable subject lines to email +
 * webhook deliveries (`subject` field on the payload). Task #161
 * surfaces that same subject as the primary header on each row of
 * the dashboard's Ledger Alerts card, and flags watchdog-stalled /
 * monitor-recovered rows with a small "MONITOR" badge so a glance
 * tells operator-stalled signals apart from real tamper alerts.
 *
 * Selectors / copy under test
 * (`artifacts/theorema-certs/src/pages/dashboard.tsx` ~1795–1875):
 *   - `[data-testid="text-ledger-alert-subject-N"]` carries the
 *     `subject` from the payload as primary header text.
 *   - `[data-testid="text-ledger-alert-monitor-badge-N"]` renders
 *     the small "MONITOR" badge on stalled-monitor and
 *     monitor-recovered rows.
 *   - `[data-testid="row-ledger-alert-N"]` carries
 *     `data-monitor-row="true"` on the same rows.
 *   - `[data-testid="text-ledger-alert-message-N"]` still renders
 *     the underlying message as secondary body text (regression
 *     guard: a refactor must not silently drop it).
 *
 * Three rows are mocked into the response so the spec pins:
 *   1. a stalled-monitor row (subject + badge + red header)
 *   2. a monitor-recovered row (subject + badge + green header)
 *   3. a real tamper row (subject + NO badge + red header)
 */

const LEDGER_ALERTS_URL = "**/api/lean/ledger-alerts*";

function buildMonitorAlertsResponse() {
  const stalledTimestamp = "2026-05-28T01:00:00.000Z";
  const recoveredTimestamp = "2026-05-28T01:05:00.000Z";
  const tamperTimestamp = "2026-05-28T01:10:00.000Z";
  // Order in the live ring buffer is oldest-first; the route walks
  // it most-recent-first, so the tamper row ends up at index 0 in
  // the rendered list, then monitor-recovered, then stalled.
  return {
    alerts: [
      {
        id: "tamper-row-id",
        acknowledgedAt: null,
        timestamp: tamperTimestamp,
        workflow: "zeta-burst-101-10000",
        message:
          "Ledger checkpoint verification failed: live prefix sha mismatch",
        subject:
          "[MorningStar] Ledger integrity alert: zeta-burst-101-10000",
        failureMode: "hits_rewritten_in_place",
        previousFailureMode: null,
        recovery: null,
        hitsPath: "data/hits.txt",
        checkpointPath: "data/hits.txt.checkpoint",
        expectedSize: 1024,
        actualSize: 1024,
        expectedSha:
          "0000000000000000000000000000000000000000000000000000000000000000",
        source: "kernel._verify_checkpoint",
        delivery: {
          webhook: { status: "ok", error: null },
          email: { status: "ok", error: null },
        },
      },
      {
        id: "monitor-recovered-row-id",
        acknowledgedAt: null,
        timestamp: recoveredTimestamp,
        workflow: "api-server",
        message:
          "The auto-integrity check has resumed — push alerts on ledger tamper are firing again",
        subject: "[MorningStar] Ledger monitor RECOVERED: api-server",
        failureMode: "recovered",
        previousFailureMode: "monitor_stalled",
        recovery: null,
        hitsPath: "data/hits.txt",
        checkpointPath: "data/hits.txt.checkpoint",
        expectedSize: null,
        actualSize: null,
        expectedSha: null,
        source: "api-server.checkWatchdog",
        delivery: {
          webhook: { status: "ok", error: null },
          email: { status: "ok", error: null },
        },
      },
      {
        id: "monitor-stalled-row-id",
        acknowledgedAt: null,
        timestamp: stalledTimestamp,
        workflow: "api-server",
        message:
          "The auto-integrity check has stalled — push alerts on ledger tamper may not fire until the api-server is investigated",
        subject:
          "[MorningStar] Ledger MONITOR STALLED — push alerts may be silent: api-server",
        failureMode: "monitor_stalled",
        previousFailureMode: null,
        recovery: null,
        hitsPath: "data/hits.txt",
        checkpointPath: "data/hits.txt.checkpoint",
        expectedSize: null,
        actualSize: null,
        expectedSha: null,
        source: "api-server.checkWatchdog",
        delivery: {
          webhook: { status: "ok", error: null },
          email: { status: "ok", error: null },
        },
      },
    ],
    limit: 50,
    totalReturned: 3,
    logPath: "data/ledger-alerts.jsonl",
    logExists: true,
    ackGcDropped: 0,
    rotation: 0,
    availableRotations: [],
  };
}

async function installLedgerAlertsMock(
  page: import("@playwright/test").Page,
) {
  await page.route(LEDGER_ALERTS_URL, async (route: Route) => {
    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify(buildMonitorAlertsResponse()),
    });
  });
}

test.describe("dashboard: ledger alerts subject header + MONITOR badge", () => {
  test("renders the alert subject as the row header and flags monitor rows with a MONITOR badge", async ({
    page,
  }) => {
    await installLedgerAlertsMock(page);

    await page.goto("/");

    const panel = page.locator('[data-testid="panel-ledger-alerts"]');
    await expect(panel).toBeVisible();

    // Index 0: tamper row — subject is the integrity-alert wording,
    // and the MONITOR badge MUST NOT fire (regression guard: a
    // future change that flags everything as monitor would falsely
    // calm an on-call).
    const tamperSubject = page.locator(
      '[data-testid="text-ledger-alert-subject-0"]',
    );
    await expect(tamperSubject).toBeVisible();
    await expect(tamperSubject).toHaveText(
      "[MorningStar] Ledger integrity alert: zeta-burst-101-10000",
    );
    const tamperRow = page.locator('[data-testid="row-ledger-alert-0"]');
    await expect(tamperRow).not.toHaveAttribute("data-monitor-row", "true");
    await expect(
      page.locator('[data-testid="text-ledger-alert-monitor-badge-0"]'),
    ).toHaveCount(0);
    // Secondary body text still carries the underlying message.
    await expect(
      page.locator('[data-testid="text-ledger-alert-message-0"]'),
    ).toContainText("live prefix sha mismatch");

    // Index 1: monitor-recovered row — subject is the RECOVERED
    // wording, MONITOR badge fires, row carries the data attribute.
    const recoveredSubject = page.locator(
      '[data-testid="text-ledger-alert-subject-1"]',
    );
    await expect(recoveredSubject).toBeVisible();
    await expect(recoveredSubject).toHaveText(
      "[MorningStar] Ledger monitor RECOVERED: api-server",
    );
    const recoveredRow = page.locator('[data-testid="row-ledger-alert-1"]');
    await expect(recoveredRow).toHaveAttribute("data-monitor-row", "true");
    const recoveredBadge = page.locator(
      '[data-testid="text-ledger-alert-monitor-badge-1"]',
    );
    await expect(recoveredBadge).toBeVisible();
    await expect(recoveredBadge).toHaveText("MONITOR");

    // Index 2: stalled-monitor row — subject is the STALLED
    // wording, MONITOR badge fires, secondary message body still
    // names the api-server investigation pointer.
    const stalledSubject = page.locator(
      '[data-testid="text-ledger-alert-subject-2"]',
    );
    await expect(stalledSubject).toBeVisible();
    await expect(stalledSubject).toHaveText(
      "[MorningStar] Ledger MONITOR STALLED — push alerts may be silent: api-server",
    );
    const stalledRow = page.locator('[data-testid="row-ledger-alert-2"]');
    await expect(stalledRow).toHaveAttribute("data-monitor-row", "true");
    const stalledBadge = page.locator(
      '[data-testid="text-ledger-alert-monitor-badge-2"]',
    );
    await expect(stalledBadge).toBeVisible();
    await expect(stalledBadge).toHaveText("MONITOR");
    await expect(
      page.locator('[data-testid="text-ledger-alert-message-2"]'),
    ).toContainText("api-server is investigated");
  });
});
