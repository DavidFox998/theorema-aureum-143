import { test, expect, type Route, type Request } from "@playwright/test";
import {
  mkdtempSync,
  writeFileSync,
  rmSync,
  unlinkSync,
  existsSync,
  readFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import { createHash } from "node:crypto";
import http from "node:http";
import type { AddressInfo } from "node:net";
import express from "express";
import { createLedgerChecker } from "../../../api-server/src/routes/ledger.js";

/**
 * Task #169: end-to-end coverage for the per-row referee attribution
 * rendered inside the dashboard's "Recent dismissals" panel
 * (`panel-ledger-sidecar-forged-history`, task #150).
 *
 * Task #151 pinned the named-referee attribution on the LIVE
 * acknowledged badge, and task #167 covered the history panel's row
 * ordering / payload-sha attributes for two NAMED referees. Neither
 * test pins the panel's "anonymous" rendering for a dismissal that
 * landed with no `ackedBy` — a refactor of the row template could
 * silently drop the inline name on the named row, or drop the
 * italic "anonymous" placeholder on the unattributed row, without
 * any test catching it.
 *
 * This spec exercises one named ack (alice) and one anonymous ack
 * on two distinct forged payloads, then asserts the panel renders
 * BOTH rows with the correct inline text + `data-acked-by`
 * attribute:
 *   - row 0 (newest): anonymous → inline text "anonymous",
 *     `data-acked-by="anonymous"` (the production server's
 *     `acknowledgeForgedSidecar` normalizes a missing / null caller
 *     attribution to the literal string "anonymous" so the audit
 *     trail always names a dismisser — see task #139 / the comment
 *     above `ackedByNormalized` in `routes/ledger.ts`)
 *   - row 1: alice → inline text "alice",
 *     `data-acked-by="alice"`
 *
 * Fixture strategy mirrors
 * `ledger-sidecar-forged-history-panel.spec.ts` (task #167): boot an
 * in-process express server backed by a real `createLedgerChecker`,
 * forward `/api/ledger/integrity`,
 * `/api/ledger/sidecar-forged-ack`, and the history endpoint to it.
 * The ack handler resolves a bearer token to either a named referee
 * (named-token map, like the production `LEAN_REBUILD_TOKENS`
 * parser) or to `null` for an "anonymous" valid token (sentinel
 * value treated like the production shared `LEAN_REBUILD_TOKEN`
 * path, where the token authenticates but carries no attribution).
 */

const LEDGER_INTEGRITY_URL = "**/api/ledger/integrity*";
const LEDGER_ACK_URL = "**/api/ledger/sidecar-forged-ack";
const LEDGER_ACK_HISTORY_URL = "**/api/ledger/sidecar-forged-ack/history*";
const REBUILD_TOKEN_STORAGE_KEY = "lean-rebuild-token";

const ALICE_TOKEN = "alice-named-token-fixture";
const ALICE_NAME = "alice";
const ANON_TOKEN = "anonymous-shared-token-fixture";

function sha256(buf: Buffer | string): string {
  return createHash("sha256").update(buf).digest("hex");
}

type FixtureServer = {
  baseUrl: string;
  close: () => Promise<void>;
};

async function bootFixture(paths: {
  hitsPath: string;
  checkpointPath: string;
  lastOkPath: string;
  secretPath: string;
}): Promise<FixtureServer> {
  const checker = createLedgerChecker({
    hitsPath: paths.hitsPath,
    checkpointPath: paths.checkpointPath,
    lastOkPath: paths.lastOkPath,
    secretPath: paths.secretPath,
  });

  // Named-token map: bearer token → referee name. Tokens not in the
  // map but equal to `ANON_TOKEN` authenticate but resolve to `null`
  // (anonymous attribution), mirroring the production split between
  // `LEAN_REBUILD_TOKENS=alice:...` (named) and the shared
  // `LEAN_REBUILD_TOKEN` (no name resolved).
  const namedTokens = new Map<string, string>([[ALICE_TOKEN, ALICE_NAME]]);

  const app = express();
  app.use(express.json());
  app.use("/api", checker.router);
  app.post("/api/ledger/sidecar-forged-ack", (req, res) => {
    const auth = req.headers["authorization"] ?? "";
    const match = /^Bearer\s+(.+)$/i.exec(
      Array.isArray(auth) ? (auth[0] ?? "") : auth,
    );
    const provided = match ? match[1]?.trim() : "";
    if (!provided) {
      res
        .status(401)
        .json({ ok: false, error: "Unauthorized: bad referee token." });
      return;
    }
    let refereeName: string | null;
    if (namedTokens.has(provided)) {
      refereeName = namedTokens.get(provided) ?? null;
    } else if (provided === ANON_TOKEN) {
      refereeName = null;
    } else {
      res
        .status(401)
        .json({ ok: false, error: "Unauthorized: bad referee token." });
      return;
    }
    const result = checker.acknowledgeForgedSidecar(refereeName);
    if (!result.ok) {
      res.status(409).json({
        ok: false,
        error: "No forged-sidecar incident to acknowledge.",
      });
      return;
    }
    res.json({
      ok: true,
      acknowledgedAt: result.acknowledgedAt,
      alreadyAcknowledged: result.alreadyAcknowledged,
      payloadSha: result.payloadSha,
      ackedBy: result.ackedBy,
    });
  });
  // GET history endpoint is registered in production by `lean.ts`,
  // not by `checker.router`. Re-implement here against the same
  // rotating on-disk log (`${lastOkPath}.forged-ack.log.jsonl`) that
  // the ack handler appends to. Same contract the dashboard renders
  // — newest-first, capacity 20.
  const historyPath = `${paths.lastOkPath}.forged-ack.log.jsonl`;
  app.get("/api/ledger/sidecar-forged-ack/history", (req, res) => {
    const rawLimit = req.query["limit"];
    let limit = 20;
    if (typeof rawLimit === "string" && rawLimit.trim() !== "") {
      const parsed = Number(rawLimit);
      if (Number.isFinite(parsed) && parsed > 0) {
        limit = Math.floor(parsed);
      }
    }
    const entries: Array<{
      payloadSha: string;
      acknowledgedAt: string;
      ackedBy: string | null;
    }> = [];
    if (existsSync(historyPath)) {
      const raw = readFileSync(historyPath, "utf-8");
      const lines = raw.split("\n").filter((l) => l.length > 0);
      for (let i = lines.length - 1; i >= 0 && entries.length < limit; i--) {
        try {
          const parsed = JSON.parse(lines[i] as string) as Record<
            string,
            unknown
          >;
          const payloadSha = parsed["payloadSha"];
          const acknowledgedAt = parsed["acknowledgedAt"];
          if (
            typeof payloadSha !== "string" ||
            !/^[0-9a-f]{64}$/i.test(payloadSha) ||
            typeof acknowledgedAt !== "string"
          ) {
            continue;
          }
          const ackedByRaw = parsed["ackedBy"];
          entries.push({
            payloadSha: payloadSha.toLowerCase(),
            acknowledgedAt,
            ackedBy:
              typeof ackedByRaw === "string" && ackedByRaw.length > 0
                ? ackedByRaw
                : null,
          });
        } catch {
          continue;
        }
      }
    }
    res.json({ entries, capacity: 20 });
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

test.describe(
  "dashboard: Recent dismissals panel per-row attribution — named + anonymous (task #169)",
  () => {
    test("named referee row carries the name; anonymous row renders 'anonymous' with empty data-acked-by", async ({
      page,
    }) => {
      const tmpDir = mkdtempSync(
        path.join(tmpdir(), "ledger-forged-history-attr-e2e-"),
      );
      const seeded = seedTmpLedger(tmpDir);
      const { hitsPath, checkpointPath, lastOkPath, secretPath } = seeded;

      const markerV1 = "payload-v1-attr-named";
      const markerV2 = "payload-v2-attr-anon-distinct";
      const shaV1 = payloadShaFor(markerV1);
      const shaV2 = payloadShaFor(markerV2);
      expect(shaV1).not.toBe(shaV2);

      // --- Boot 1: forge payload-v1, alice acks ---
      writeForgedSidecar(lastOkPath, markerV1);
      let active = await bootFixture(seeded);

      try {
        await installForwarders(page, () => active);

        // Seed alice's named token for the first ack.
        await page.addInitScript(
          ([key, token]) => {
            window.localStorage.setItem(key as string, token as string);
          },
          [REBUILD_TOKEN_STORAGE_KEY, ALICE_TOKEN],
        );

        await page.goto("/");

        const banner = page.locator(
          '[data-testid="panel-ledger-sidecar-forged"]',
        );
        await expect(banner).toBeVisible();
        await expect(banner).toHaveAttribute("data-acknowledged", "false");

        const ackButton = page.locator(
          '[data-testid="button-ack-ledger-sidecar-forged"]',
        );
        await expect(ackButton).toBeEnabled();
        await ackButton.click();
        await expect(banner).toHaveAttribute("data-acknowledged", "true");

        // --- Restart with payload-v2 (distinct sha) ---
        // Same pattern as task #167: re-forge with NEW bytes so the
        // prior ack file is discarded (sha mismatch) and the banner
        // re-fires un-acked on the next reload.
        await active.close();
        writeForgedSidecar(lastOkPath, markerV2);
        active = await bootFixture(seeded);

        // Swap to the anonymous-shared token. The fixture's ack
        // handler resolves this to a `null` referee name, so the
        // ack writes an anonymous row into the on-disk history log.
        await page.addInitScript(
          ([key, token]) => {
            window.localStorage.setItem(key as string, token as string);
          },
          [REBUILD_TOKEN_STORAGE_KEY, ANON_TOKEN],
        );
        await page.reload();

        await expect(banner).toBeVisible();
        await expect(banner).toHaveAttribute("data-acknowledged", "false");

        // After one ack, the history panel renders alice's row.
        const historyPanel = page.locator(
          '[data-testid="panel-ledger-sidecar-forged-history"]',
        );
        await expect(historyPanel).toBeVisible();
        const aliceRow = page.locator(
          '[data-testid="row-ledger-sidecar-forged-history-0"]',
        );
        await expect(aliceRow).toHaveAttribute("data-acked-by", ALICE_NAME);
        await expect(aliceRow).toContainText(ALICE_NAME);

        // --- Ack #2: anonymous acks payload-v2 ---
        await expect(ackButton).toBeEnabled();
        await ackButton.click();
        await expect(banner).toHaveAttribute("data-acknowledged", "true");

        // --- Restart with same payload-v2 so the banner + history
        // panel stay mounted and we can read both rows.
        await active.close();
        writeForgedSidecar(lastOkPath, markerV2);
        active = await bootFixture(seeded);

        await page.reload();
        await expect(banner).toBeVisible();
        await expect(historyPanel).toBeVisible();

        // Both rows now present, newest-first: row-0 anonymous/v2,
        // row-1 alice/v1.
        await expect(
          page.locator(
            '[data-testid="text-ledger-sidecar-forged-history-count"]',
          ),
        ).toHaveText("2 of last 20");

        const row0 = page.locator(
          '[data-testid="row-ledger-sidecar-forged-history-0"]',
        );
        // Anonymous: production's `acknowledgeForgedSidecar`
        // normalizes a null caller attribution to the literal string
        // "anonymous" (task #139), so the dashboard renders the
        // attribute and visible text as "anonymous". Pin both — a
        // refactor that re-introduces a `null` ackedBy on the wire
        // would flip the attribute to "" and silently break the
        // audit trail.
        await expect(row0).toHaveAttribute("data-acked-by", "anonymous");
        await expect(row0).toHaveAttribute("data-payload-sha", shaV2);
        await expect(row0).toContainText("anonymous");
        // Anonymous row must NOT contain alice's name (would mean
        // the per-row attribution leaked across rows).
        await expect(row0).not.toContainText(ALICE_NAME);

        const row1 = page.locator(
          '[data-testid="row-ledger-sidecar-forged-history-1"]',
        );
        // Named: data-acked-by carries the raw name, visible text
        // contains the name, and the row does NOT fall back to the
        // anonymous placeholder.
        await expect(row1).toHaveAttribute("data-acked-by", ALICE_NAME);
        await expect(row1).toHaveAttribute("data-payload-sha", shaV1);
        await expect(row1).toContainText(ALICE_NAME);
        await expect(row1).not.toContainText("anonymous");

        await expect(
          page.locator(
            '[data-testid^="row-ledger-sidecar-forged-history-"]',
          ),
        ).toHaveCount(2);
      } finally {
        await active.close();
        for (const p of [
          lastOkPath,
          secretPath,
          `${lastOkPath}.forged-ack`,
          `${lastOkPath}.forged-ack.log.jsonl`,
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
