"use client";

import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import {
  createFolder,
  deleteFile,
  deleteFolder,
  fetchFiles,
  fetchFolders,
  fetchLawyerSharedInbox,
  setFileLawyerAccess,
  updateFolder,
  updateVaultFile,
  uploadFile,
  type ApiVaultFile,
  type ApiVaultFolder,
} from "@/api/vaultApi";
import { Button } from "@/components/ui/primitives/Button";
import { glassCard, glassList } from "@/lib/vetoGlass";
import { useTranslation } from "@/lib/i18n/LocaleProvider";
import {
  FolderPlus,
  Link2,
  Link2Off,
  Loader2,
  Pencil,
  Trash2,
  Upload,
} from "lucide-react";

type Props = {
  /** citizen = own folders + share toggles; lawyer = own workspace + shared inbox */
  mode: "citizen" | "lawyer";
};

/** Prefer i18n; fall back to Hebrew if the key was not merged into the active dictionary. */
function label(
  t: (path: string) => string,
  path: string,
  fallbackHe: string,
): string {
  const v = t(path);
  return !v || v === path ? fallbackHe : v;
}

function folderIdOf(file: ApiVaultFile): string | null {
  if (!file.folderId) return null;
  return String(file.folderId);
}

function formatBytes(n: number | undefined): string {
  if (!n || !Number.isFinite(n)) return "—";
  if (n < 1024) return `${n} B`;
  if (n < 1024 * 1024) return `${(n / 1024).toFixed(1)} KB`;
  return `${(n / (1024 * 1024)).toFixed(1)} MB`;
}

export function VaultCaseFoldersPanel({ mode }: Props) {
  const { t } = useTranslation();
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [folders, setFolders] = useState<ApiVaultFolder[]>([]);
  const [files, setFiles] = useState<ApiVaultFile[]>([]);
  const [sharedInbox, setSharedInbox] = useState<ApiVaultFile[]>([]);
  const [selectedFolderId, setSelectedFolderId] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [newFolderName, setNewFolderName] = useState("");
  const [renamingFolderId, setRenamingFolderId] = useState<string | null>(null);
  const [renameValue, setRenameValue] = useState("");
  const [view, setView] = useState<"mine" | "shared">(
    mode === "lawyer" ? "shared" : "mine",
  );

  // No setState before the first await: this runs straight from an effect, and a
  // synchronous setState there cascades an extra render pass on every mount.
  const refresh = useCallback(async () => {
    try {
      const [f, fl] = await Promise.all([fetchFolders(), fetchFiles()]);
      setError(null);
      setFolders(f);
      setFiles(fl);
      if (mode === "lawyer") {
        try {
          setSharedInbox(await fetchLawyerSharedInbox());
        } catch {
          setSharedInbox([]);
        }
      }
    } catch (e) {
      setError(
        e instanceof Error
          ? e.message
          : label(t, "vault.caseLoadFailed", "לא ניתן לטעון תיקיות"),
      );
    } finally {
      setLoading(false);
    }
  }, [mode, t]);

  useEffect(() => {
    // Deferred: refresh() writes state, and doing that straight from an effect
    // body cascades an extra render pass on every mount.
    queueMicrotask(() => void refresh());
  }, [refresh]);

  const rootFolders = useMemo(
    () => folders.filter((f) => !f.parentId),
    [folders],
  );

  const visibleFiles = useMemo(() => {
    if (view === "shared") return sharedInbox;
    if (!selectedFolderId) return files;
    return files.filter((f) => folderIdOf(f) === selectedFolderId);
  }, [files, selectedFolderId, sharedInbox, view]);

  const fileCountByFolder = useMemo(() => {
    const map = new Map<string, number>();
    for (const f of files) {
      const id = folderIdOf(f);
      if (!id) continue;
      map.set(id, (map.get(id) ?? 0) + 1);
    }
    return map;
  }, [files]);

  const createCaseFolder = async () => {
    const name = newFolderName.trim();
    if (!name || busy) return;
    setBusy(true);
    setError(null);
    try {
      await createFolder(name);
      setNewFolderName("");
      await refresh();
    } catch (e) {
      setError(
        e instanceof Error
          ? e.message
          : label(t, "vault.caseCreateFailed", "יצירת תיקייה נכשלה"),
      );
    } finally {
      setBusy(false);
    }
  };

  const renameCaseFolder = async (folderId: string) => {
    const name = renameValue.trim();
    if (!name || busy) return;
    setBusy(true);
    setError(null);
    try {
      await updateFolder(folderId, { name });
      setRenamingFolderId(null);
      await refresh();
    } catch (e) {
      setError(
        e instanceof Error
          ? e.message
          : label(t, "vault.caseRenameFailed", "שינוי שם נכשל"),
      );
    } finally {
      setBusy(false);
    }
  };

  const removeCaseFolder = async (folderId: string) => {
    if (busy) return;
    if (
      !window.confirm(
        label(t, "vault.caseDeleteConfirm", "למחוק את התיקייה? רק אם היא ריקה."),
      )
    ) {
      return;
    }
    setBusy(true);
    setError(null);
    try {
      await deleteFolder(folderId);
      if (selectedFolderId === folderId) setSelectedFolderId(null);
      await refresh();
    } catch (e) {
      setError(
        e instanceof Error
          ? e.message
          : label(t, "vault.caseDeleteFailed", "מחיקת תיקייה נכשלה"),
      );
    } finally {
      setBusy(false);
    }
  };

  const onUploadPicked = async (list: FileList | null) => {
    if (!list?.length || busy) return;
    setBusy(true);
    setError(null);
    try {
      const target = selectedFolderId ?? "";
      for (let i = 0; i < list.length; i++) {
        const file = list.item(i);
        if (file) await uploadFile(file, target);
      }
      await refresh();
    } catch (e) {
      setError(
        e instanceof Error
          ? e.message
          : label(t, "vault.uploadFailedGeneric", "ההעלאה נכשלה"),
      );
    } finally {
      setBusy(false);
      if (fileInputRef.current) fileInputRef.current.value = "";
    }
  };

  const toggleShare = async (file: ApiVaultFile) => {
    if (busy || mode !== "citizen") return;
    setBusy(true);
    setError(null);
    try {
      await setFileLawyerAccess(file._id, !file.lawyerAccess);
      await refresh();
    } catch (e) {
      setError(
        e instanceof Error
          ? e.message
          : label(t, "vault.shareFailed", "עדכון שיתוף נכשל"),
      );
    } finally {
      setBusy(false);
    }
  };

  const renameFile = async (file: ApiVaultFile) => {
    const name = window.prompt(
      label(t, "vault.caseRenameFilePrompt", "שם קובץ חדש"),
      file.name,
    );
    if (!name?.trim() || name.trim() === file.name) return;
    setBusy(true);
    setError(null);
    try {
      await updateVaultFile(file._id, { name: name.trim() });
      await refresh();
    } catch (e) {
      setError(
        e instanceof Error
          ? e.message
          : label(t, "vault.caseRenameFailed", "שינוי שם נכשל"),
      );
    } finally {
      setBusy(false);
    }
  };

  const moveFile = async (file: ApiVaultFile) => {
    const options = rootFolders
      .map((f) => `${f.name} → ${f._id}`)
      .join("\n");
    const raw = window.prompt(
      `${label(t, "vault.caseMovePrompt", "הדביקו מזהה תיקייה להעברה, או השאירו ריק לשורש:")}\n\n${options}\n\n(${label(t, "vault.caseMoveRootHint", "ריק = ללא תיקייה")})`,
      folderIdOf(file) ?? "",
    );
    if (raw === null) return;
    const folderId = raw.trim() === "" ? null : raw.trim();
    setBusy(true);
    setError(null);
    try {
      await updateVaultFile(file._id, { folderId });
      await refresh();
    } catch (e) {
      setError(
        e instanceof Error
          ? e.message
          : label(t, "vault.caseMoveFailed", "העברת קובץ נכשלה"),
      );
    } finally {
      setBusy(false);
    }
  };

  const removeVaultFile = async (file: ApiVaultFile) => {
    if (
      !window.confirm(
        label(t, "vault.caseDeleteFileConfirm", "למחוק את הקובץ מהכספת?"),
      )
    ) {
      return;
    }
    setBusy(true);
    setError(null);
    try {
      await deleteFile(file._id);
      await refresh();
    } catch (e) {
      setError(
        e instanceof Error
          ? e.message
          : label(t, "vault.removeFailed", "ההסרה נכשלה"),
      );
    } finally {
      setBusy(false);
    }
  };

  if (loading) {
    return (
      <section className="mb-10 flex items-center gap-2 text-sm text-muted">
        <Loader2 className="h-4 w-4 animate-spin" aria-hidden />
        {t("vault.loadingAria")}
      </section>
    );
  }

  return (
    <section className="mb-10 space-y-5">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <h2 className="font-frank text-xl font-black text-primary">
            {label(t, "vault.caseFoldersTitle", "תיקיות לפי מקרה")}
          </h2>
          <p className="mt-1 text-sm text-muted">
            {mode === "lawyer"
              ? label(
                  t,
                  "vault.caseFoldersLawyerSubtitle",
                  "צפו בקבצים שהמנוי אישר לכם, ונהלו גם את תיקיות העבודה שלכם.",
                )
              : label(
                  t,
                  "vault.caseFoldersCitizenSubtitle",
                  "צרו תיקייה לכל תיק, העלו קבצים, שנו שם/מיקום, ונהלו שיתוף עם עורך הדין לכל קובץ.",
                )}
          </p>
        </div>
        {mode === "lawyer" ? (
          <div className="flex gap-1 rounded-xl border border-subtle bg-white/[0.04] p-1">
            <button
              type="button"
              onClick={() => setView("shared")}
              className={`rounded-lg px-3 py-1.5 text-xs font-bold ${
                view === "shared"
                  ? "bg-veto-gold/20 text-brand-text"
                  : "text-secondary"
              }`}
            >
              {label(t, "vault.sharedInboxTab", "קבצים מאושרים")}
            </button>
            <button
              type="button"
              onClick={() => setView("mine")}
              className={`rounded-lg px-3 py-1.5 text-xs font-bold ${
                view === "mine"
                  ? "bg-veto-gold/20 text-brand-text"
                  : "text-secondary"
              }`}
            >
              {label(t, "vault.myWorkspaceTab", "הכספת שלי")}
            </button>
          </div>
        ) : null}
      </div>

      {error ? (
        <div
          className="rounded-2xl border border-amber-500/30 bg-amber-500/10 px-4 py-3 text-sm text-amber-100"
          role="status"
        >
          {error}
        </div>
      ) : null}

      {view === "mine" ? (
        <>
          <div className="flex flex-col gap-2 sm:flex-row">
            <input
              value={newFolderName}
              onChange={(e) => setNewFolderName(e.target.value)}
              placeholder={label(t, "vault.caseFolderNamePh", "שם תיקיית מקרה…")}
              className="min-h-11 flex-1 rounded-xl border border-subtle bg-white/[0.04] px-3 text-sm text-primary outline-none ring-veto-gold/40 focus:ring-2"
              disabled={busy}
            />
            <Button
              variant="secondary"
              disabled={busy || !newFolderName.trim()}
              onClick={() => void createCaseFolder()}
              iconStart={<FolderPlus className="h-4 w-4" aria-hidden />}
            >
              {label(t, "vault.caseCreateFolder", "תיקייה חדשה")}
            </Button>
            <Button
              variant="primary"
              disabled={busy}
              onClick={() => fileInputRef.current?.click()}
              iconStart={<Upload className="h-4 w-4" aria-hidden />}
            >
              {selectedFolderId
                ? label(t, "vault.caseUploadToFolder", "העלאה לתיקייה")
                : label(t, "vault.caseUploadRoot", "העלאה לכספת")}
            </Button>
            <input
              ref={fileInputRef}
              type="file"
              multiple
              className="hidden"
              onChange={(e) => void onUploadPicked(e.target.files)}
            />
          </div>

          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
            <button
              type="button"
              onClick={() => setSelectedFolderId(null)}
              className={`flex flex-col p-4 text-start transition ${glassCard} ${
                selectedFolderId == null
                  ? "ring-2 ring-veto-gold/50"
                  : "hover:bg-white/[0.06]"
              }`}
            >
              <p className="font-semibold text-primary">
                {label(t, "vault.caseAllFiles", "כל הקבצים")}
              </p>
              <p className="mt-1 text-xs text-muted">
                {files.length} {label(t, "vault.files", "קבצים")}
              </p>
            </button>
            {rootFolders.map((folder) => {
              const active = selectedFolderId === folder._id;
              const count = fileCountByFolder.get(folder._id) ?? 0;
              return (
                <div
                  key={folder._id}
                  className={`flex flex-col p-4 ${glassCard} ${
                    active ? "ring-2 ring-veto-gold/50" : ""
                  }`}
                >
                  {renamingFolderId === folder._id ? (
                    <div className="flex flex-col gap-2">
                      <input
                        value={renameValue}
                        onChange={(e) => setRenameValue(e.target.value)}
                        className="rounded-lg border border-subtle bg-white/[0.06] px-2 py-1.5 text-sm text-primary"
                        disabled={busy}
                      />
                      <div className="flex gap-2">
                        <Button
                          variant="primary"
                          size="sm"
                          disabled={busy}
                          onClick={() => void renameCaseFolder(folder._id)}
                        >
                          {t("common.save")}
                        </Button>
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => setRenamingFolderId(null)}
                        >
                          {t("common.cancel")}
                        </Button>
                      </div>
                    </div>
                  ) : (
                    <>
                      <button
                        type="button"
                        className="text-start"
                        onClick={() =>
                          setSelectedFolderId((cur) =>
                            cur === folder._id ? null : folder._id,
                          )
                        }
                      >
                        <p className="font-semibold text-primary">{folder.name}</p>
                        <p className="mt-1 text-xs text-muted">
                          {count}{" "}
                          {count === 1
                            ? label(t, "vault.fileOne", "קובץ")
                            : label(t, "vault.files", "קבצים")}
                        </p>
                      </button>
                      <div className="mt-3 flex flex-wrap gap-1">
                        <Button
                          variant="ghost"
                          size="sm"
                          className="text-secondary"
                          disabled={busy}
                          onClick={() => {
                            setRenamingFolderId(folder._id);
                            setRenameValue(folder.name);
                          }}
                          iconStart={<Pencil className="h-3.5 w-3.5" aria-hidden />}
                        >
                          {label(t, "vault.caseRename", "שנה שם")}
                        </Button>
                        <Button
                          variant="ghost"
                          size="sm"
                          className="text-red-300"
                          disabled={busy}
                          onClick={() => void removeCaseFolder(folder._id)}
                          iconStart={<Trash2 className="h-3.5 w-3.5" aria-hidden />}
                        >
                          {t("vault.remove")}
                        </Button>
                      </div>
                    </>
                  )}
                </div>
              );
            })}
          </div>
        </>
      ) : null}

      <div>
        <h3 className="mb-3 font-frank text-sm font-bold uppercase tracking-wide text-muted">
          {view === "shared"
            ? label(t, "vault.sharedInboxHeading", "קבצים שאושרו על ידי מנויים")
            : selectedFolderId
              ? label(t, "vault.filesInFolder", "קבצים ב-{name}").replace(
                  "{name}",
                  rootFolders.find((f) => f._id === selectedFolderId)?.name ??
                    label(t, "common.unknown", "לא ידוע"),
                )
              : label(t, "vault.caseFilesHeading", "קבצי תיקיות")}
        </h3>
        <ul className={glassList}>
          {visibleFiles.length === 0 ? (
            <li className="px-4 py-10 text-center text-sm text-muted">
              {view === "shared"
                ? label(t, "vault.sharedInboxEmpty", "אין עדיין קבצים ששותפו איתכם.")
                : label(
                    t,
                    "vault.emptyFilesList",
                    "אין כאן קבצים עדיין. העלו כדי לשמור ראיות.",
                  )}
            </li>
          ) : null}
          {visibleFiles.map((file) => (
            <li
              key={file._id}
              className="flex flex-col gap-3 px-4 py-4 sm:flex-row sm:items-center"
            >
              <div className="min-w-0 flex-1">
                <p className="truncate font-medium text-primary">{file.name}</p>
                <p className="text-xs text-muted">
                  {formatBytes(file.sizeBytes)}
                  {file.uploadedAt
                    ? ` · ${new Intl.DateTimeFormat("he-IL", {
                        dateStyle: "short",
                      }).format(new Date(file.uploadedAt))}`
                    : ""}
                  {view === "shared" && file.user_id
                    ? ` · ${label(t, "vault.sharedFromCitizen", "ממנוי משויך")}`
                    : ""}
                </p>
              </div>
              <div className="flex flex-wrap items-center gap-1">
                {file.url ? (
                  <a
                    href={file.url}
                    target="_blank"
                    rel="noreferrer"
                    className="rounded-lg px-2 py-1.5 text-xs font-bold text-brand-100 hover:bg-white/[0.06]"
                  >
                    {label(t, "vault.open", "פתח")}
                  </a>
                ) : null}
                {view === "mine" ? (
                  <>
                    <Button
                      variant="ghost"
                      size="sm"
                      disabled={busy}
                      onClick={() => void renameFile(file)}
                    >
                      {label(t, "vault.caseRename", "שנה שם")}
                    </Button>
                    <Button
                      variant="ghost"
                      size="sm"
                      disabled={busy}
                      onClick={() => void moveFile(file)}
                    >
                      {label(t, "vault.caseMove", "העבר")}
                    </Button>
                    {mode === "citizen" ? (
                      <Button
                        variant="ghost"
                        size="sm"
                        disabled={busy}
                        className={
                          file.lawyerAccess
                            ? "text-brand-text"
                            : "text-secondary"
                        }
                        onClick={() => void toggleShare(file)}
                        iconStart={
                          file.lawyerAccess ? (
                            <Link2 className="h-3.5 w-3.5" aria-hidden />
                          ) : (
                            <Link2Off className="h-3.5 w-3.5" aria-hidden />
                          )
                        }
                      >
                        {file.lawyerAccess
                          ? label(t, "vault.shareOn", "משותף לעו״ד")
                          : label(t, "vault.shareOff", "לא משותף")}
                      </Button>
                    ) : null}
                    <Button
                      variant="ghost"
                      size="sm"
                      className="text-red-300"
                      disabled={busy}
                      onClick={() => void removeVaultFile(file)}
                    >
                      {label(t, "vault.remove", "הסר")}
                    </Button>
                  </>
                ) : null}
              </div>
            </li>
          ))}
        </ul>
      </div>
    </section>
  );
}
