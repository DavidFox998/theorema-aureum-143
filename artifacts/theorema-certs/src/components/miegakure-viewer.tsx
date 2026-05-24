import { useMemo, useRef, useState, useEffect } from "react";
import { Canvas, useFrame } from "@react-three/fiber";
import { OrbitControls } from "@react-three/drei";
import * as THREE from "three";
import {
  build600CellVertices,
  buildEdges,
  rotate4D,
  stereographic3,
  type Vec4,
} from "@/lib/h4-600cell";

function detectWebGL(): boolean {
  try {
    const c = document.createElement("canvas");
    return !!(c.getContext("webgl2") || c.getContext("webgl"));
  } catch {
    return false;
  }
}

interface PolytopeProps {
  theta: number;
  autoRotate3D: boolean;
}

function Polytope({ theta, autoRotate3D }: PolytopeProps) {
  const groupRef = useRef<THREE.Group>(null);
  const pointsRef = useRef<THREE.Points>(null);
  const linesRef = useRef<THREE.LineSegments>(null);

  const { verts4D, edges } = useMemo(() => {
    const v = build600CellVertices();
    const e = buildEdges(v);
    return { verts4D: v, edges: e };
  }, []);

  const pointGeo = useMemo(() => new THREE.BufferGeometry(), []);
  const lineGeo = useMemo(() => new THREE.BufferGeometry(), []);
  const pointPositions = useMemo(() => new Float32Array(verts4D.length * 3), [verts4D]);
  const linePositions = useMemo(() => new Float32Array(edges.length * 2 * 3), [edges]);
  const pointColors = useMemo(() => new Float32Array(verts4D.length * 3), [verts4D]);

  // Initialize attributes
  useMemo(() => {
    pointGeo.setAttribute("position", new THREE.BufferAttribute(pointPositions, 3));
    pointGeo.setAttribute("color", new THREE.BufferAttribute(pointColors, 3));
    lineGeo.setAttribute("position", new THREE.BufferAttribute(linePositions, 3));
  }, [pointGeo, lineGeo, pointPositions, linePositions, pointColors]);

  useFrame((_, delta) => {
    // Project rotated 4D vertices to 3D
    const projected: [number, number, number][] = new Array(verts4D.length);
    for (let i = 0; i < verts4D.length; i++) {
      const r = rotate4D(verts4D[i] as Vec4, theta);
      projected[i] = stereographic3(r, 2.4);
    }

    for (let i = 0; i < projected.length; i++) {
      const p = projected[i];
      pointPositions[i * 3] = p[0];
      pointPositions[i * 3 + 1] = p[1];
      pointPositions[i * 3 + 2] = p[2];
      // Color by proximity to the slice w = cos(θ) (in rotated coords, w component).
      const rw = rotate4D(verts4D[i] as Vec4, theta)[3];
      const slice = Math.cos(theta);
      const closeness = Math.max(0, 1 - Math.abs(rw - slice) * 3);
      // gold for "on slice", deep indigo for "off"
      pointColors[i * 3] = 0.15 + 0.85 * closeness;
      pointColors[i * 3 + 1] = 0.12 + 0.68 * closeness;
      pointColors[i * 3 + 2] = 0.35 + 0.05 * closeness;
    }

    for (let i = 0; i < edges.length; i++) {
      const [a, b] = edges[i];
      const pa = projected[a];
      const pb = projected[b];
      linePositions[i * 6] = pa[0];
      linePositions[i * 6 + 1] = pa[1];
      linePositions[i * 6 + 2] = pa[2];
      linePositions[i * 6 + 3] = pb[0];
      linePositions[i * 6 + 4] = pb[1];
      linePositions[i * 6 + 5] = pb[2];
    }

    pointGeo.attributes.position.needsUpdate = true;
    pointGeo.attributes.color.needsUpdate = true;
    lineGeo.attributes.position.needsUpdate = true;
    pointGeo.computeBoundingSphere();
    lineGeo.computeBoundingSphere();

    if (autoRotate3D && groupRef.current) {
      groupRef.current.rotation.y += delta * 0.18;
    }
  });

  return (
    <group ref={groupRef}>
      <lineSegments ref={linesRef} geometry={lineGeo}>
        <lineBasicMaterial color="#3a3358" transparent opacity={0.42} />
      </lineSegments>
      <points ref={pointsRef} geometry={pointGeo}>
        <pointsMaterial size={0.085} vertexColors sizeAttenuation />
      </points>
    </group>
  );
}

interface MiegakureViewerProps {
  theta: number;
  autoRotate3D: boolean;
}

export function MiegakureViewer({ theta, autoRotate3D }: MiegakureViewerProps) {
  const [webglOk, setWebglOk] = useState<boolean | null>(null);

  useEffect(() => {
    setWebglOk(detectWebGL());
  }, []);

  if (webglOk === false) {
    return (
      <div
        className="w-full h-full flex items-center justify-center p-6 font-mono text-xs text-muted-foreground"
        style={{ background: "linear-gradient(180deg, #07070d 0%, #11101a 100%)" }}
        data-testid="miegakure-fallback"
      >
        <div className="max-w-md text-center space-y-2">
          <div className="text-foreground text-sm">WebGL unavailable in this environment.</div>
          <div>120 H₄ root vectors loaded · 720 edges computed · rotation prepared.</div>
          <div className="text-[10px]">Open in a desktop browser with WebGL enabled to see the 600-cell rotate.</div>
        </div>
      </div>
    );
  }

  if (webglOk === null) {
    return (
      <div
        className="w-full h-full"
        style={{ background: "linear-gradient(180deg, #07070d 0%, #11101a 100%)" }}
      />
    );
  }

  return (
    <Canvas
      camera={{ position: [4.5, 3, 4.5], fov: 50 }}
      style={{ background: "linear-gradient(180deg, #07070d 0%, #11101a 100%)" }}
      data-testid="miegakure-canvas"
      onCreated={({ gl }) => {
        gl.setClearColor("#07070d", 1);
      }}
    >
      <ambientLight intensity={0.45} />
      <pointLight position={[5, 5, 5]} intensity={0.9} color="#f5d782" />
      <pointLight position={[-5, -3, -5]} intensity={0.5} color="#6e7bff" />
      <Polytope theta={theta} autoRotate3D={autoRotate3D} />
      <OrbitControls enableDamping dampingFactor={0.08} />
    </Canvas>
  );
}
