import { test, expect, type Route, type Request } from "@playwright/test";
import { mkdtempSync, writeFileSync, rmSync, chmodSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import { createHash } from "node:crypto";
import http from "node:http";
import type { AddressInfo } from "node:net";
import express from "express";
import { createLedgerRouter } from "../../../api-server/src/routes/ledger.js";

/**
 * Task #148: end-to-end coverage for the "Strict keyfile mode: ON / OFF"
 * badge on the Ledger Integrity dashboard card (task #137).
 *
 * The badge is sourced from `sidecarSecretStrictMode` on
 * `GET /api/ledger/integrity`, which is derived at boot via
 * `isSidecarSecretStrictMode(process.env.LEDGER_SIDECAR_SECRET_STRICT_MODE)`.
 * We boot a real `createLedgerRouter` over a tmp dir for each posture
 * (with the env var toggled before construction) and forward
 * `/api/ledger/integrity` from the dashboard into the fixture, so the
 * badge is fed by the REAL field the production code path produces.
 */

const LEDGER_INTEGRITY_URL = "**/api/ledger/integrity*";

function sha256(buf: Buffer | string): string {
  return createHash("sha256").update(buf).digest("hex");
}

type FixtureServer = {
  baseUrl: string;
  close: () => Promise<void>;
};

async function startFixture(strictMode: boolean): Promise<FixtureServer> {
  const tmpDir = mkdtempSync(path.join(tmpdir(), "ledger-strict-e2e-"));
  const hitsPath = path.join(tmpDir, "hits.txt");
  const checkpointPath = path.join(tmpDir, "hits.txt.checkpoint");
  const lastOkPath = path.join(tmpDir, "hits.txt.lastok");
  const secretPath = path.join(tmpDir, "hits.txt.lastok.key");

  const sealed = "line1\nline2\nline3\n";
  const buf = Buffer.from(sealed, "utf-8");
  writeFileSync(hitsPath, buf);
  writeFileSync(checkpointPath, `${buf.length} ${sha256(buf)}\n`);
  writeFileSync(secretPath, "ab".repeat(32) + "\n");
  // Task #123 strict mode hard-fails boot when the keyfile is group-
  // or world-readable. Tighten to 0600 BEFORE constructing the router
  // so the ON-posture fixture is not rejected by `loadOrCreateSecret`.
  chmodSync(secretPath, 0o600);

  const prevEnv = process.env.LEDGER_SIDECAR_SECRET_STRICT_MODE;
  if (strictMode) {
    process.env.LEDGER_SIDECAR_SECRET_STRICT_MODE = "1";
  } else {
    delete process.env.LEDGER_SIDECAR_SECRET_STRICT_MODE;
  }
  let router;
  try {
    router = createLedgerRouter({
      hitsPath,
      checkpointPath,
      lastOkPath,
      secretPath,
    });
  } finally {
    if (prevEnv === undefined) {
      delete process.env.LEDGER_SIDECAR_SECRET_STRICT_MODE;
    } else {
      process.env.LEDGER_SIDECAR_SECRET_STRICT_MODE = prevEnv;
    }
  }

  const app = express();
  app.use("/api", router);
  const srv = http.createServer(app);
  await new Promise<void>((resolve) => srv.listen(0, "127.0.0.1", resolve));
  const port = (srv.address() as AddressInfo).port;

  return {
    baseUrl: `http://127.0.0.1:${port}`,
    close: async () => {
      await new Promise<void>((resolve, reject) =>
        srv.close((err) => (err ? reject(err) : resolve())),
      );
      rmSync(tmpDir, { recursive: true, force: true });
    },
  };
}

async function forwardIntegrityToFixture(
  page: import("@playwright/test").Page,
  fixtureBaseUrl: string,
): Promise<void> {
  await page.route(
    LEDGER_INTEGRITY_URL,
    async (route: Route, request: Request) => {
      const upstream = new URL(request.url());
      const forwarded = `${fixtureBaseUrl}/api/ledger/integrity${upstream.search}`;
      const res = await fetch(forwarded, {
        method: request.method(),
        headers: request.headers(),
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
    },
  );
}

test.describe("dashboard: ledger sidecar strict keyfile mode badge", () => {
  test("renders 'Strict keyfile mode: ON' with green styling when the API server boots with LEDGER_SIDECAR_SECRET_STRICT_MODE=1", async ({
    page,
  }) => {
    const fixture = await startFixture(true);
    try {
      await forwardIntegrityToFixture(page, fixture.baseUrl);
      await page.goto("/");

      const badge = page.locator(
        '[data-testid="badge-ledger-sidecar-strict-mode"]',
      );
      await expect(badge).toBeVisible();
      await expect(badge).toHaveAttribute("data-strict-mode", "on");
      await expect(badge).toContainText("Strict keyfile mode: ON");
      // Green styling — the class list flips to the green palette in
      // the ON posture (dashboard.tsx ~line 1925).
      await expect(badge).toHaveClass(/border-green-500\/50/);
      await expect(badge).toHaveClass(/text-green-700/);
    } finally {
      await fixture.close();
    }
  });

  test("renders 'Strict keyfile mode: OFF' with muted styling when LEDGER_SIDECAR_SECRET_STRICT_MODE is unset", async ({
    page,
  }) => {
    const fixture = await startFixture(false);
    try {
      await forwardIntegrityToFixture(page, fixture.baseUrl);
      await page.goto("/");

      const badge = page.locator(
        '[data-testid="badge-ledger-sidecar-strict-mode"]',
      );
      await expect(badge).toBeVisible();
      await expect(badge).toHaveAttribute("data-strict-mode", "off");
      await expect(badge).toContainText("Strict keyfile mode: OFF");
      // Muted styling in the OFF posture — distinct from the green
      // ON palette so an operator can tell at a glance.
      await expect(badge).toHaveClass(/border-muted-foreground\/40/);
      await expect(badge).toHaveClass(/text-muted-foreground/);
      await expect(badge).not.toHaveClass(/border-green-500\/50/);
    } finally {
      await fixture.close();
    }
  });
});
