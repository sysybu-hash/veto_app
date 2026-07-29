import { apiUrl, authJsonHeaders } from "@/api/apiClient";
import type { SerializedLegalDocument } from "@/lib/documentSerialize";

/**
 * Server-side document export (`backend/src/services/documentRender`).
 * Replaces the client-side html2canvas+jsPDF rasterization path: the
 * PDF is rendered by real Chromium (selectable/searchable Hebrew text,
 * proper page breaks, running header/footer with page numbers) instead
 * of being a sliced screenshot.
 */
export async function renderDocumentExport(
  document: SerializedLegalDocument,
  format: "pdf" | "docx",
  lang: "he" | "en" | "ru" = "he",
): Promise<Blob> {
  const res = await fetch(apiUrl("/api/doc-export"), {
    method: "POST",
    headers: authJsonHeaders(),
    body: JSON.stringify({ document, format, lang }),
  });
  if (!res.ok) {
    const body = await res.json().catch(() => ({}));
    throw new Error(body?.error || `Export failed (${res.status})`);
  }
  return res.blob();
}
