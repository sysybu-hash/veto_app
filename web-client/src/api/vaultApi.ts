import {
  authJsonHeaders,
  authMultipartHeaders,
  apiUrl,
} from "@/api/apiClient";

/** Raw file document from GET /api/vault/files */
export type ApiVaultFile = {
  _id: string;
  name: string;
  mimeType?: string;
  sizeBytes: number;
  folderId?: string | null;
  uploadedAt?: string;
};

/** Raw folder from GET /api/vault/folders */
export type ApiVaultFolder = {
  _id: string;
  name: string;
  parentId?: string | null;
  createdAt?: string;
};

async function readErrorMessage(res: Response): Promise<string> {
  try {
    const data = (await res.json()) as { error?: unknown; message?: unknown };
    if (typeof data.error === "string") return data.error;
    if (typeof data.message === "string") return data.message;
  } catch {
    /* ignore */
  }
  return `Request failed (${res.status})`;
}

/**
 * GET /api/vault/files — all files for the current user.
 */
export async function fetchFiles(): Promise<ApiVaultFile[]> {
  const res = await fetch(apiUrl("/api/vault/files"), {
    method: "GET",
    headers: authJsonHeaders(),
  });
  if (!res.ok) {
    throw new Error(await readErrorMessage(res));
  }
  const data = (await res.json()) as { files?: unknown };
  if (!Array.isArray(data.files)) {
    throw new Error("Invalid response: missing files array");
  }
  return data.files as ApiVaultFile[];
}

/**
 * GET /api/vault/folders — folders for the current user.
 */
export async function fetchFolders(): Promise<ApiVaultFolder[]> {
  const res = await fetch(apiUrl("/api/vault/folders"), {
    method: "GET",
    headers: authJsonHeaders(),
  });
  if (!res.ok) {
    throw new Error(await readErrorMessage(res));
  }
  const data = (await res.json()) as { folders?: unknown };
  if (!Array.isArray(data.folders)) {
    throw new Error("Invalid response: missing folders array");
  }
  return data.folders as ApiVaultFolder[];
}

/**
 * POST /api/vault/files/upload — multipart upload (field name `file`).
 * Uses FormData; do not set `Content-Type` manually so the browser adds the boundary.
 */
export async function uploadFile(
  file: File,
  folderId: string,
): Promise<ApiVaultFile> {
  const formData = new FormData();
  formData.append("file", file);
  formData.append("name", file.name);
  formData.append("mimeType", file.type || "application/octet-stream");
  if (folderId.trim() !== "") {
    formData.append("folderId", folderId);
  }

  const res = await fetch(apiUrl("/api/vault/files/upload"), {
    method: "POST",
    headers: authMultipartHeaders(),
    body: formData,
  });

  if (!res.ok) {
    throw new Error(await readErrorMessage(res));
  }
  const created = (await res.json()) as ApiVaultFile & { _id?: string };
  if (!created?._id) {
    throw new Error("Invalid response: missing file id");
  }
  return created as ApiVaultFile;
}

/**
 * DELETE /api/vault/files/:fileId
 */
export async function deleteFile(fileId: string): Promise<void> {
  const res = await fetch(apiUrl(`/api/vault/files/${encodeURIComponent(fileId)}`), {
    method: "DELETE",
    headers: authJsonHeaders(),
  });
  if (!res.ok) {
    throw new Error(await readErrorMessage(res));
  }
}
