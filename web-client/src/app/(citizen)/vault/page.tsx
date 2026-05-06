"use client";

import { useRouter } from "next/navigation";
import { useCallback, useEffect, useMemo, useState } from "react";
import {
  deleteFile,
  fetchFiles,
  fetchFolders,
  type ApiVaultFile,
} from "@/api/vaultApi";
import { getJwt } from "@/lib/authToken";
import {
  VaultUploadModal,
  type VaultFolderOption,
} from "@/components/vault/VaultUploadModal";
import { CitizenBottomNav } from "@/components/citizen/CitizenBottomNav";

type VaultFolder = VaultFolderOption & {
  description: string;
  fileCount: number;
};

export type VaultFileEntry = {
  id: string;
  name: string;
  folderId: string;
  type: "pdf" | "image" | "doc" | "other";
  sizeLabel: string;
  updatedAt: string;
};

type FolderBase = { id: string; name: string; description: string };

function fileKindFromName(name: string): VaultFileEntry["type"] {
  const lower = name.toLowerCase();
  if (/\.(pdf)$/.test(lower)) return "pdf";
  if (/\.(png|jpe?g|gif|webp|heic)$/.test(lower)) return "image";
  if (/\.(docx?|txt|rtf)$/.test(lower)) return "doc";
  return "other";
}

function formatBytes(n: number): string {
  if (n < 1024) return `${n} B`;
  if (n < 1024 * 1024) return `${(n / 1024).toFixed(1)} KB`;
  return `${(n / (1024 * 1024)).toFixed(1)} MB`;
}

function mapApiFileToEntry(f: ApiVaultFile): VaultFileEntry {
  const uploaded = f.uploadedAt ? new Date(f.uploadedAt) : new Date();
  const dateLabel = Number.isNaN(uploaded.getTime())
    ? new Date().toISOString().slice(0, 10)
    : uploaded.toISOString().slice(0, 10);
  return {
    id: String(f._id),
    name: f.name,
    folderId: f.folderId != null ? String(f.folderId) : "",
    type: fileKindFromName(f.name),
    sizeLabel: formatBytes(typeof f.sizeBytes === "number" ? f.sizeBytes : 0),
    updatedAt: dateLabel,
  };
}

function FolderIcon({ className }: { className?: string }) {
  return (
    <svg
      className={className}
      viewBox="0 0 24 24"
      fill="currentColor"
      aria-hidden
    >
      <path d="M19.5 21a3 3 0 003-3v-4.5c0-1.257-.529-2.41-1.378-3.225a3.01 3.01 0 00-1.752-.894 3.002 3.002 0 00-1.093-.177h-1.307l-.228-.225a3 3 0 00-2.121-.879H6.75A3.75 3.75 0 003 8.25v10.5A3 3 0 006 21h13.5zM6 4.5a3 3 0 013-3h4.303a3 3 0 012.652 1.596L16.5 6H19.5a3 3 0 013 3v.75H6V4.5z" />
    </svg>
  );
}

function FileTypeIcon({ type }: { type: VaultFileEntry["type"] }) {
  const base = "h-8 w-8 shrink-0";
  if (type === "pdf") {
    return (
      <svg
        className={`${base} text-red-500`}
        viewBox="0 0 24 24"
        fill="currentColor"
        aria-hidden
      >
        <path d="M4 4a2 2 0 012-2h8l6 6v12a2 2 0 01-2 2H6a2 2 0 01-2-2V4zm2 0v16h12V9h-5V4H6zm2 4h8v2H8V8zm0 4h8v2H8v-2z" />
      </svg>
    );
  }
  if (type === "image") {
    return (
      <svg
        className={`${base} text-emerald-500`}
        viewBox="0 0 24 24"
        fill="currentColor"
        aria-hidden
      >
        <path d="M4 5a2 2 0 012-2h12a2 2 0 012 2v14a2 2 0 01-2 2H6a2 2 0 01-2-2V5zm2 0v14h12V5H6zm2 4a2 2 0 104.001 0A2 2 0 008 9zm6 6-3-4-4 6h12l-5-6z" />
      </svg>
    );
  }
  if (type === "doc") {
    return (
      <svg
        className={`${base} text-blue-600`}
        viewBox="0 0 24 24"
        fill="currentColor"
        aria-hidden
      >
        <path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8l-6-6zm0 3L17 8h-3V5zM8 12h8v2H8v-2zm0 4h8v2H8v-2z" />
      </svg>
    );
  }
  return (
    <svg
      className={`${base} text-slate-400`}
      viewBox="0 0 24 24"
      fill="currentColor"
      aria-hidden
    >
      <path d="M4 4a2 2 0 012-2h12a2 2 0 012 2v16a2 2 0 01-2 2H6a2 2 0 01-2-2V4zm2 0v16h12V4H6z" />
    </svg>
  );
}

function VaultLoadingSkeleton() {
  return (
    <div className="animate-pulse space-y-8" aria-busy="true" aria-label="Loading vault">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div className="space-y-2">
          <div className="h-8 w-56 rounded-lg bg-white/10 md:h-9 md:w-64" />
          <div className="h-4 w-full max-w-md rounded-lg bg-white/10" />
        </div>
        <div className="h-12 w-40 rounded-xl bg-white/10" />
      </div>
      <div>
        <div className="mb-3 h-4 w-24 rounded bg-white/10" />
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {[1, 2, 3].map((i) => (
            <div key={i} className="h-32 rounded-2xl bg-white/10" />
          ))}
        </div>
      </div>
      <div>
        <div className="mb-3 h-4 w-32 rounded bg-white/10" />
        <div className="h-52 rounded-2xl bg-white/10" />
      </div>
    </div>
  );
}

export default function CitizenVaultPage() {
  const router = useRouter();
  const [folderList, setFolderList] = useState<FolderBase[]>([]);
  const [files, setFiles] = useState<VaultFileEntry[]>([]);
  const [selectedFolderId, setSelectedFolderId] = useState<string | null>(null);
  const [uploadOpen, setUploadOpen] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [actionError, setActionError] = useState<string | null>(null);
  const [deletingId, setDeletingId] = useState<string | null>(null);

  const loadVault = useCallback(async () => {
    if (!getJwt()) return;
    setIsLoading(true);
    setLoadError(null);
    try {
      const [apiFolders, apiFiles] = await Promise.all([
        fetchFolders(),
        fetchFiles(),
      ]);
      setFiles(apiFiles.map(mapApiFileToEntry));
      setFolderList(
        apiFolders.map((fo) => ({
          id: String(fo._id),
          name: fo.name,
          description: "Documents in your vault",
        })),
      );
    } catch (e) {
      setLoadError(e instanceof Error ? e.message : "Failed to load vault");
      setFiles([]);
      setFolderList([]);
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    if (!getJwt()) {
      router.replace("/login");
      return;
    }
    void loadVault();
  }, [router, loadVault]);

  const folders: VaultFolder[] = useMemo(
    () =>
      folderList.map((folder) => ({
        ...folder,
        fileCount: files.filter((f) => f.folderId === folder.id).length,
      })),
    [folderList, files],
  );

  const uploadFolderOptions: VaultFolderOption[] = useMemo(
    () => [
      { id: "", name: "Unsorted" },
      ...folders.map(({ id, name }) => ({ id, name })),
    ],
    [folders],
  );

  const recentFiles = useMemo(() => {
    const list = selectedFolderId
      ? files.filter((f) => f.folderId === selectedFolderId)
      : [...files];
    return list.sort(
      (a, b) =>
        new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime(),
    );
  }, [files, selectedFolderId]);

  const removeFile = async (id: string) => {
    setActionError(null);
    setDeletingId(id);
    try {
      await deleteFile(id);
      await loadVault();
    } catch (e) {
      setActionError(e instanceof Error ? e.message : "Remove failed");
    } finally {
      setDeletingId(null);
    }
  };

  const defaultUploadFolderId = folders[0]?.id ?? "";

  return (
    <div className="mx-auto flex w-full max-w-5xl flex-1 flex-col px-4 pb-28 pt-8 md:px-8">
      <header className="mb-8 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-white md:text-3xl">
            My Legal Vault
          </h1>
          <p className="mt-1 text-sm text-slate-400">
            Organize contracts, evidence, and identification documents in one
            secure view.
          </p>
        </div>
        <button
          type="button"
          disabled={isLoading || !!loadError}
          onClick={() => setUploadOpen(true)}
          className="inline-flex items-center justify-center gap-2 rounded-xl bg-blue-600 px-5 py-3 text-sm font-semibold text-white shadow-lg shadow-blue-900/30 transition hover:bg-blue-500 disabled:cursor-not-allowed disabled:opacity-50"
        >
          <svg
            className="h-5 w-5"
            fill="none"
            stroke="currentColor"
            strokeWidth={2}
            viewBox="0 0 24 24"
            aria-hidden
          >
            <path
              d="M4 16v2a2 2 0 002 2h12a2 2 0 002-2v-2M7 10l5-5 5 5M12 5v12"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
          </svg>
          Upload file
        </button>
      </header>

      {isLoading && <VaultLoadingSkeleton />}

      {!isLoading && loadError && (
        <div
          className="mb-6 flex flex-col gap-3 rounded-xl border border-red-500/40 bg-red-950/40 px-4 py-4 text-sm text-red-100 sm:flex-row sm:items-center sm:justify-between"
          role="alert"
        >
          <p>{loadError}</p>
          <button
            type="button"
            onClick={() => void loadVault()}
            className="shrink-0 rounded-lg bg-red-600 px-4 py-2 text-sm font-semibold text-white hover:bg-red-500"
          >
            Retry
          </button>
        </div>
      )}

      {!isLoading && !loadError && (
        <>
          {actionError && (
            <div
              className="mb-6 rounded-xl border border-amber-500/40 bg-amber-950/30 px-4 py-3 text-sm text-amber-100"
              role="status"
            >
              {actionError}
            </div>
          )}

          <section className="mb-10">
            <div className="mb-3 flex items-center justify-between">
              <h2 className="text-sm font-semibold uppercase tracking-wide text-slate-400">
                Folders
              </h2>
              {selectedFolderId && (
                <button
                  type="button"
                  onClick={() => setSelectedFolderId(null)}
                  className="text-xs font-semibold text-blue-400 hover:text-blue-300"
                >
                  Show all files
                </button>
              )}
            </div>
            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
              {folders.map((folder) => {
                const active = selectedFolderId === folder.id;
                return (
                  <button
                    key={folder.id}
                    type="button"
                    onClick={() =>
                      setSelectedFolderId((cur) =>
                        cur === folder.id ? null : folder.id,
                      )
                    }
                    className={`flex flex-col rounded-2xl border p-5 text-left transition ${
                      active
                        ? "border-blue-500 bg-blue-950/40 ring-2 ring-blue-500/40"
                        : "border-white/10 bg-white/5 hover:border-white/20 hover:bg-white/[0.07]"
                    }`}
                  >
                    <div className="mb-3 flex items-center gap-3">
                      <div
                        className={`flex h-12 w-12 items-center justify-center rounded-xl ${
                          active
                            ? "bg-blue-600 text-white"
                            : "bg-slate-700 text-blue-300"
                        }`}
                      >
                        <FolderIcon className="h-7 w-7" />
                      </div>
                      <div className="min-w-0 flex-1">
                        <p className="font-semibold text-white">{folder.name}</p>
                        <p className="truncate text-xs text-slate-400">
                          {folder.description}
                        </p>
                      </div>
                    </div>
                    <p className="text-xs font-medium text-slate-500">
                      {folder.fileCount} {folder.fileCount === 1 ? "file" : "files"}
                    </p>
                  </button>
                );
              })}
            </div>
            {folders.length === 0 && (
              <p className="mt-3 text-sm text-slate-500">
                No folders yet. Upload files as{" "}
                <span className="font-medium text-slate-400">Unsorted</span> or
                create folders in the VETO app when available.
              </p>
            )}
          </section>

          <section>
            <h2 className="mb-3 text-sm font-semibold uppercase tracking-wide text-slate-400">
              {selectedFolderId
                ? `Files in ${folders.find((f) => f.id === selectedFolderId)?.name ?? "folder"}`
                : "Recent files"}
            </h2>
            <ul className="divide-y divide-white/10 overflow-hidden rounded-2xl border border-white/10 bg-white/[0.04]">
              {recentFiles.length === 0 && (
                <li className="px-4 py-12 text-center text-sm text-slate-500">
                  No files here yet. Upload to add evidence and documents.
                </li>
              )}
              {recentFiles.map((file) => (
                <li
                  key={file.id}
                  className="flex items-center gap-4 px-4 py-4 transition hover:bg-white/[0.06]"
                >
                  <FileTypeIcon type={file.type} />
                  <div className="min-w-0 flex-1">
                    <p className="truncate font-medium text-white">{file.name}</p>
                    <p className="text-xs text-slate-400">
                      {file.folderId
                        ? (folders.find((f) => f.id === file.folderId)?.name ??
                          "Folder")
                        : "Unsorted"}{" "}
                      · {file.sizeLabel} · {file.updatedAt}
                    </p>
                  </div>
                  <button
                    type="button"
                    disabled={deletingId === file.id}
                    onClick={() => void removeFile(file.id)}
                    className="shrink-0 rounded-lg px-2 py-1 text-xs font-semibold text-red-400 hover:bg-red-950/50 disabled:opacity-50"
                  >
                    {deletingId === file.id ? "Removing…" : "Remove"}
                  </button>
                </li>
              ))}
            </ul>
          </section>
        </>
      )}

      <VaultUploadModal
        open={uploadOpen}
        folders={uploadFolderOptions}
        defaultFolderId={defaultUploadFolderId}
        onClose={() => setUploadOpen(false)}
        onUploadSuccess={() => void loadVault()}
      />

      <CitizenBottomNav active="vault" />
    </div>
  );
}
