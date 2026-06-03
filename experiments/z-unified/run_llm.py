#!/usr/bin/env python3
"""
Method A [T=0] — genuine LLM direct-generation across the 3 Z modules.

HONEST: real LLM calls via the Replit AI Integrations Anthropic proxy (billed to
credits). temperature=0. Failed/unparsed replies are recorded as errors, never
back-filled or fabricated.

RESUMABLE: persists to Z_UNIFIED_llm_progress.json and runs only until an
internal wall-clock BUDGET (default 100s) so each invocation stays under the
shell time cap. Re-run until it prints "ALL DONE".

Env: BESSEL is irrelevant here. Z_TRIALS (default 100), Z_WORKERS (default 30),
Z_BUDGET (default 100), Z_MODEL (default claude-haiku-4-5).
"""
import os, json, re, time, urllib.request, urllib.error
from concurrent.futures import ThreadPoolExecutor, as_completed

HERE = os.path.dirname(os.path.abspath(__file__))
TRIALS = int(os.environ.get("Z_TRIALS", "100"))
WORKERS = int(os.environ.get("Z_WORKERS", "30"))
BUDGET = float(os.environ.get("Z_BUDGET", "100"))
MODEL = os.environ.get("Z_MODEL", "claude-haiku-4-5")

BASE = os.environ["AI_INTEGRATIONS_ANTHROPIC_BASE_URL"].rstrip("/")
KEY = os.environ["AI_INTEGRATIONS_ANTHROPIC_API_KEY"]
URL = BASE + "/v1/messages"
PROGRESS = os.path.join(HERE, "Z_UNIFIED_llm_progress.json")
NUM_RE = re.compile(r"[-+]?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?")

PROMPTS = {
    "COMM": lambda c: (
        f"A binary symmetric channel has crossover probability p={c['p']}. "
        "Compute its Shannon capacity C = 1 - H2(p) in bits, where "
        "H2(p) = -p*log2(p) - (1-p)*log2(1-p). Do NOT use any tool, code, or "
        "step-by-step scratch work. Reply with ONLY the decimal value."),
    "POLY": lambda c: (
        "Convert this binary string to a base-10 integer (most significant bit "
        f"on the left): {c['bits']}. Do NOT use any tool, code, or step-by-step "
        "scratch work. Reply with ONLY the integer."),
    "BC": lambda c: (
        f"Compute the Riemann zeta function value zeta(s) for s={c['beta_KMS']}. "
        "Do NOT use any tool, code, or step-by-step scratch work. Reply with "
        "ONLY the decimal value to as many digits as you can."),
}
FILES = {"COMM": "COMM_TEST_SET.json", "POLY": "POLYMER_TEST_SET.json",
         "BC": "BOSTCONNES_TEST_SET.json"}


def call_once(prompt):
    body = json.dumps({"model": MODEL, "max_tokens": 8192, "temperature": 0,
                       "messages": [{"role": "user", "content": prompt}]}).encode()
    req = urllib.request.Request(URL, data=body, method="POST", headers={
        "x-api-key": KEY, "anthropic-version": "2023-06-01",
        "content-type": "application/json"})
    for attempt in range(4):
        try:
            with urllib.request.urlopen(req, timeout=90) as r:
                data = json.load(r)
            text = "".join(p.get("text", "") for p in data.get("content", [])
                           if p.get("type") == "text").strip()
            m = NUM_RE.search(text.replace(",", ""))
            val = float(m.group(0)) if m else None
            return {"raw": text, "value": val, "ok": val is not None}
        except urllib.error.HTTPError as e:
            if e.code == 429 and attempt < 3:
                time.sleep(2 ** attempt); continue
            return {"raw": f"HTTPError {e.code}", "value": None, "ok": False}
        except Exception as e:  # noqa: BLE001
            if attempt < 3:
                time.sleep(2 ** attempt); continue
            return {"raw": f"ERR {type(e).__name__}", "value": None, "ok": False}
    return {"raw": "exhausted", "value": None, "ok": False}


def main():
    cases = {}
    for mod, fn in FILES.items():
        with open(os.path.join(HERE, fn)) as f:
            cases[mod] = {c["id"]: c for c in json.load(f)}
    progress = {}
    if os.path.exists(PROGRESS):
        with open(PROGRESS) as f:
            progress = json.load(f)

    jobs = []  # (mod, id, trial)
    for mod in FILES:
        for cid in cases[mod]:
            for t in range(TRIALS):
                key = f"{mod}#{cid}#{t}"
                if key not in progress:
                    jobs.append((mod, cid, t, key))
    total = sum(len(cases[m]) for m in FILES) * TRIALS
    if not jobs:
        print(f"ALL DONE: {total}/{total} trials already complete.")
        return

    def run(job):
        mod, cid, t, key = job
        return key, call_once(PROMPTS[mod](cases[mod][cid]))

    def save():
        with open(PROGRESS, "w") as f:
            json.dump(progress, f)

    start = time.monotonic()
    done = 0
    with ThreadPoolExecutor(max_workers=WORKERS) as ex:
        fut2 = {ex.submit(run, j): j for j in jobs}
        for fut in as_completed(fut2):
            key, res = fut.result()
            progress[key] = res
            done += 1
            if done % 25 == 0:
                save()
                print(f"  +{done} this run ({len(progress)}/{total} total)", flush=True)
            if time.monotonic() - start > BUDGET:
                for f in fut2:
                    if not f.done():
                        f.cancel()
                break
    save()
    remaining = total - len(progress)
    if remaining <= 0:
        print(f"ALL DONE: {len(progress)}/{total} trials complete.")
    else:
        print(f"PARTIAL: {len(progress)}/{total} done, {remaining} remaining "
              f"(+{done} this run). Re-run to continue.")


if __name__ == "__main__":
    main()
