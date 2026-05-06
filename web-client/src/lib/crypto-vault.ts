import { createHash } from "node:crypto";

/**
 * SHA-512 digital seal for legal traceability: binds document bytes, issuance time, and server secret.
 */
export function generateDigitalSeal(
  documentContent: string,
  timestampIso: string,
): string {
  const key = process.env.VETO_PRIVATE_KEY?.trim();
  if (!key) {
    throw new Error("VETO_PRIVATE_KEY is not configured");
  }
  const canonical = [
    "VETO_DIGITAL_SEAL_V1",
    documentContent,
    timestampIso,
    key,
  ].join("\u001e");
  return createHash("sha512").update(canonical, "utf8").digest("hex");
}

export function isSealConfigured(): boolean {
  return Boolean(process.env.VETO_PRIVATE_KEY?.trim());
}
