import { Link } from "wouter";
import {
  ArrowLeft,
  AlertTriangle,
  Gauge,
  Sparkles,
  Telescope,
  ShieldCheck,
  FileText,
  Download,
} from "lucide-react";
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  ReferenceLine,
  ReferenceDot,
} from "recharts";
import { Card } from "@/components/ui/card";
import {
  ChartContainer,
  ChartTooltip,
  ChartTooltipContent,
  type ChartConfig,
} from "@/components/ui/chart";
import data from "@/data/desert-map.json";

const mono = "font-mono text-sm bg-muted px-1.5 py-0.5 border border-border";

const CERT_PDF_URL = `${import.meta.env.BASE_URL}pdfs/desert_map_summary.pdf`;
const CERT_PDF_SHA256 =
  "c9bc888b586f597b638a0ca4c1d1fb99d3878c450cd5777d5a2be9f0a79e98ce";

// Row flag classes requested for the data tables: P5 = bridge, P6-P20 = beyond-tolerance.
function rowClass(k: number): string {
  if (k === 5) return "bridge bg-primary/5";
  if (k >= 6) return "beyond-tolerance";
  return "";
}

type Regime = "Classical-Z" | "Bridge" | "Desert";

interface PrimeRow {
  k: number;
  digits: number;
  display: string;
  full: string;
  gap_from_prev: string;
  desert_width: string;
  desert_width_display: string;
  r: string;
  c_unwt_cum: string;
  c_wt_cum: string;
  regime: Regime;
  h4_axes_active: number;
  bdp: {
    q: number | null;
    m: number | null;
    k: string | null;
    error: string | null;
    error_ratio: string | null;
    tolerance_log10: string | null;
    status: "EXACT" | "VERIFIED" | "BEYOND_TOLERANCE";
  };
}

const meta = data.meta;
const primes = data.primes as PrimeRow[];
const invariants = data.classical_invariants as {
  axis: number;
  prime: number;
  value: string;
}[];

const REGIME_STYLE: Record<
  Regime,
  { label: string; chip: string; dot: string }
> = {
  "Classical-Z": {
    label: "Classical Z",
    chip: "border-green-500/50 bg-green-500/10 text-green-700 dark:text-green-400",
    dot: "bg-green-500",
  },
  Bridge: {
    label: "Bridge",
    chip: "border-primary/50 bg-primary/10 text-primary",
    dot: "bg-primary",
  },
  Desert: {
    label: "Desert",
    chip: "border-amber-500/50 bg-amber-500/10 text-amber-700 dark:text-amber-400",
    dot: "bg-amber-500",
  },
};

function StatusChip({ status }: { status: PrimeRow["bdp"]["status"] }) {
  const map = {
    EXACT: {
      text: "exact · 0",
      cls: "border-green-500/50 bg-green-500/10 text-green-700 dark:text-green-400",
    },
    VERIFIED: {
      text: "verified · < 1",
      cls: "border-primary/50 bg-primary/10 text-primary",
    },
    BEYOND_TOLERANCE: {
      text: "beyond tolerance",
      cls: "border-amber-500/50 bg-amber-500/10 text-amber-700 dark:text-amber-400",
    },
  }[status];
  return (
    <span
      className={`inline-block px-1.5 py-0.5 border font-mono text-[10px] uppercase tracking-wide ${map.cls}`}
    >
      {map.text}
    </span>
  );
}

// ---- chart data ----------------------------------------------------------
const cwtData = primes.map((p) => ({
  k: p.k,
  cwt: parseFloat(p.c_wt_cum),
  regime: p.regime,
}));

const toleranceData = primes
  .filter((p) => p.k >= 5)
  .map((p) => ({
    k: p.k,
    tol: p.bdp.tolerance_log10 ? parseFloat(p.bdp.tolerance_log10) : 0,
    status: p.bdp.status,
  }));

const axesData = primes.map((p) => ({ k: p.k, axes: p.h4_axes_active }));

const cwtConfig = {
  cwt: { label: "C_wt (cumulative)", color: "hsl(var(--primary))" },
} satisfies ChartConfig;
const tolConfig = {
  tol: { label: "log₁₀(κ-tolerance)", color: "hsl(var(--primary))" },
} satisfies ChartConfig;
const axesConfig = {
  axes: { label: "H4 axes active", color: "hsl(var(--primary))" },
} satisfies ChartConfig;

const PRIMARY = "hsl(var(--primary))";
const AXIS = "hsl(var(--muted-foreground))";

export default function DesertMapPage() {
  return (
    <div className="space-y-8">
      <Link
        href="/"
        className="inline-flex items-center text-xs font-mono text-muted-foreground hover:text-foreground transition-colors"
        data-testid="link-back-dashboard"
      >
        <ArrowLeft className="w-3 h-3 mr-2" /> BACK TO DASHBOARD
      </Link>

      <header className="border-b border-border pb-6">
        <div className="font-mono text-[10px] text-muted-foreground uppercase tracking-[0.18em] mb-2">
          Exceptional-prime desert map · α₀ = 299 + π/10
        </div>
        <h2 className="text-3xl font-bold font-sans tracking-tight mb-2">
          The Desert Map — P5 and the Edge of Verification
        </h2>
        <p className="text-sm font-mono text-muted-foreground max-w-3xl">
          TWENTY EXCEPTIONAL PRIMES TO 10⁴⁰⁰⁰ · FOUR CLASSICAL · ONE BRIDGE WE CAN
          STILL CHECK BY HAND · THEN A DESERT THAT KEEPS ITS SECRET
        </p>
      </header>

      <Card className="p-6 border-primary/50 bg-primary/5">
        <div className="font-mono text-[10px] text-primary uppercase tracking-[0.18em] mb-2">
          What this page is
        </div>
        <p className="font-serif text-base leading-relaxed">
          The exceptional primes for <span className={mono}>α₀ = 299 + π/10</span>{" "}
          are the primes <span className={mono}>p</span> with{" "}
          <span className={mono}>‖p·π/10‖ &lt; 1/p</span> — equivalently{" "}
          <span className={mono}>r = p·‖p·π/10‖ &lt; 1</span>. There are exactly{" "}
          <strong>20 of them below 10⁴⁰⁰⁰</strong>, and they split sharply: the
          first four — <span className={mono}>{"{2, 3, 19, 191}"}</span> — form a
          finite <em>classical</em> set, and then the fifth,{" "}
          <strong>P5 = 3,993,746,143,633</strong>, opens a desert of nearly four
          trillion consecutive non-exceptional integers. This page maps that
          structure honestly. It proves <strong>no new mathematics</strong>: the
          desert widths and energies are computed; the "bridge" is a numerical
          observation we can verify only where our arithmetic reaches; the
          12-curve reading is an interpretation, not a theorem.
        </p>
      </Card>

      {/* Certificate download ------------------------------------------- */}
      <Card className="p-5 border-primary/50 bg-card flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div className="flex items-start gap-3">
          <FileText className="w-5 h-5 text-primary mt-0.5 shrink-0" />
          <div>
            <div className="font-mono text-[10px] uppercase tracking-[0.18em] text-primary mb-1">
              Certificate
            </div>
            <div className="font-sans font-semibold text-base">
              Certificate: Exceptional-Prime Desert Map
            </div>
            <div className="font-mono text-[10px] text-muted-foreground mt-1 break-all">
              sha256 {CERT_PDF_SHA256}
            </div>
          </div>
        </div>
        <a
          href={CERT_PDF_URL}
          target="_blank"
          rel="noopener noreferrer"
          className="inline-flex items-center gap-2 px-3 py-2 border border-primary/50 bg-primary/10 text-primary font-mono text-xs uppercase tracking-wide hover:bg-primary/20 transition-colors shrink-0"
          data-testid="link-certificate-pdf"
        >
          <Download className="w-3.5 h-3.5" /> View PDF
        </a>
      </Card>

      {/* The two concepts, kept distinct -------------------------------- */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <Card className="p-5 border-border bg-card">
          <div className="flex items-center gap-2 font-mono text-[11px] uppercase tracking-[0.18em] text-primary mb-2 border-b border-border pb-2">
            <Gauge className="w-4 h-4" /> Error rate — a measurement
          </div>
          <p className="font-serif text-sm leading-relaxed text-foreground/90">
            The <strong>error rate</strong> is a number we actually compute: the
            gap <span className={mono}>|q·κ^m − p − k·π|</span> in the bridge
            relation. It is <strong>0 exactly</strong> for the four classical
            primes, and <strong>≈ 0.038 (&lt; 1)</strong> for P5. It is a
            measured quantity with a stated tolerance — and past P5 it stops being
            measurable at all.
          </p>
        </Card>
        <Card className="p-5 border-border bg-card">
          <div className="flex items-center gap-2 font-mono text-[11px] uppercase tracking-[0.18em] text-amber-700 dark:text-amber-400 mb-2 border-b border-border pb-2">
            <Sparkles className="w-4 h-4" /> Self-symmetry — an interpretation
          </div>
          <p className="font-serif text-sm leading-relaxed text-foreground/90">
            The <strong>self-symmetry</strong> is a structural <em>reading</em>,
            not a measurement: the picture of the classical set carrying the full{" "}
            <strong>12-fold H4 (600-cell) symmetry</strong>, collapsing to a
            single axis past the boundary. It is a way of seeing the data — a
            Coxeter interpretation — and we label it as such. It asserts no proof.
          </p>
        </Card>
      </div>

      {/* Three regimes --------------------------------------------------- */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Card className="p-5 border-green-500/40 bg-green-500/5">
          <div className="font-mono text-[10px] uppercase tracking-[0.18em] text-green-700 dark:text-green-400 mb-1">
            P1–P4 · Classical Z
          </div>
          <div className="font-sans font-bold text-lg mb-2">{"{2, 3, 19, 191}"}</div>
          <p className="font-serif text-sm leading-relaxed text-foreground/85">
            Finite and closed. <span className={mono}>C_unwt = {meta.c_unwt_s4}</span>{" "}
            &lt; {meta.bound_2sqrt13} (= 2√13). Error rate{" "}
            <strong>exactly 0</strong>. All 12 H4 axes active.
          </p>
        </Card>
        <Card className="p-5 border-primary/50 bg-primary/5">
          <div className="font-mono text-[10px] uppercase tracking-[0.18em] text-primary mb-1">
            P5 · The Bridge
          </div>
          <div className="font-sans font-bold text-lg mb-2">3,993,746,143,633</div>
          <p className="font-serif text-sm leading-relaxed text-foreground/85">
            The one giant we can still test by hand:{" "}
            <span className={mono}>191·κ¹⁶</span> lands{" "}
            <strong>≈ 0.038 (&lt; 1)</strong> from P5, mod π. Symmetry breaks 12 →
            1. Weighted energy jumps to {meta.c_wt_s5}.
          </p>
        </Card>
        <Card className="p-5 border-amber-500/40 bg-amber-500/5">
          <div className="font-mono text-[10px] uppercase tracking-[0.18em] text-amber-700 dark:text-amber-400 mb-1">
            P6–P20 · The Desert
          </div>
          <div className="font-sans font-bold text-lg mb-2">16 … 3,548 digits</div>
          <p className="font-serif text-sm leading-relaxed text-foreground/85">
            Beyond reach. Testing the bridge here needs κ to as many digits as the
            prime itself — thousands of digits of tolerance, beyond our machines.
            Marked <strong>indeterminate</strong>, not pass, not fail.
          </p>
        </Card>
      </div>

      {/* P5 centrepiece -------------------------------------------------- */}
      <Card className="p-6 border-primary/50 bg-card">
        <div className="font-mono text-[11px] text-primary uppercase tracking-[0.18em] mb-4 border-b border-border pb-2">
          The bridge at P5 — verified, with its tolerance
        </div>
        <div className="bg-muted/40 border-l-4 border-primary p-4 font-mono text-sm leading-relaxed overflow-x-auto">
          <div>q = 191 (∈ S₄) · m = 16 · k = {primes[4].bdp.k}</div>
          <div className="mt-2">
            | 191·κ¹⁶ − P5 − k·π |{" "}
            <span className="text-primary font-bold">= {primes[4].bdp.error}</span>{" "}
            <span className="text-muted-foreground">
              ± 0.029 (from κ at 15 digits)
            </span>{" "}
            <span className="text-primary">&lt; 1 ✓</span>
          </div>
          <div className="mt-1 text-muted-foreground">
            error_ratio = error / P5 = {primes[4].bdp.error_ratio} ·{" "}
            κ = {meta.kappa}
          </div>
        </div>
        <p className="font-serif text-sm leading-relaxed text-foreground/85 mt-4">
          This is the honest centrepiece. With κ known to 15 digits, the
          propagated uncertainty in <span className={mono}>191·κ¹⁶</span> is about{" "}
          <span className={mono}>±0.029</span> — comfortably smaller than 1 — so{" "}
          <strong>the bridge at P5 is genuinely verified</strong>. We do not claim
          the digit-level value <span className={mono}>0.038</span> beyond that
          tolerance; only that the inequality <span className={mono}>&lt; 1</span>{" "}
          holds robustly. Cross-references:{" "}
          <Link href="/certificates/M1" className="text-primary underline underline-offset-2">M1</Link>{" "}
          (the constant α₀),{" "}
          <Link href="/certificates/M3" className="text-primary underline underline-offset-2">M3</Link>{" "}
          (the CF obstruction),{" "}
          <Link href="/certificates/M4" className="text-primary underline underline-offset-2">M4</Link>{" "}
          (the exceptional set),{" "}
          <Link href="/certificates/M5" className="text-primary underline underline-offset-2">M5</Link>{" "}
          (the Bost bound).
        </p>
      </Card>

      {/* Charts ---------------------------------------------------------- */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card className="p-5 border-border bg-card">
          <div className="font-mono text-[11px] uppercase tracking-[0.18em] text-muted-foreground mb-1 border-b border-border pb-2">
            Chart 1 · Weighted energy C_wt (cumulative, log scale)
          </div>
          <p className="font-mono text-[10px] text-muted-foreground my-2">
            Jumps from {meta.c_wt_s4} (S₄) to {meta.c_wt_s5} at P5, up to{" "}
            {meta.c_wt_s20} — computed, flagged Open.
          </p>
          <ChartContainer config={cwtConfig} className="aspect-[16/10]">
            <LineChart data={cwtData} margin={{ left: 8, right: 12, top: 8, bottom: 8 }}>
              <CartesianGrid vertical={false} strokeDasharray="3 3" />
              <XAxis dataKey="k" tickLine={false} axisLine={false} fontSize={11} stroke={AXIS} label={{ value: "prime index k", position: "insideBottom", offset: -2, fontSize: 10, fill: AXIS }} />
              <YAxis scale="log" domain={["auto", "auto"]} tickLine={false} axisLine={false} fontSize={11} stroke={AXIS} width={48} />
              <ChartTooltip content={<ChartTooltipContent />} />
              <Line type="monotone" dataKey="cwt" stroke={PRIMARY} strokeWidth={2} dot={{ r: 2 }} />
              <ReferenceDot x={5} y={parseFloat(meta.c_wt_s5)} r={4} fill={PRIMARY} stroke="none" />
            </LineChart>
          </ChartContainer>
        </Card>

        <Card className="p-5 border-border bg-card">
          <div className="font-mono text-[11px] uppercase tracking-[0.18em] text-muted-foreground mb-1 border-b border-border pb-2">
            Chart 2 · Edge of verification (κ-tolerance, log₁₀)
          </div>
          <p className="font-mono text-[10px] text-muted-foreground my-2">
            P5 sits below the line (verifiable). Past it the tolerance needed
            explodes to 10³⁵³⁶ — beyond any machine.
          </p>
          <ChartContainer config={tolConfig} className="aspect-[16/10]">
            <LineChart data={toleranceData} margin={{ left: 8, right: 12, top: 8, bottom: 8 }}>
              <CartesianGrid vertical={false} strokeDasharray="3 3" />
              <XAxis dataKey="k" tickLine={false} axisLine={false} fontSize={11} stroke={AXIS} label={{ value: "prime index k", position: "insideBottom", offset: -2, fontSize: 10, fill: AXIS }} />
              <YAxis tickLine={false} axisLine={false} fontSize={11} stroke={AXIS} width={48} />
              <ChartTooltip content={<ChartTooltipContent />} />
              <ReferenceLine y={0} stroke="hsl(var(--primary))" strokeDasharray="4 4" label={{ value: "limit: error<1 verifiable", position: "insideTopLeft", fontSize: 9, fill: PRIMARY }} />
              <Line type="monotone" dataKey="tol" stroke={PRIMARY} strokeWidth={2} dot={{ r: 2 }} />
            </LineChart>
          </ChartContainer>
        </Card>
      </div>

      {/* H4 12-Curve Collapse ------------------------------------------- */}
      <Card className="p-6 border-border bg-card">
        <div className="font-mono text-[11px] uppercase tracking-[0.18em] text-amber-700 dark:text-amber-400 mb-4 border-b border-border pb-2 flex items-center gap-2">
          <Sparkles className="w-4 h-4" /> H4 12-Curve Collapse — self-symmetry (interpretation)
        </div>
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 items-center">
          <div>
            <div className="flex items-center justify-around mb-3">
              <Spokes n={12} label="P1–P4" sub="12 axes" active />
              <div className="font-mono text-2xl text-muted-foreground">→</div>
              <Spokes n={1} label="P5–P20" sub="1 axis" />
            </div>
            <p className="text-center font-serif text-sm text-foreground/80 italic">
              Only 4 primes satisfy all 12 H4 symmetries. P5 breaks to 1. The
              desert.
            </p>
          </div>
          <div>
            <p className="font-serif text-sm leading-relaxed text-foreground/90 mb-3">
              Read through the 600-cell, the classical set carries the four real
              invariants <span className={mono}>I_k = log p_k /(p_k − 1)</span>{" "}
              across its 12 Weyl axes (the other 8 are zero), summing to{" "}
              <span className={mono}>{meta.sum_classical_invariants}</span> — under
              the single bound {meta.bound_2sqrt13}. At P5 the picture collapses to
              one axis, and the single-axis share{" "}
              <span className={mono}>I₄·κ¹⁶ ≈ {meta.kappa_axis_p5}</span> already
              dwarfs the per-axis budget{" "}
              <span className={mono}>{meta.single_axis_bound}</span>.
            </p>
            <div className="grid grid-cols-2 gap-2">
              {invariants.map((iv) => (
                <div key={iv.axis} className="font-mono text-xs border border-border bg-muted/20 px-2 py-1">
                  I_{iv.axis} = {iv.value} <span className="text-muted-foreground">· p={iv.prime}</span>
                </div>
              ))}
            </div>
            <p className="font-mono text-[10px] text-amber-700 dark:text-amber-400 mt-3">
              12-curve model = H4 Coxeter interpretation. Numerical, not derived.
              No proof of H4 structure is claimed.
            </p>
          </div>
        </div>
        <div className="mt-6">
          <div className="font-mono text-[10px] uppercase tracking-[0.18em] text-muted-foreground mb-2">
            Chart 3 · H4 symmetry axes active
          </div>
          <ChartContainer config={axesConfig} className="aspect-[16/5]">
            <LineChart data={axesData} margin={{ left: 8, right: 12, top: 8, bottom: 8 }}>
              <CartesianGrid vertical={false} strokeDasharray="3 3" />
              <XAxis dataKey="k" tickLine={false} axisLine={false} fontSize={11} stroke={AXIS} />
              <YAxis domain={[0, 12]} ticks={[0, 1, 6, 12]} tickLine={false} axisLine={false} fontSize={11} stroke={AXIS} width={32} />
              <ChartTooltip content={<ChartTooltipContent />} />
              <Line type="stepAfter" dataKey="axes" stroke={PRIMARY} strokeWidth={2} dot={{ r: 2 }} />
            </LineChart>
          </ChartContainer>
        </div>
      </Card>

      {/* Table 1 — primes · widths · r · regime ------------------------- */}
      <Card className="p-0 border-border bg-card overflow-hidden">
        <div className="p-4 border-b border-border font-mono text-[11px] uppercase tracking-[0.18em] text-muted-foreground">
          Table 1 · the twenty exceptional primes — Dₖ · pₖ · wₖ · rₖ · regime
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-sm" data-testid="table-primes-1">
            <thead>
              <tr className="border-b border-border text-[10px] font-mono uppercase tracking-wide text-muted-foreground">
                <th className="text-left p-3">k</th>
                <th className="text-right p-3">Dₖ</th>
                <th className="text-left p-3">pₖ (head…tail)</th>
                <th className="text-right p-3">wₖ (desert width)</th>
                <th className="text-right p-3">rₖ</th>
                <th className="text-left p-3">Regime</th>
              </tr>
            </thead>
            <tbody className="font-mono text-xs">
              {primes.map((p) => {
                const rs = REGIME_STYLE[p.regime];
                return (
                  <tr
                    key={p.k}
                    className={`border-b border-border/60 ${rowClass(p.k)}`}
                    data-testid={`row-t1-prime-${p.k}`}
                  >
                    <td className="p-3 text-muted-foreground">P{p.k}</td>
                    <td className="p-3 text-right text-muted-foreground">{p.digits}</td>
                    <td className="p-3 text-foreground">{p.display}</td>
                    <td className="p-3 text-right text-muted-foreground">
                      {p.k === 1 ? "—" : p.desert_width_display}
                    </td>
                    <td className="p-3 text-right text-foreground">{p.r}</td>
                    <td className="p-3">
                      <span className={`inline-flex items-center gap-1.5 px-1.5 py-0.5 border text-[10px] uppercase tracking-wide ${rs.chip}`}>
                        <span className={`w-1.5 h-1.5 ${rs.dot}`} />
                        {rs.label}
                      </span>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </Card>

      {/* Table 2 — weighted energy & bridge status ---------------------- */}
      <Card className="p-0 border-border bg-card overflow-hidden">
        <div className="p-4 border-b border-border font-mono text-[11px] uppercase tracking-[0.18em] text-muted-foreground">
          Table 2 · weighted energy &amp; bridge status — Cwt · H4 · BDP_status · error · log₁₀τ
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-sm" data-testid="table-primes-2">
            <thead>
              <tr className="border-b border-border text-[10px] font-mono uppercase tracking-wide text-muted-foreground">
                <th className="text-left p-3">k</th>
                <th className="text-right p-3">Cwt (cum.)</th>
                <th className="text-right p-3">H4</th>
                <th className="text-left p-3">BDP_status</th>
                <th className="text-right p-3">error</th>
                <th className="text-right p-3">log₁₀τ</th>
              </tr>
            </thead>
            <tbody className="font-mono text-xs">
              {primes.map((p) => (
                <tr
                  key={p.k}
                  className={`border-b border-border/60 ${rowClass(p.k)}`}
                  data-testid={`row-t2-prime-${p.k}`}
                >
                  <td className="p-3 text-muted-foreground">P{p.k}</td>
                  <td className="p-3 text-right text-foreground">{p.c_wt_cum}</td>
                  <td className="p-3 text-right text-muted-foreground">{p.h4_axes_active}</td>
                  <td className="p-3">
                    <StatusChip status={p.bdp.status} />
                  </td>
                  <td className="p-3 text-right text-muted-foreground">
                    {p.bdp.error !== null ? (
                      p.bdp.error
                    ) : (
                      <span className="italic">indeterminate</span>
                    )}
                  </td>
                  <td className="p-3 text-right text-muted-foreground">
                    {p.bdp.tolerance_log10 !== null ? p.bdp.tolerance_log10 : "—"}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Card>

      {/* The mystery ending --------------------------------------------- */}
      <Card className="p-6 border-amber-500/50 bg-amber-500/5">
        <div className="flex items-center gap-2 font-mono text-[11px] uppercase tracking-[0.18em] text-amber-700 dark:text-amber-400 mb-3 border-b border-amber-500/30 pb-2">
          <Telescope className="w-4 h-4" /> Where the map ends
        </div>
        <div className="space-y-3 font-serif text-base leading-relaxed text-foreground/90">
          <p>
            Past P5 the desert is silent. To hear whether the bridge still holds
            out there, we would need to know κ to as many digits as the prime
            itself — thousands of digits of tolerance, on machines whose precision
            would have to run far beyond ours. We do not have that, and we will
            not pretend to.
          </p>
          <p>
            So we stop at the honest edge.{" "}
            <strong>We do not claim the bridge holds for P6–P20; we do not claim
            it fails.</strong>{" "}
            What we can verify, we have verified — the four classical primes
            exactly, and P5 to a stated tolerance. The rest stays where it
            belongs: an open horizon, beyond the reach of this instrument. The map
            ends, deliberately, in a mystery.
          </p>
        </div>
      </Card>

      {/* Honesty box ----------------------------------------------------- */}
      <Card className="p-6 border-border bg-card">
        <div className="flex items-center gap-2 font-mono text-[11px] uppercase tracking-[0.18em] text-muted-foreground mb-3 border-b border-border pb-2">
          <AlertTriangle className="w-4 h-4" /> Honesty box — scope limits
        </div>
        <ul className="space-y-2 font-serif text-sm leading-relaxed text-foreground/85 list-disc list-inside">
          <li>
            The rule is exactly <span className={mono}>r = p·‖p·π/10‖ &lt; 1</span>.
            The 20 primes were re-certified against π to 9,000 digits; primality
            is <strong>BPSW</strong>, not a formal certificate for the 1000+ digit
            entries.
          </li>
          <li>
            <strong>Error rate</strong> (the bridge defect) is a measurement:{" "}
            <span className={mono}>0</span> for P1–P4, <span className={mono}>&lt; 1</span>{" "}
            for P5 (±0.029 from a 15-digit κ), and{" "}
            <strong>not computable</strong> for P6–P20. "Beyond tolerance" means
            indeterminate — never a pass.
          </li>
          <li>
            <strong>Self-symmetry</strong> (the H4 12→1 reading) is an
            interpretation, numerical and not derived. No proof of H4 structure,
            no RH, no Colmez/Bost theorem is asserted here.
          </li>
          <li>
            <span className={mono}>C_wt</span> is a computed quantity flagged{" "}
            <strong>Open</strong>. The certified data file{" "}
            <span className={mono}>data/desert_map.csv</span> is unchanged
            (sha256 {meta.certified_csv_sha256.slice(0, 12)}…); this page reads a
            separate derived layer.
          </li>
        </ul>
        <div className="flex items-center gap-2 mt-4 font-mono text-[10px] text-green-700 dark:text-green-400">
          <ShieldCheck className="w-3.5 h-3.5" /> computed &amp; verifiable data only · no new mathematics claimed
        </div>
      </Card>

      <div className="text-[10px] font-mono text-muted-foreground text-center pt-2">
        Entangled Technologies · exceptional-prime desert map · κ = {meta.kappa} (15 digits)
      </div>
    </div>
  );
}

function Spokes({
  n,
  label,
  sub,
  active = false,
}: {
  n: number;
  label: string;
  sub: string;
  active?: boolean;
}) {
  const size = 110;
  const c = size / 2;
  const rad = size / 2 - 8;
  const color = active ? "hsl(var(--primary))" : "hsl(var(--muted-foreground))";
  return (
    <div className="flex flex-col items-center gap-1">
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
        <circle cx={c} cy={c} r={rad} fill="none" stroke="hsl(var(--border))" strokeWidth={1} />
        {Array.from({ length: n }).map((_, i) => {
          const ang = (i / n) * 2 * Math.PI - Math.PI / 2;
          return (
            <line
              key={i}
              x1={c}
              y1={c}
              x2={c + rad * Math.cos(ang)}
              y2={c + rad * Math.sin(ang)}
              stroke={color}
              strokeWidth={n === 1 ? 3 : 1.5}
            />
          );
        })}
        <circle cx={c} cy={c} r={3} fill={color} />
      </svg>
      <div className="font-mono text-[10px] text-foreground">{label}</div>
      <div className="font-mono text-[10px] text-muted-foreground">{sub}</div>
    </div>
  );
}
