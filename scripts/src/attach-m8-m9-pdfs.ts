import { readFileSync, existsSync } from "node:fs";
import { randomUUID } from "node:crypto";
import { Storage } from "@google-cloud/storage";
import { eq } from "drizzle-orm";
import { db, pool, certificatesTable } from "@workspace/db";

const REPLIT_SIDECAR_ENDPOINT = "http://127.0.0.1:1106";

const storage = new Storage({
  credentials: {
    audience: "replit",
    subject_token_type: "access_token",
    token_url: `${REPLIT_SIDECAR_ENDPOINT}/token`,
    type: "external_account",
    credential_source: {
      url: `${REPLIT_SIDECAR_ENDPOINT}/credential`,
      format: { type: "json", subject_token_field_name: "access_token" },
    },
    universe_domain: "googleapis.com",
  },
  projectId: "",
});

const PRIVATE_OBJECT_DIR = process.env.PRIVATE_OBJECT_DIR;
if (!PRIVATE_OBJECT_DIR) throw new Error("PRIVATE_OBJECT_DIR not set");

function parseObjectPath(path: string): {
  bucketName: string;
  objectName: string;
} {
  const p = path.startsWith("/") ? path : `/${path}`;
  const parts = p.split("/").filter((s) => s.length > 0);
  if (parts.length < 1) throw new Error(`Invalid object path: ${path}`);
  const bucketName = parts[0];
  const objectName = parts.slice(1).join("/");
  return { bucketName, objectName };
}

async function uploadBytes(
  bytes: Buffer,
  contentType: string,
): Promise<string> {
  const objectId = randomUUID();
  const privateDir = PRIVATE_OBJECT_DIR!.endsWith("/")
    ? PRIVATE_OBJECT_DIR!.slice(0, -1)
    : PRIVATE_OBJECT_DIR!;
  const fullPath = `${privateDir}/uploads/${objectId}`;
  const { bucketName, objectName } = parseObjectPath(fullPath);
  const file = storage.bucket(bucketName).file(objectName);
  await file.save(bytes, {
    contentType,
    resumable: false,
    metadata: { contentType },
  });
  return `/objects/uploads/${objectId}`;
}

async function setPdfPath(moduleId: string, objectPath: string) {
  await db
    .update(certificatesTable)
    .set({ pdfObjectPath: objectPath })
    .where(eq(certificatesTable.moduleId, moduleId));
  console.log(`  ${moduleId} pdfObjectPath = ${objectPath}`);
}

async function main() {
  const m8PdfPath = new URL(
    "../../attached_assets/Module_M8A_Audit_1779645671320.pdf",
    import.meta.url,
  );
  if (!existsSync(m8PdfPath)) {
    throw new Error(`M8 source PDF not found at ${m8PdfPath.pathname}`);
  }

  console.log("Uploading M8 PDF (Bost-Connes Input Checks audit)...");
  const m8Bytes = readFileSync(m8PdfPath);
  const m8Path = await uploadBytes(m8Bytes, "application/pdf");
  await setPdfPath("M8", m8Path);

  const m9PdfPath = new URL(
    "../../attached_assets/M9_All_GRH_WeilTransfer.pdf",
    import.meta.url,
  );
  if (!existsSync(m9PdfPath)) {
    throw new Error(`M9 source PDF not found at ${m9PdfPath.pathname}`);
  }

  console.log(
    "Uploading M9 PDF (Opera Numerorum — M9-All GRH Certification, 280-curve Bost-Connes VALOR table)...",
  );
  const m9Bytes = readFileSync(m9PdfPath);
  const m9Path = await uploadBytes(m9Bytes, "application/pdf");
  await setPdfPath("M9", m9Path);

  console.log("Done.");
  await pool.end();
}

await main();
