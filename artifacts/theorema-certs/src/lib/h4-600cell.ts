export const PHI = (1 + Math.sqrt(5)) / 2;
export const INV_PHI = 1 / PHI;
export const H = 30;
export const EXPONENTS = [1, 11, 19, 29] as const;

export type Vec4 = readonly [number, number, number, number];

function permutations<T>(arr: T[]): T[][] {
  if (arr.length <= 1) return [arr];
  const out: T[][] = [];
  for (let i = 0; i < arr.length; i++) {
    const rest = [...arr.slice(0, i), ...arr.slice(i + 1)];
    for (const p of permutations(rest)) out.push([arr[i], ...p]);
  }
  return out;
}

function parity(perm: number[]): 0 | 1 {
  let inv = 0;
  for (let i = 0; i < perm.length; i++)
    for (let j = i + 1; j < perm.length; j++)
      if (perm[i] > perm[j]) inv++;
  return (inv % 2) as 0 | 1;
}

/**
 * 120 vertices of the 600-cell {3,3,5}, the H_4 root system.
 *  -  8: cyclic permutations of (±1, 0, 0, 0)
 *  - 16: (±½, ±½, ±½, ±½)
 *  - 96: even permutations of (±φ/2, ±½, ±1/(2φ), 0) with 8 sign combos
 * Total: 8 + 16 + 96 = 120 = |Φ(H_4)|.
 */
export function build600CellVertices(): Vec4[] {
  const verts: Vec4[] = [];

  // 8
  for (const s of [1, -1] as const) {
    verts.push([s, 0, 0, 0]);
    verts.push([0, s, 0, 0]);
    verts.push([0, 0, s, 0]);
    verts.push([0, 0, 0, s]);
  }

  // 16
  for (let i = 0; i < 16; i++) {
    verts.push([
      (i & 1) ? 0.5 : -0.5,
      (i & 2) ? 0.5 : -0.5,
      (i & 4) ? 0.5 : -0.5,
      (i & 8) ? 0.5 : -0.5,
    ]);
  }

  // 96 — even permutations of (φ/2, 1/2, 1/(2φ), 0), then all 8 sign combos of the 3 non-zero entries.
  const baseValues = [PHI / 2, 0.5, INV_PHI / 2, 0];
  const evenPerms = permutations([0, 1, 2, 3]).filter((p) => parity(p) === 0);
  for (const perm of evenPerms) {
    for (let s = 0; s < 8; s++) {
      const v: number[] = [0, 0, 0, 0];
      for (let k = 0; k < 4; k++) {
        v[k] = baseValues[perm[k]];
      }
      // Apply sign bits — find the three non-zero positions and flip per bit.
      const nonZero = [0, 1, 2, 3].filter((k) => v[k] !== 0);
      for (let b = 0; b < nonZero.length; b++) {
        if (s & (1 << b)) v[nonZero[b]] = -v[nonZero[b]];
      }
      verts.push([v[0], v[1], v[2], v[3]]);
    }
  }

  return verts;
}

/**
 * 720 edges of the 600-cell — pairs of vertices at squared distance 1/φ² (= 2 − 2cos(π/5)).
 * Each vertex has 12 neighbors (icosahedral neighborhood); 120·12/2 = 720.
 */
export function buildEdges(verts: Vec4[]): Array<[number, number]> {
  const target = 1 / (PHI * PHI);
  const tol = 1e-6;
  const edges: Array<[number, number]> = [];
  for (let i = 0; i < verts.length; i++) {
    for (let j = i + 1; j < verts.length; j++) {
      const a = verts[i], b = verts[j];
      const d2 =
        (a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2 +
        (a[2] - b[2]) ** 2 + (a[3] - b[3]) ** 2;
      if (Math.abs(d2 - target) < tol) edges.push([i, j]);
    }
  }
  return edges;
}

/**
 * Coxeter-plane double rotation: rotate (x,w) by θ (exponent m=1) and (y,z) by 29θ mod 2π (exponent m=29).
 * This is the action of the Coxeter element c ∈ W(H_4) with eigenvalues e^{2πi·m/h}, h=30, m∈{1,11,19,29}.
 * We use m=1 for the principal plane and m=29 (≡ −1 mod 30, the complex conjugate) for the orthogonal plane.
 */
export function rotate4D(v: Vec4, theta: number): Vec4 {
  const c1 = Math.cos(theta);
  const s1 = Math.sin(theta);
  const c29 = Math.cos(29 * theta);
  const s29 = Math.sin(29 * theta);
  const [x, y, z, w] = v;
  return [
    x * c1 - w * s1,
    y * c29 - z * s29,
    y * s29 + z * c29,
    x * s1 + w * c1,
  ];
}

/**
 * Stereographic projection from (0,0,0,d) onto the w=0 hyperplane.
 * Maps the 4-sphere (radius 1) to ℝ³, preserving conformal structure.
 */
export function stereographic3(v: Vec4, d = 2): [number, number, number] {
  const scale = d / (d - v[3]);
  return [v[0] * scale, v[1] * scale, v[2] * scale];
}

/**
 * Cross-section "vertex count" at angle θ — the visualization heuristic:
 * vertices with |w − cos(θ)| < ε belong to the 3D slice w = cos(θ).
 * The legend snapshots correspond to {0, π/30, 11π/30, π/2, 19π/30, 29π/30, π}.
 */
export function sliceCount(verts: Vec4[], theta: number, eps = 0.08): number {
  const target = Math.cos(theta);
  let n = 0;
  for (const v of verts) if (Math.abs(v[3] - target) < eps) n++;
  return n;
}

/** Coxeter cross-section legend — what the slice looks like at the six exponent angles. */
export const CROSS_SECTIONS = [
  { theta: 0, label: "Icosahedron", vertices: 12, note: "θ=0  •  H₃ subgroup pole" },
  { theta: Math.PI / 30, label: "Icosidodecahedron", vertices: 30, note: "θ=π/30  •  m=1 slice, h=30 visible" },
  { theta: (11 * Math.PI) / 30, label: "Truncated Icosahedron", vertices: 60, note: "θ=11π/30  •  m=11 slice" },
  { theta: Math.PI / 2, label: "Rhombicosidodecahedron", vertices: 120, note: "θ=π/2  •  full |Φ|=120 equator" },
  { theta: (19 * Math.PI) / 30, label: "Truncated Dodecahedron", vertices: 60, note: "θ=19π/30  •  m=19 slice" },
  { theta: (29 * Math.PI) / 30, label: "Dodecahedron", vertices: 20, note: "θ=29π/30  •  m=29 slice" },
  { theta: Math.PI, label: "Antipode", vertices: 12, note: "θ=π  •  H₃ subgroup antipole" },
] as const;
