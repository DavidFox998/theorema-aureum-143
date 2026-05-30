import { test, expect, type Route, type Request } from "@playwright/test";
import {
  mkdtempSync,
  writeFileSync,
  rmSync,
  unlinkSync,
  existsSync,
  statSync,
} from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import { createHash } from "node:crypto";
import http from "node:http";
import type { AddressInfo } from "node:net";
import express from "express";
import { createLedgerChecker } from "../../../api-server/src/routes/ledger.js";

/**
 * Task #237: end-to-end coverage for the live-log fullness hint and the
 * next-to-be-dropped archive badge in the "Recent dismissals" panel
 * (`panel-ledger-sidecar-forged-history` in
 * `artifacts/theorema-certs/src/pages/dashboard.tsx`).
 *
 * Task #207 added two pieces of UI to that panel:
 *
 *   1. A live-log fullness hint —
 *      `text-ledger-sidecar-forged-history-live-fullness` (carrying
 *      `data-live-size` / `data-max-bytes`) plus the meter
 *      `meter-ledger-sidecar-forged-history-live` whose inner bar's
 *      width is `livePct%` and whose colour tier is red (≥90%),
 *      amber (≥60%), or faded-red (<60%).
 *   2. A next-to-be-dropped warning badge —
 *      `badge-ledger-sidecar-forged-history-next-drop-<index>` plus a
 *      `data-next-drop="true"` attribute on the rotation tab whose
 *      index equals `maxRotations` (the archive the next rotation will
 *      unlink).
 *
 * The API shape is already covered at the checker layer
 * (`ledger.integration.test.ts`, the task-#207 assertions on
 * `live.maxBytes` / `live.maxRotations` / `live.liveSize`), but the
 * React rendering — that the meter width/colour tier and the badge
 * actually appear under a real forged incident with rotations on disk
 * — had no browser coverage. A regression that mis-tiered the meter,
 * stopped rendering the hint, or flagged the wrong rotation tab would
 * have landed unnoticed.
 *
 * This spec forces two real rotation cycles (so `.1` and `.2` both
 * exist on disk with `MAX_ROTATIONS=2`, i.e. `.2`'s index equals the
 * rotation cap), then repopulates the live log with a single entry
 * that sits in the amber tier (≈70% of the 200-byte cap). It then
 * boots the hermetic fixture and asserts:
 *   - the fullness hint text + data attributes match the on-disk live
 *     size and the env-resolved byte cap,
 *   - the meter renders with the matching width and the amber colour
 *     class (computed from the real on-disk size, not hardcoded),
 *   - the next-drop badge + `data-next-drop` appear on the `.2` tab
 *     (index === MAX_ROTATIONS) and NOT on `.1`.
 *
 * Hermetic fixture pattern mirrors
 * `ledger-sidecar-forged-history-rotation.spec.ts` (task #185): a
 * tmp-dir-backed `createLedgerChecker` mounted at `/api` via an
 * in-process express server, plus `page.route` forwarders for the
 * three ledger URLs the dashboard reads. The history GET delegates to
 * `checker.listForgedAckHistory()` so the response carries the
 * `liveSize` / `maxBytes` / `maxRotations` / `rotations` fields the
 * panel renders.
 */

const LEDGER_INTEGRITY_URL = "**/api/ledger/integrity*";
const LEDGER_ACK_URL = "**/api/ledger/sidecar-forged-ack";
const LEDGER_ACK_HISTORY_URL = "**/api/ledger/sidecar-forged-ack/history*";

function sha256(buf: Buffer | string): string {
  return createHash("sha256").update(buf).digest("hex");
}

function forgedSidecarBytes(marker: string): Buffer {
  return Buffer.from(
    JSON.stringify({
      lastOkAt: "2099-01-01T00:00:00.000Z",
      lastCheckedAt: "2099-01-01T00:00:00.000Z",
      marker,
    }) + "\n",
  );
}

function writeForgedSidecar(lastOkPath: string, marker: string): void {
  writeFileSync(lastOkPath, forgedSidecarBytes(marker));
}

function payloadShaFor(marker: string): string {
  return sha256(forgedSidecarBytes(marker));
}

function seedTmpLedger(tmpDir: string): {
  hitsPath: string;
  checkpointPath: string;
  lastOkPath: string;
  secretPath: string;
} {
  const hitsPath = path.join(tmpDir, "hits.txt");
  const checkpointPath = path.join(tmpDir, "hits.txt.checkpoint");
  const lastOkPath = path.join(tmpDir, "hits.txt.lastok");
  const secretPath = path.join(tmpDir, "hits.txt.lastok.key");
  const sealed = "line1\nline2\nline3\n";
  const buf = Buffer.from(sealed, "utf-8");
  writeFileSync(hitsPath, buf);
  writeFileSync(checkpointPath, `${buf.length} ${sha256(buf)}\n`);
  writeFileSync(secretPath, "ab".repeat(32) + "\n");
  return { hitsPath, checkpointPath, lastOkPath, secretPath };
}

type SeedPaths = ReturnType<typeof seedTmpLedger>;

/**
 * Drive a single forge → new-checker → ack cycle. Each call writes a
 * fresh forged sidecar with a unique marker (so the checker produces a
 * distinct `payloadSha`), instantiates a new `createLedgerChecker`
 * (which picks up the on-disk forged incident), and acknowledges it —
 * appending to the rotating history log and triggering
 * `rotateForgedAckHistory` once the live file crosses the byte cap.
 */
function ackOnce(seeded: SeedPaths, marker: string, refereeName: string): void {
  writeForgedSidecar(seeded.lastOkPath, marker);
  const checker = createLedgerChecker(seeded);
  const r = checker.acknowledgeForgedSidecar(refereeName);
  if (!r.ok) {
    throw new Error(`ackOnce failed for marker=${marker}: no_incident`);
  }
  if (r.alreadyAcknowledged) {
    throw new Error(
      `ackOnce produced alreadyAcknowledged for marker=${marker} — ` +
        `prior ack file must have collided on payloadSha`,
    );
  }
}

type FixtureServer = {
  baseUrl: string;
  close: () => Promise<void>;
};

async function bootFixture(seeded: SeedPaths): Promise<FixtureServer> {
  const checker = createLedgerChecker(seeded);
  const app = express();
  app.use(express.json());
  app.use("/api", checker.router);
  // History GET via the checker's own lister so the response shape
  // (entries + rotations + capacity + liveSize + maxBytes +
  // maxRotations) matches what the dashboard's orval hook expects.
  app.get("/api/ledger/sidecar-forged-ack/history", (req, res) => {
    const rawLimit = req.query["limit"];
    let limit: number | undefined;
    if (typeof rawLimit === "string" && rawLimit.trim() !== "") {
      const parsed = Number(rawLimit);
      if (Number.isFinite(parsed) && parsed > 0) limit = Math.floor(parsed);
    }
    const rawRotation = req.query["rotation"];
    let rotation: number | undefined;
    if (typeof rawRotation === "string" && rawRotation.trim() !== "") {
      const parsed = Number(rawRotation);
      if (Number.isFinite(parsed) && parsed >= 0) {
        rotation = Math.floor(parsed);
      }
    }
    res.json(checker.listForgedAckHistory(limit, rotation));
  });
  const srv = http.createServer(app);
  await new Promise<void>((resolve) => srv.listen(0, "127.0.0.1", resolve));
  const port = (srv.address() as AddressInfo).port;
  return {
    baseUrl: `http://127.0.0.1:${port}`,
    close: async () => {
      await new Promise<void>((resolve, reject) =>
        srv.close((err) => (err ? reject(err) : resolve())),
      );
    },
  };
}

async function installForwarders(
  page: import("@playwright/test").Page,
  getActive: () => FixtureServer,
): Promise<void> {
  const forward = async (route: Route, request: Request, suffix: string) => {
    const upstream = new URL(request.url());
    const forwarded = `${getActive().baseUrl}${suffix}${upstream.search}`;
    const postData = request.postData();
    const res = await fetch(forwarded, {
      method: request.method(),
      headers: request.headers(),
      body: postData ?? undefined,
    });
    const body = Buffer.from(await res.arrayBuffer());
    const headers: Record<string, string> = {};
    res.headers.forEach((v, k) => {
      const lk = k.toLowerCase();
      if (
        lk === "content-encoding" ||
        lk === "content-length" ||
        lk === "transfer-encoding"
      ) {
        return;
      }
      headers[k] = v;
    });
    await route.fulfill({ status: res.status, headers, body });
  };
  await page.route(LEDGER_INTEGRITY_URL, (route, request) =>
    forward(route, request, "/api/ledger/integrity"),
  );
  await page.route(LEDGER_ACK_URL, (route, request) =>
    forward(route, request, "/api/ledger/sidecar-forged-ack"),
  );
  await page.route(LEDGER_ACK_HISTORY_URL, (route, request) =>
    forward(route, request, "/api/ledger/sidecar-forged-ack/history"),
  );
}

function fmtSize(n: number): string {
  if (n < 1024) return `${n} B`;
  if (n < 1024 * 1024) return `${(n / 1024).toFixed(1)} KB`;
  return `${(n / (1024 * 1024)).toFixed(2)} MB`;
}

test.describe(
  "dismissals fullness hint + next-to-be-dropped badge render (task #237)",
  () => {
    // The rotator reads `process.env.MORNINGSTAR_FORGED_ACK_HISTORY_*`
    // every append, so set/restore around this spec only — other
    // forged-ack specs in the same worker must see the default policy.
    const ENV_BYTES_KEY = "MORNINGSTAR_FORGED_ACK_HISTORY_MAX_BYTES";
    const ENV_ROTS_KEY = "MORNINGSTAR_FORGED_ACK_HISTORY_MAX_ROTATIONS";
    let prevBytes: string | undefined;
    let prevRots: string | undefined;

    const MAX_BYTES = 200;
    const MAX_ROTATIONS = 2;

    test.beforeAll(() => {
      prevBytes = process.env[ENV_BYTES_KEY];
      prevRots = process.env[ENV_ROTS_KEY];
      // One JSONL entry is ~140 bytes. 200 fits exactly one; the
      // second append tips it over and triggers a rotation. A single
      // repopulating entry afterwards sits at ~70% of the cap — the
      // amber tier (60% ≤ pct < 90%).
      process.env[ENV_BYTES_KEY] = String(MAX_BYTES);
      process.env[ENV_ROTS_KEY] = String(MAX_ROTATIONS);
    });

    test.afterAll(() => {
      if (prevBytes === undefined) delete process.env[ENV_BYTES_KEY];
      else process.env[ENV_BYTES_KEY] = prevBytes;
      if (prevRots === undefined) delete process.env[ENV_ROTS_KEY];
      else process.env[ENV_ROTS_KEY] = prevRots;
    });

    test("fullness hint text + meter tier render, and the next-drop badge lights the archive at the rotation cap", async ({
      page,
    }) => {
      const tmpDir = mkdtempSync(
        path.join(tmpdir(), "ledger-forged-history-fullness-e2e-"),
      );
      const seeded = seedTmpLedger(tmpDir);
      const { lastOkPath, secretPath, hitsPath, checkpointPath } = seeded;
      const historyPath = `${lastOkPath}.forged-ack.log.jsonl`;
      const rot1 = `${historyPath}.1`;
      const rot2 = `${historyPath}.2`;
      const rot3 = `${historyPath}.3`;

      const finalMarker = "fullness-vfinal";
      const finalRef = "judy";

      let active: FixtureServer | null = null;
      try {
        // --- Ack 1 (alice): live log gets one entry, below the cap ---
        ackOnce(seeded, "fullness-v1", "alice");
        expect(existsSync(historyPath)).toBe(true);
        expect(existsSync(rot1)).toBe(false);

        // --- Ack 2 (bob): live crosses MAX_BYTES → FIRST rotation,
        //     .1 = alice/bob, live deleted. ---
        ackOnce(seeded, "fullness-v2", "bob");
        expect(existsSync(rot1)).toBe(true);
        expect(existsSync(historyPath)).toBe(false);
        expect(existsSync(rot2)).toBe(false);

        // --- Ack 3 (carol): live log recreated with one entry ---
        ackOnce(seeded, "fullness-v3", "carol");
        expect(existsSync(historyPath)).toBe(true);

        // --- Ack 4 (dave): live crosses again → SECOND rotation. The
        //     existing .1 (alice/bob) shifts to .2, live (carol/dave)
        //     becomes the new .1. Now .1 and .2 both exist, so .2's
        //     index === MAX_ROTATIONS → it's the next to be dropped. ---
        ackOnce(seeded, "fullness-v4", "dave");
        expect(existsSync(rot1)).toBe(true);
        expect(existsSync(rot2)).toBe(true);
        // MAX_ROTATIONS=2: nothing past .2 may exist.
        expect(existsSync(rot3)).toBe(false);
        expect(existsSync(historyPath)).toBe(false);

        // --- Final ack (judy): repopulate the live log with one entry
        //     so the fullness hint + meter render against a non-empty,
        //     sub-cap live file. ---
        ackOnce(seeded, finalMarker, finalRef);
        expect(existsSync(historyPath)).toBe(true);

        // The on-disk live size drives the fullness hint; derive the
        // expected percentage + colour tier from it rather than
        // hardcoding (entry size varies slightly with referee/marker).
        const liveSize = statSync(historyPath).size;
        expect(liveSize).toBeGreaterThan(0);
        expect(liveSize).toBeLessThan(MAX_BYTES);
        const livePct = Math.min(100, (liveSize / MAX_BYTES) * 100);
        // Confirm the fixture lands in the amber tier so this spec
        // genuinely exercises the middle colour branch.
        expect(livePct).toBeGreaterThanOrEqual(60);
        expect(livePct).toBeLessThan(90);
        const expectedColorClass = "bg-amber-500";
        const expectedPctText = `(${livePct.toFixed(0)}%)`;

        // Re-forge the sidecar with the final marker so the next
        // checker boot sees a forged incident whose payloadSha matches
        // judy's on-disk ack — keeps the banner visible + acknowledged.
        writeForgedSidecar(lastOkPath, finalMarker);

        active = await bootFixture(seeded);
        await installForwarders(page, () => active!);
        await page.goto("/");

        const banner = page.locator(
          '[data-testid="panel-ledger-sidecar-forged"]',
        );
        await expect(banner).toBeVisible();
        await expect(banner).toHaveAttribute("data-acknowledged", "true");

        const historyPanel = page.locator(
          '[data-testid="panel-ledger-sidecar-forged-history"]',
        );
        await expect(historyPanel).toBeVisible();

        // --- Fullness hint text + data attributes ---
        const fullness = page.locator(
          '[data-testid="text-ledger-sidecar-forged-history-live-fullness"]',
        );
        await expect(fullness).toBeVisible();
        await expect(fullness).toHaveAttribute(
          "data-live-size",
          String(liveSize),
        );
        await expect(fullness).toHaveAttribute(
          "data-max-bytes",
          String(MAX_BYTES),
        );
        await expect(fullness).toContainText(
          `live: ${fmtSize(liveSize)} / ${fmtSize(MAX_BYTES)} ${expectedPctText}`,
        );

        // --- Meter: renders, inner bar carries the amber tier class
        //     and a width matching the computed percentage. ---
        const meter = page.locator(
          '[data-testid="meter-ledger-sidecar-forged-history-live"]',
        );
        await expect(meter).toBeVisible();
        const bar = meter.locator('div[style*="width"]');
        await expect(bar).toHaveClass(new RegExp(expectedColorClass));
        const widthStyle = await bar.evaluate(
          (el) => (el as HTMLElement).style.width,
        );
        const renderedPct = Number.parseFloat(widthStyle.replace("%", ""));
        expect(renderedPct).toBeCloseTo(livePct, 5);

        // --- Rotations strip: .1 + .2 present, .3 capped out. ---
        const rotationsStrip = page.locator(
          '[data-testid="panel-ledger-sidecar-forged-history-rotations"]',
        );
        await expect(rotationsStrip).toBeVisible();
        const tab1 = page.locator(
          '[data-testid="btn-ledger-sidecar-forged-history-rotation-1"]',
        );
        const tab2 = page.locator(
          '[data-testid="btn-ledger-sidecar-forged-history-rotation-2"]',
        );
        await expect(tab1).toBeVisible();
        await expect(tab2).toBeVisible();
        await expect(
          page.locator(
            '[data-testid="btn-ledger-sidecar-forged-history-rotation-3"]',
          ),
        ).toHaveCount(0);

        // --- Next-to-be-dropped badge: only on the .2 tab (index ===
        //     MAX_ROTATIONS), never on .1. ---
        await expect(tab2).toHaveAttribute("data-next-drop", "true");
        await expect(
          page.locator(
            '[data-testid="badge-ledger-sidecar-forged-history-next-drop-2"]',
          ),
        ).toBeVisible();
        await expect(tab1).not.toHaveAttribute("data-next-drop", "true");
        await expect(
          page.locator(
            '[data-testid="badge-ledger-sidecar-forged-history-next-drop-1"]',
          ),
        ).toHaveCount(0);
      } finally {
        if (active) await active.close();
        for (const p of [
          lastOkPath,
          secretPath,
          `${lastOkPath}.forged-ack`,
          historyPath,
          rot1,
          rot2,
          rot3,
          hitsPath,
          checkpointPath,
        ]) {
          try {
            if (existsSync(p)) unlinkSync(p);
          } catch {
            /* ignore */
          }
        }
        rmSync(tmpDir, { recursive: true, force: true });
      }
    });
  },
);
