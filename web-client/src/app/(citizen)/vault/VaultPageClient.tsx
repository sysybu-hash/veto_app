"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import type { EvidenceDTO } from "@/app/actions/vault";
import { deleteEvidence, syncSosArtifactsToVault } from "@/app/actions/vault";
import { getJwt } from "@/lib/authToken";
import { useTranslation } from "@/lib/i18n/LocaleProvider";
import {
  VaultUploadModal,
  type VaultFolderOption,
} from "@/components/vault/VaultUploadModal";
import { CitizenBottomNav } from "@/components/citizen/CitizenBottomNav";
import {
  btnPrimaryGold,
  btnSecondaryGlass,
  glassCard,
  glassList,
} from "@/lib/vetoGlass";
import { Wand2 } from "lucide-react";

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
  isVerified: boolean;
};

type FolderBase = { id: string; name: string; description: string };

function fileKindFromName(name: string): VaultFileEntry["type"] {
  const lower = name.toLowerCase();
  if (/\.(pdf)$/.test(lower)) return "pdf";
  if (/\.(png|jpe?g|gif|webp|heic)$/.test(lower)) return "image";
  if (/\.(docx?|txt|rtf)$/.test(lower)) return "doc";
  return "other";
}

function mapEvidenceToEntry(e: EvidenceDTO): VaultFileEntry {
  const hint = `${e.title} ${e.fileUrl}`;
  const uploaded = e.createdAt ? new Date(e.createdAt) : new Date();
  const dateLabel = Number.isNaN(uploaded.getTime())
    ? new Date().toISOString().slice(0, 10)
    : uploaded.toISOString().slice(0, 10);
  return {
    id: e.id,
    name: e.title,
    folderId: e.category,
    type: fileKindFromName(hint),
    sizeLabel: "—",
    updatedAt: dateLabel,
    isVerified: e.isVerified,
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

function VaultLoadingSkeleton({ label }: { label: string }) {
  return (
    <div className="animate-pulse space-y-8" aria-busy="true" aria-label={label}>
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div className="space-y-2">
          <div className="h-8 w-56 rounded-lg bg-white/[0.06] md:h-9 md:w-64" />
          <div className="h-4 w-full max-w-md rounded-lg bg-white/[0.03]" />
        </div>
        <div className="h-12 w-40 rounded-xl bg-white/[0.03]" />
      </div>
      <div>
        <div className="mb-3 h-4 w-24 rounded bg-white/[0.03]" />
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {[1, 2, 3].map((i) => (
            <div key={i} className={`h-32 ${glassCard} opacity-80`} />
          ))}
        </div>
      </div>
      <div>
        <div className="mb-3 h-4 w-32 rounded bg-white/[0.03]" />
        <div className={`h-52 ${glassCard} opacity-80`} />
      </div>
    </div>
  );
}

export function VaultPageClient({
  initialEvidence,
  adminContext = false,
}: {
  initialEvidence: EvidenceDTO[];
  /** When true, opened from /admin/vault — no citizen bottom nav. */
  adminContext?: boolean;
}) {
  const router = useRouter();
  const { t } = useTranslation();
  const [evidenceRows, setEvidenceRows] = useState<EvidenceDTO[]>(initialEvidence);
  const [selectedFolderId, setSelectedFolderId] = useState<string | null>(null);
  const [uploadOpen, setUploadOpen] = useState(false);
  const [isHydrating, setIsHydrating] = useState(true);
  const loadError: string | null = null;
  const [actionError, setActionError] = useState<string | null>(null);
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const [syncBusy, setSyncBusy] = useState(false);
  const [syncMsg, setSyncMsg] = useState<string | null>(null);
  const syncOnce = useRef(false);

  useEffect(() => {
    queueMicrotask(() => {
      setEvidenceRows(initialEvidence);
    });
  }, [initialEvidence]);

  useEffect(() => {
    if (!getJwt()) {
      router.replace("/login");
      return;
    }
    queueMicrotask(() => setIsHydrating(false));
  }, [router]);

  const folderList: FolderBase[] = useMemo(() => {
    const cats = [...new Set(evidenceRows.map((e) => e.category))];
    return cats.map((cat) => ({
      id: cat,
      name: cat === "general" ? t("vault.categoryGeneral") : cat,
      description: t("vault.folderCardDescription"),
    }));
  }, [evidenceRows, t]);

  const files = useMemo(
    () => evidenceRows.map(mapEvidenceToEntry),
    [evidenceRows],
  );

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
      { id: "", name: t("vault.categoryGeneral") },
      ...folders.map(({ id, name }) => ({ id, name })),
    ],
    [folders, t],
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

  const refreshVault = useCallback(() => {
    router.refresh();
  }, [router]);

  const runSosSync = useCallback(async () => {
    setSyncBusy(true);
    setSyncMsg(null);
    try {
      const r = await syncSosArtifactsToVault();
      if (!r.success) {
        setSyncMsg(r.error);
        return;
      }
      if (r.added > 0) {
        setSyncMsg(t("vault.syncSosOk").replace("{n}", String(r.added)));
        refreshVault();
      } else {
        setSyncMsg(t("vault.syncSosNone"));
      }
    } catch (e) {
      setSyncMsg(e instanceof Error ? e.message : t("vault.syncSosErr"));
    } finally {
      setSyncBusy(false);
    }
  }, [refreshVault, t]);

  useEffect(() => {
    if (!getJwt() || syncOnce.current) return;
    syncOnce.current = true;
    queueMicrotask(() => {
      void runSosSync();
    });
  }, [runSosSync]);

  const removeFile = async (id: string) => {
    setActionError(null);
    setDeletingId(id);
    try {
      const res = await deleteEvidence(id);
      if (!res.success) {
        setActionError(res.error);
        return;
      }
      refreshVault();
    } catch (e) {
      setActionError(e instanceof Error ? e.message : t("vault.removeFailed"));
    } finally {
      setDeletingId(null);
    }
  };

  const defaultUploadFolderId = folders[0]?.id ?? "";

  const bottomPad = adminContext ? "pb-10" : "pb-28";

  if (isHydrating) {
    return (
      <div
        className={`mx-auto flex w-full max-w-5xl flex-1 flex-col px-4 pt-8 md:px-8 ${bottomPad}`}
      >
        <VaultLoadingSkeleton label={t("vault.loadingAria")} />
        {!adminContext ? <CitizenBottomNav active="vault" /> : null}
      </div>
    );
  }

  return (
    <div
      className={`mx-auto flex w-full max-w-5xl flex-1 flex-col px-4 pt-8 md:px-8 ${bottomPad}`}
    >
      {adminContext ? (
        <Link
          href="/admin/dashboard"
          className="mb-4 inline-block text-sm font-semibold text-[#C5A059] hover:underline"
        >
          ← מרכז שליטה
        </Link>
      ) : null}
      <header className="mb-8 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="font-frank text-2xl font-bold tracking-tight text-slate-100 md:text-3xl">
            {t("vault.title")}
          </h1>
          <p className="mt-1 text-sm text-slate-400">{t("vault.subtitle")}</p>
          {syncMsg && (
            <p className="mt-2 text-xs text-slate-400" role="status">
              {syncMsg}
            </p>
          )}
        </div>
        <div className="flex w-full flex-col gap-3 sm:w-auto sm:items-end">
          <button
            type="button"
            disabled={syncBusy || !!loadError}
            onClick={() => void runSosSync()}
            className={`inline-flex items-center justify-center gap-2 px-5 py-3 text-sm ${btnSecondaryGlass} disabled:cursor-not-allowed disabled:opacity-50`}
          >
            {syncBusy ? t("vault.syncSosBusy") : t("vault.syncSos")}
          </button>
          <div className="flex w-full flex-col gap-2 sm:flex-row sm:flex-wrap sm:justify-end">
            <Link
              href="/vault/generator"
              className="inline-flex min-h-[3.25rem] flex-1 items-center justify-center gap-2.5 rounded-2xl bg-gradient-to-br from-slate-900 via-slate-800 to-[#3d3428] px-6 py-4 text-base font-semibold text-white shadow-[0_14px_44px_rgba(15,23,42,0.38)] ring-2 ring-[#C5A059]/40 transition hover:from-slate-800 hover:to-[#4a3f30] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#C5A059] sm:flex-initial sm:min-w-[260px]"
            >
              <Wand2 className="h-6 w-6 shrink-0" aria-hidden />
              יצירת מסמך חכם (AI)
            </Link>
            <button
              type="button"
              disabled={!!loadError}
              onClick={() => setUploadOpen(true)}
              className={`inline-flex min-h-[3.25rem] flex-1 items-center justify-center gap-2 px-6 py-4 text-base font-semibold ${btnPrimaryGold} disabled:cursor-not-allowed disabled:opacity-50 sm:flex-initial`}
            >
              <svg
                className="h-6 w-6 shrink-0"
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
          </div>
        </div>
      </header>

      {loadError && (
        <div
          className="mb-6 flex flex-col gap-3 rounded-2xl border border-red-500/30 bg-red-500/10 px-4 py-4 text-sm text-red-200 backdrop-blur-xl sm:flex-row sm:items-center sm:justify-between"
          role="alert"
        >
          <p>{loadError}</p>
          <button
            type="button"
            onClick={() => void refreshVault()}
            className={`shrink-0 px-4 py-2 text-sm ${btnSecondaryGlass} border-red-500/30 text-red-200`}
          >
            {t("common.retry")}
          </button>
        </div>
      )}

      {!loadError && (
        <>
          {actionError && (
            <div
              className="mb-6 rounded-2xl border border-amber-500/30 bg-amber-500/10 px-4 py-3 text-sm text-amber-200 backdrop-blur-xl"
              role="status"
            >
              {actionError}
            </div>
          )}

          <section className="mb-10">
            <div className="mb-3 flex items-center justify-between">
              <h2 className="font-frank text-sm font-bold uppercase tracking-wide text-slate-400">
                {t("vault.categories")}
              </h2>
              {selectedFolderId && (
                <button
                  type="button"
                  onClick={() => setSelectedFolderId(null)}
                  className={`text-xs ${btnSecondaryGlass} px-3 py-1.5`}
                >
                  {t("vault.showAllFiles")}
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
                    className={`flex flex-col p-5 text-start transition ${glassCard} ${
                      active
                        ? "shadow-[0_0_28px_rgba(197,160,89,0.35)] ring-2 ring-[#C5A059]/50"
                        : "hover:bg-white/[0.06]"
                    }`}
                  >
                    <div className="mb-3 flex items-center gap-3">
                      <div
                        className={`flex h-12 w-12 items-center justify-center rounded-xl border border-white/10 ${
                          active
                            ? "bg-[#C5A059]/25 text-[#C5A059]"
                            : "bg-white/[0.04] text-slate-300"
                        }`}
                      >
                        <FolderIcon className="h-7 w-7 drop-shadow-sm" />
                      </div>
                      <div className="min-w-0 flex-1">
                        <p className="font-semibold text-slate-100">{folder.name}</p>
                        <p className="truncate text-xs text-slate-400">
                          {folder.description}
                        </p>
                      </div>
                    </div>
                    <p className="text-xs font-medium text-slate-400">
                      {folder.fileCount}{" "}
                      {folder.fileCount === 1 ? t("vault.fileOne") : t("vault.files")}
                    </p>
                  </button>
                );
              })}
            </div>
            {folders.length === 0 && (
              <p className="mt-3 text-sm text-slate-500">
                {t("vault.emptyFoldersHint")}
              </p>
            )}
          </section>

          <section>
            <h2 className="mb-3 font-frank text-sm font-bold uppercase tracking-wide text-slate-400">
              {selectedFolderId
                ? t("vault.filesInFolder").replace(
                    "{name}",
                    folders.find((f) => f.id === selectedFolderId)?.name ??
                      t("common.unknown"),
                  )
                : t("vault.documentPreviews")}
            </h2>
            <ul className={glassList}>
              {recentFiles.length === 0 && (
                <li className="px-4 py-12 text-center text-sm text-slate-400">
                  {t("vault.emptyFilesList")}
                </li>
              )}
              {recentFiles.map((file) => (
                <li
                  key={file.id}
                  className="flex items-center gap-4 px-4 py-4 transition hover:bg-white/[0.04]"
                >
                  <div className="rounded-xl border border-white/10 bg-white/[0.04] p-2 backdrop-blur-md">
                    <FileTypeIcon type={file.type} />
                  </div>
                  <div className="min-w-0 flex-1 rounded-xl border border-white/10 bg-white/[0.03] px-3 py-2 backdrop-blur-md">
                    <div className="flex flex-wrap items-center gap-2">
                      <p className="truncate font-medium text-slate-100">
                        {file.name}
                      </p>
                      {file.isVerified ? (
                        <span
                          className="shrink-0 rounded-md border border-[#C5A059]/40 bg-[#C5A059]/15 px-2 py-0.5 text-[10px] font-black uppercase tracking-wide text-[#e8c987] shadow-[0_0_12px_rgba(197,160,89,0.35)]"
                          title={t("vault.sealTitle")}
                        >
                          {t("vault.sealedBadge")}
                        </span>
                      ) : null}
                    </div>
                    <p className="text-xs text-slate-400">
                      {folders.find((f) => f.id === file.folderId)?.name ??
                        file.folderId}{" "}
                      · {file.sizeLabel} · {file.updatedAt}
                    </p>
                  </div>
                  <a
                    href={evidenceRows.find((e) => e.id === file.id)?.fileUrl}
                    target="_blank"
                    rel="noreferrer"
                    className="shrink-0 rounded-lg px-2 py-1 text-xs font-semibold text-[#e8c987] hover:bg-white/[0.06]"
                  >
                    {t("vault.open")}
                  </a>
                  <button
                    type="button"
                    disabled={deletingId === file.id}
                    onClick={() => void removeFile(file.id)}
                    className="shrink-0 rounded-lg px-2 py-1 text-xs font-semibold text-red-300 hover:bg-red-500/15 disabled:opacity-50"
                  >
                    {deletingId === file.id ? t("vault.removing") : t("vault.remove")}
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
        onUploadSuccess={() => {
          refreshVault();
        }}
      />

      {!adminContext ? <CitizenBottomNav active="vault" /> : null}
    </div>
  );
}
