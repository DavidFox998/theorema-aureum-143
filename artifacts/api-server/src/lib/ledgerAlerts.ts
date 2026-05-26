import { spawn } from "node:child_process";
import type { Logger } from "pino";

export type LedgerAlertKind = "alert" | "recovered";

export interface LedgerAlertContext {
  failure_mode: string | null;
  expected_size?: number | null;
  expected_sha?: string | null;
  actual_size?: number | null;
  actual_sha?: string | null;
  checked_at: string;
  source: string;
  previous_failure_mode?: string | null;
  hits_path?: string;
  checkpoint_path?: string;
  [k: string]: unknown;
}

export interface LedgerAlertInvocation {
  kind: LedgerAlertKind;
  message: string;
  context: LedgerAlertContext;
}

export type LedgerAlertSink = (
  invocation: LedgerAlertInvocation,
) => void | Promise<void>;

export interface KernelAlertSinkOptions {
  repoRoot: string;
  logger?: Pick<Logger, "warn" | "info">;
  pythonBin?: string;
  spawnTimeoutMs?: number;
}

/**
 * Default ledger alert sink: shell out to `kernel._fire_ledger_alert` so the
 * server-side monitor reuses the EXACT same transport code, payload shape,
 * env-var configuration and on-disk ring-buffer history as the Python-side
 * `_append_line` integrity guard. Per task #85: "same path
 * kernel._fire_ledger_alert already uses for the Python side".
 *
 * The python invocation is fire-and-forget from the caller's perspective
 * (the returned promise resolves once the python process exits, but we
 * never throw — failures are logged and swallowed so a flaky on-call sink
 * cannot stall the periodic monitor).
 */
export function createKernelAlertSink(
  opts: KernelAlertSinkOptions,
): LedgerAlertSink {
  const pythonBin = opts.pythonBin ?? "python3";
  const timeoutMs = opts.spawnTimeoutMs ?? 30_000;
  // The python program reads {message, context} as JSON from stdin and
  // forwards to kernel._fire_ledger_alert, then drains the daemon
  // dispatch thread so webhook/SMTP delivery + history-write actually
  // complete before the subprocess exits.
  const program = [
    "import json, sys",
    `sys.path.insert(0, ${JSON.stringify(opts.repoRoot)})`,
    "import kernel",
    "data = json.load(sys.stdin)",
    "kernel._fire_ledger_alert(data['message'], data['context'])",
    "kernel._await_alert_dispatch(15.0)",
  ].join("\n");

  return (invocation) =>
    new Promise<void>((resolve) => {
      let settled = false;
      const done = () => {
        if (settled) return;
        settled = true;
        resolve();
      };
      try {
        const child = spawn(pythonBin, ["-c", program], {
          stdio: ["pipe", "ignore", "pipe"],
        });
        const killTimer = setTimeout(() => {
          opts.logger?.warn(
            { timeoutMs, kind: invocation.kind },
            "ledger alert: python sink timed out, killing",
          );
          try {
            child.kill("SIGKILL");
          } catch {
            /* ignore */
          }
          done();
        }, timeoutMs);
        killTimer.unref?.();
        let stderr = "";
        child.stderr.on("data", (chunk: Buffer) => {
          stderr += chunk.toString("utf-8");
          if (stderr.length > 4096) {
            stderr = stderr.slice(-4096);
          }
        });
        child.on("error", (err) => {
          clearTimeout(killTimer);
          opts.logger?.warn(
            { err, kind: invocation.kind },
            "ledger alert: python sink spawn failed",
          );
          done();
        });
        child.on("exit", (code) => {
          clearTimeout(killTimer);
          if (code !== 0) {
            opts.logger?.warn(
              { code, stderr, kind: invocation.kind },
              "ledger alert: python sink exited non-zero",
            );
          } else {
            opts.logger?.info(
              { kind: invocation.kind },
              "ledger alert: dispatched via kernel._fire_ledger_alert",
            );
          }
          done();
        });
        child.stdin.end(
          JSON.stringify({
            message: invocation.message,
            context: invocation.context,
          }),
        );
      } catch (err) {
        opts.logger?.warn(
          { err, kind: invocation.kind },
          "ledger alert: unexpected sink error",
        );
        done();
      }
    });
}
