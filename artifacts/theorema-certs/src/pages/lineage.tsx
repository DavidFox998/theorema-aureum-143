import { Link } from "wouter";
import { ArrowLeft, AlertTriangle, BookOpen } from "lucide-react";
import { Card } from "@/components/ui/card";

const mono = "font-mono text-sm bg-muted px-1.5 py-0.5 border border-border";

const TRIO = "{propext, Classical.choice, Quot.sound}";

function Section({
  index,
  title,
  children,
}: {
  index: string;
  title: string;
  children: React.ReactNode;
}) {
  return (
    <Card className="p-6 border-border bg-card">
      <div className="flex items-baseline gap-3 mb-4 border-b border-border pb-3">
        <div className="font-mono text-xs text-primary uppercase tracking-[0.18em]">
          {index}
        </div>
        <h3 className="font-sans font-bold text-lg tracking-tight">{title}</h3>
      </div>
      <div className="space-y-4 font-serif text-base leading-relaxed text-foreground/90">
        {children}
      </div>
    </Card>
  );
}

function Person({
  name,
  years,
  contribution,
  children,
}: {
  name: string;
  years: string;
  contribution: string;
  children: React.ReactNode;
}) {
  return (
    <div
      className="border-l-4 border-primary/60 pl-4 py-1"
      data-testid={`person-${name.toLowerCase().replace(/[^a-z]+/g, "-")}`}
    >
      <div className="flex items-baseline gap-2 flex-wrap mb-1">
        <span className="font-sans font-bold text-base text-foreground">
          {name}
        </span>
        <span className="font-mono text-[11px] text-muted-foreground">
          {years}
        </span>
        <span className="font-mono text-[10px] uppercase tracking-wider text-primary">
          · {contribution}
        </span>
      </div>
      <div className="font-serif text-base leading-relaxed text-foreground/90 space-y-2">
        {children}
      </div>
    </div>
  );
}

export default function LineagePage() {
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
          Tribute &amp; methodology · the people behind the inequality
        </div>
        <h2 className="text-3xl font-bold font-sans tracking-tight mb-2">
          Lineage &amp; Method
        </h2>
        <p className="text-sm font-mono text-muted-foreground">
          THE MATHEMATICIANS WHOSE SCIENCE WE STAND ON — AND HOW OUR ROUTE
          DIFFERS FROM THE STANDARD ONE
        </p>
      </header>

      <Card className="p-6 border-primary/50 bg-primary/5">
        <div className="font-mono text-[10px] text-primary uppercase tracking-[0.18em] mb-2">
          What this page is
        </div>
        <p className="font-serif text-base leading-relaxed">
          Not a single line of this work is original soil. It grows out of a
          century of harmonic analysis, representation theory, and constructive
          quantum field theory built by people who are mostly gone now. This page
          is a plain-language tribute to them — who they were, what they proved,
          and why each piece is load-bearing for the one inequality we reached —
          followed by an honest account of how <strong>our</strong> method
          differs from the standard fifty-year route, and exactly how the
          one-plaquette bound <span className={mono}>‖g − 1‖² ≥ 0</span> turns
          into <span className={mono}>0 &lt; wilsonAction U</span>. The honesty
          box at the foot states, in the same words as our internal invariants,
          what this does and does <strong>not</strong> mean.
        </p>
      </Card>

      <Section index="§ 1" title="The lineage — a roll of honor">
        <p className="text-foreground/80">
          Each name below is a tool we used directly. We name them so the science
          is not forgotten, and so a reader can trace every step back to its
          origin.
        </p>

        <Person
          name="Alfréd Haar"
          years="1885–1933"
          contribution="The invariant measure"
        >
          <p>
            Haar gave us the right way to average on a group. On the real line we
            measure a set by its length, and length is unchanged when we slide
            the set sideways. Haar's 1933 theorem says every locally compact
            group carries an analogous measure that is unchanged when we{" "}
            <em>multiply</em> by a fixed group element — and on a compact group
            like <span className={mono}>SU(3)</span> it is finite, so we can
            normalize it to a probability measure with{" "}
            <span className={mono}>∫ 1 dμ = 1</span>. He died the year he
            published it, at 48. Without his measure there is no fair average
            over gauge configurations, and nothing downstream even has a place to
            live.
          </p>
        </Person>

        <Person
          name="Fritz Peter & Hermann Weyl"
          years="1899–1949 · 1885–1955"
          contribution="The decomposition"
        >
          <p>
            Where Haar tells you <em>how</em> to average, Peter and Weyl (1927)
            tell you <em>why the average breaks into clean pieces</em>. Their
            theorem is the exact generalization of the Fourier series from the
            circle to any compact group: the matrix coefficients of the
            irreducible unitary representations form an orthogonal basis of{" "}
            <span className={mono}>L²(G)</span>, which splits as a direct sum{" "}
            <span className={mono}>⊕_λ (V_λ ⊗ V_λ*)</span> — one block per
            irreducible <span className={mono}>λ</span>. For{" "}
            <span className={mono}>SU(3)</span> the blocks are indexed by a pair
            of integers (highest weights), with a dimension and a Casimir for
            each. Weyl, one of the last universalists, also gave us the
            integration formula and the dimension formula that make those blocks
            computable.
          </p>
        </Person>

        <Person
          name="Oskar Perron & Georg Frobenius"
          years="1880–1975 · 1849–1917"
          contribution="The leading eigenvalue"
        >
          <p>
            Perron (1907) and Frobenius (1912) proved that a matrix with positive
            entries has a real, simple, largest eigenvalue whose eigenvector is
            strictly positive — the spectral fact behind every transfer-matrix
            argument in statistical mechanics. The "scalar shadow" we work with
            downstream is precisely the Perron sector: the top, sign-definite
            piece of the operator. Their theorem is why isolating that one piece
            is even a meaningful thing to do.
          </p>
        </Person>

        <Person
          name="Roman Kotecký & David Preiss"
          years="contemporary"
          contribution="Cluster convergence"
        >
          <p>
            The Kotecký–Preiss criterion (1986) is the clean, checkable condition
            under which a polymer / cluster expansion converges — the standard
            engine for proving a mass gap at strong coupling. We name it here
            with deliberate honesty: in our development the{" "}
            <span className={mono}>kotecky_preiss_criterion</span> is an{" "}
            <strong>open</strong> <span className={mono}>sorry</span>. It marks
            the road we did <em>not</em> complete, the one the standard programme
            walks. Their work defines the bar; we have not cleared it.
          </p>
        </Person>

        <Person
          name="Konrad Osterwalder, Robert Schrader & Kenneth Wilson"
          years="OS 1973–75 · Wilson 1974"
          contribution="The QFT toolkit"
        >
          <p>
            Wilson gave the lattice gauge action — the plaquette sum whose
            positivity is the very inequality this site is about — as the
            non-perturbative definition of the theory. Osterwalder and Schrader
            gave the reflection-positivity axioms that let a Euclidean lattice
            theory be reconstructed as a genuine quantum theory with a positive
            self-adjoint transfer operator. Together with the Sobolev-space
            analysis behind the continuum limit, this is the frame inside which
            "mass gap" is even a well-posed question. We use Wilson's action
            honestly and leave the full OS reconstruction where it stands —
            open.
          </p>
        </Person>
      </Section>

      <Section index="§ 2" title="How our method differs from the standard route">
        <p>
          For roughly fifty years the canonical attack on the mass gap has been:
          control the full infinite-dimensional Wilson transfer operator on{" "}
          <span className={mono}>L²(∏ SU(3), Haar)</span>, prove a spectral gap
          directly (typically via a convergent cluster expansion à la
          Kotecký–Preiss at strong coupling), and pass to the continuum. Our
          route is deliberately different — and it is important to be exact about
          how, because the difference is also the source of the limitation.
        </p>
        <div className="grid gap-3 md:grid-cols-2">
          <div className="border border-border bg-muted/20 p-4">
            <div className="font-mono text-[10px] uppercase tracking-wider text-primary mb-1">
              Operator
            </div>
            <p className="font-serif text-sm leading-relaxed">
              <strong>Standard:</strong> the full Wilson transfer Hamiltonian, an
              operator on an infinite-dimensional Hilbert space.
              <br />
              <strong>Ours:</strong> the scalar / Perron-sector{" "}
              <em>shadow</em> <span className={mono}>H = wilsonAction U · 𝟙</span>{" "}
              — a single sign-definite number times the identity.
            </p>
          </div>
          <div className="border border-border bg-muted/20 p-4">
            <div className="font-mono text-[10px] uppercase tracking-wider text-primary mb-1">
              Direction
            </div>
            <p className="font-serif text-sm leading-relaxed">
              <strong>Standard:</strong> build the gap first, derive positivity
              as a consequence.
              <br />
              <strong>Ours:</strong> nail down strict <em>positivity</em> of the
              action off the vacuum first, and read the shadow's gap off that.
            </p>
          </div>
          <div className="border border-border bg-muted/20 p-4">
            <div className="font-mono text-[10px] uppercase tracking-wider text-primary mb-1">
              Space
            </div>
            <p className="font-serif text-sm leading-relaxed">
              <strong>Standard:</strong> the infinite lattice{" "}
              <span className={mono}>ℤ⁴</span> and its thermodynamic limit.
              <br />
              <strong>Ours:</strong> a finite configuration{" "}
              <span className={mono}>Fin (4·L⁴)</span>, fully formal and
              machine-checked, no limit taken.
            </p>
          </div>
          <div className="border border-border bg-muted/20 p-4">
            <div className="font-mono text-[10px] uppercase tracking-wider text-primary mb-1">
              Mindset
            </div>
            <p className="font-serif text-sm leading-relaxed">
              <strong>Standard:</strong> estimate the hard object directly,
              accepting analytic difficulty.
              <br />
              <strong>Ours:</strong> "solve the shadow" — extract the
              sign-definite Perron piece, prove it cleanly and completely, and be
              explicit that it is a shadow.
            </p>
          </div>
        </div>
      </Section>

      <Section index="§ 3" title="How the one inequality was reached">
        <p>
          The whole positivity result rests on one elementary fact about unitary
          matrices, run forward carefully. For a unitary{" "}
          <span className={mono}>3×3</span> matrix <span className={mono}>g</span>{" "}
          the Hilbert–Schmidt norm satisfies{" "}
          <span className={mono}>‖g − 1‖² = 6 − 2·Re tr g</span>. The chain is:
        </p>
        <p className="border-l-4 border-primary pl-4 bg-muted/30 py-2 font-mono text-sm leading-relaxed">
          ‖g − 1‖² ≥ 0
          <span className="text-muted-foreground"> ⟹ </span>
          <span className="text-primary">Re tr g ≤ 3</span>
          <span className="text-muted-foreground"> ; equality ⟺ </span>
          <span className="text-primary">g = 1</span>
          <span className="text-muted-foreground"> (since ‖M‖² = 0 ⟺ M = 0)</span>
          <br />
          <span className="text-muted-foreground"> ⟹ </span>
          plaquetteEnergy P = (3 − Re tr P)/3 ≥ 0, &gt; 0 iff P ≠ 1
          <br />
          <span className="text-muted-foreground"> ⟹ </span>
          <span className="text-primary">0 &lt; wilsonAction U</span>
          <span className="text-muted-foreground">
            {" "}
            (Finset.sum_pos′ — a sum of non-negatives with one strict term)
          </span>
        </p>
        <p>
          Each arrow is fully formal and <span className={mono}>sorry</span>-free.
          The first arrow is just non-negativity of a squared norm; the equality
          case is <span className={mono}>‖M‖² = 0 ⇔ M = 0</span>; the last arrow
          is mathlib's <span className={mono}>Finset.sum_pos′</span>, which turns
          "every plaquette ≥ 0 and at least one &gt; 0" into a strictly positive
          total action.
        </p>
        <p className="font-serif text-base leading-relaxed border-l-4 border-primary/60 pl-4 italic text-foreground/90">
          Haar is how you average, Peter–Weyl is why the average breaks into
          pieces, and the inequality is the size of the first piece.
        </p>
        <p>
          That sentence is the whole tribute in one line: the measure
          (Haar), the decomposition (Peter–Weyl), and the leading positive term
          (the inequality, sitting in the Perron sector by Perron–Frobenius) are
          the three classical facts our one new step leans on.
        </p>
      </Section>

      <Section index="§ 4" title="What it does — and does not — mean">
        <p>
          What is genuinely, permanently true: the one-plaquette inequality and
          the strict positivity of the Wilson action off the vacuum are real,
          elementary, machine-checked, <span className={mono}>sorry</span>-free
          results carrying only the classical-trio axioms{" "}
          <span className={mono}>{TRIO}</span>. That brick is closed.
        </p>
        <p>
          What is <strong>conditional</strong>, and must be read as conditional:
          the picture in which this "reduces the Millennium Problem" depends on
          the scalar shadow <span className={mono}>H = wilsonAction U · 𝟙</span>{" "}
          standing in for the real Wilson transfer operator. It does not. So the
          framing "one inequality away from the mass gap" is a{" "}
          <strong>hypothesis about a route</strong>, not an achieved result. The
          honest reading: we closed the shadow's inequality completely, and we
          are explicit that closing the shadow is not closing the theory.
        </p>
      </Section>

      <Card className="p-6 border-amber-500/60 bg-amber-500/5">
        <div className="flex items-center gap-2 font-mono text-[11px] text-amber-700 dark:text-amber-400 uppercase tracking-[0.18em] mb-3 border-b border-amber-500/30 pb-2">
          <AlertTriangle className="w-4 h-4" />
          Honesty box — scope limits (do not over-read)
        </div>
        <div className="space-y-3 font-serif text-base leading-relaxed text-foreground/90">
          <p>
            The tribute and the inequality chain above are real. Everything in
            this box is what they are <strong>not</strong>, stated in the same
            words as our internal locked invariants.
          </p>
          <p>
            The operator used downstream is the{" "}
            <strong>scalar / Perron-sector shadow</strong>{" "}
            <span className={mono}>H = wilsonAction U · 𝟙</span>, which is{" "}
            <strong>not</strong> the real Wilson transfer Hamiltonian on{" "}
            <span className={mono}>L²(∏ SU(3), Haar)</span>. The positivity above
            is scalar-sector action positivity only.
          </p>
          <p>
            <strong>Surface #1 stays OPEN.</strong> The mass-gap target file{" "}
            <span className={mono}>MassGap574.lean</span> still carries a{" "}
            <span className={mono}>sorry</span>; the{" "}
            <span className={mono}>kotecky_preiss_criterion</span> remains an open{" "}
            <span className={mono}>sorry</span>; the YM tower's status remains{" "}
            <span className={mono}>Open</span>. There is{" "}
            <strong>no μ &gt; 0 claim</strong>, and this is <strong>not</strong>{" "}
            the Clay Yang–Mills solution. These are honored foundations and an
            honestly-bounded new step — nothing more.
          </p>
        </div>
      </Card>

      <Card className="p-6 border-border bg-card">
        <div className="flex items-center gap-2 font-mono text-[11px] text-muted-foreground uppercase tracking-[0.18em] mb-2 border-b border-border pb-2">
          <BookOpen className="w-4 h-4" />
          See the verified sources
        </div>
        <p className="font-serif text-sm leading-relaxed text-foreground/80">
          The actual machine-checked Lean files behind Haar, Peter–Weyl, and the
          Wilson-action positivity — each <span className={mono}>sorry</span>-free
          with axiom footprint <span className={mono}>{TRIO}</span> — are
          available to read and download on the{" "}
          <Link
            href="/foundations"
            className="text-primary underline underline-offset-2 hover:opacity-80"
            data-testid="link-foundations-cross"
          >
            Foundations page
          </Link>
          .
        </p>
      </Card>

      <div className="text-[10px] font-mono text-muted-foreground text-center pt-2">
        Entangled Technologies · in tribute · the science is not forgotten
      </div>
    </div>
  );
}
