"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { saveEvidence } from "@/app/actions/vault";
import { uploadFile } from "@/api/vaultApi";
import {
  glassInput,
  glassPanel,
  modalBackdrop,
} from "@/lib/vetoGlass";
import { useToastStore } from "@/store/useToastStore";
import { useTranslation } from "@/lib/i18n/LocaleProvider";
import { Button } from "@/components/ui/primitives/Button";
import { IconButton } from "@/components/ui/primitives/IconButton";

export type VaultFolderOption = { id: string; name: string };

async function sha256HexFromFile(file: File): Promise<string> {
  const buf = await file.arrayBuffer();
  const hash = await crypto.subtle.digest("SHA-256", buf);
  return Array.from(new Uint8Array(hash))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

type VaultUploadModalProps = {
  open: boolean;
  folders: VaultFolderOption[];
  defaultFolderId: string;
  onClose: () => void;
  onUploadSuccess: () => void;
};

export function VaultUploadModal({
  open,
  folders,
  defaultFolderId,
  onClose,
  onUploadSuccess,
}: VaultUploadModalProps) {
  const { t } = useTranslation();
  const inputRef = useRef<HTMLInputElement>(null);
  const [folderId, setFolderId] = useState(defaultFolderId);
  const [picked, setPicked] = useState<File[]>([]);
  const [dragActive, setDragActive] = useState(false);
  const [isUploading, setIsUploading] = useState(false);
  const [uploadError, setUploadError] = useState<string | null>(null);
  const pushToast = useToastStore((s) => s.push);

  useEffect(() => {
    if (!open) return;
    queueMicrotask(() => {
      setFolderId(defaultFolderId);
      setUploadError(null);
    });
  }, [open, defaultFolderId]);

  const reset = useCallback(() => {
    setPicked([]);
    setFolderId(defaultFolderId);
    setDragActive(false);
    setUploadError(null);
    if (inputRef.current) inputRef.current.value = "";
  }, [defaultFolderId]);

  const handleClose = () => {
    if (isUploading) return;
    reset();
    onClose();
  };

  const addFiles = (list: FileList | File[]) => {
    const next = [...picked];
    for (let i = 0; i < list.length; i++) {
      next.push(list[i]!);
    }
    setPicked(next);
  };

  const onInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files?.length) addFiles(e.target.files);
  };

  const onDrop = (e: React.DragEvent) => {
    e.preventDefault();
    setDragActive(false);
    if (e.dataTransfer.files?.length) addFiles(e.dataTransfer.files);
  };

  const onDragOver = (e: React.DragEvent) => {
    e.preventDefault();
    setDragActive(true);
  };

  const onDragLeave = () => setDragActive(false);

  const submit = async () => {
    if (picked.length === 0 || isUploading) return;
    setUploadError(null);
    setIsUploading(true);
    try {
      const category =
        folderId.trim() === "" ? "general" : folderId.trim();

      for (const file of picked) {
        const hash = await sha256HexFromFile(file);
        const created = await uploadFile(file, folderId);
        const url =
          typeof created.url === "string" && created.url.length > 0
            ? created.url
            : "";
        if (!url) {
          throw new Error(t("vault.uploadMissingUrl"));
        }
        const neon = await saveEvidence({
          title: file.name,
          url,
          hash,
          category,
        });
        if (!neon.success) {
          throw new Error(neon.error);
        }
      }
      pushToast(t("vault.uploadSuccessToast"), "success");
      reset();
      onUploadSuccess();
      onClose();
    } catch (e) {
      const msg = e instanceof Error ? e.message : t("vault.uploadFailedGeneric");
      setUploadError(msg);
      pushToast(msg, "error");
    } finally {
      setIsUploading(false);
    }
  };

  if (!open) return null;

  return (
    <div
      className={`fixed inset-0 z-[90] flex items-end justify-center p-4 sm:items-center ${modalBackdrop}`}
      role="presentation"
      onMouseDown={(e) => {
        if (e.target === e.currentTarget && !isUploading) handleClose();
      }}
    >
      <div
        className={`flex max-h-[min(90dvh,640px)] w-full max-w-lg flex-col overflow-hidden shadow-2xl shadow-slate-900/20 ${glassPanel}`}
        role="dialog"
        aria-modal="true"
        aria-labelledby="vault-upload-title"
        onMouseDown={(e) => e.stopPropagation()}
      >
        <div className="flex items-start justify-between border-b border-subtle px-5 py-4">
          <div>
            <h2
              id="vault-upload-title"
              className="font-frank text-lg font-bold text-primary"
            >
              {t("vault.uploadModalTitle")}
            </h2>
            <p className="mt-0.5 text-sm text-secondary">
              {t("vault.uploadModalSubtitle")}
            </p>
          </div>
          <IconButton
            variant="ghost"
            size="sm"
            onClick={handleClose}
            disabled={isUploading}
            label={t("vault.uploadCloseAria")}
            icon={
              <svg className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth={2} viewBox="0 0 24 24">
                <path d="M6 18L18 6M6 6l12 12" />
              </svg>
            }
          />
        </div>

        <div className="min-h-0 flex-1 space-y-4 overflow-y-auto px-5 py-4">
          <div>
            <label
              htmlFor="vault-folder-select"
              className="mb-1.5 block text-xs font-semibold uppercase tracking-wide text-secondary"
            >
              {t("vault.destinationFolder")}
            </label>
            <select
              id="vault-folder-select"
              value={folderId}
              disabled={isUploading}
              onChange={(e) => setFolderId(e.target.value)}
              className={glassInput}
            >
              {folders.map((f) => (
                <option key={f.id || "__unsorted"} value={f.id}>
                  {f.name}
                </option>
              ))}
            </select>
          </div>

          <div>
            <p className="mb-1.5 text-xs font-semibold uppercase tracking-wide text-secondary">
              {t("vault.uploadFilesHeading")}
            </p>
            <div
              onDrop={onDrop}
              onDragOver={onDragOver}
              onDragLeave={onDragLeave}
              className={`rounded-2xl border-2 border-dashed px-4 py-10 text-center backdrop-blur-sm transition ${
                dragActive
                  ? "border-veto-gold bg-veto-gold/15 shadow-[0_0_24px_rgba(197,160,89,0.25)]" : "border-default bg-surface-sunken hover:border-veto-gold/50 dark:hover:border-white/40"} ${isUploading ? "pointer-events-none opacity-60" : ""}`}
            >
              <input
                ref={inputRef}
                type="file"
                multiple
                disabled={isUploading}
                className="sr-only"
                id="vault-file-input"
                onChange={onInputChange}
              />
              <label
                htmlFor="vault-file-input"
                className={`cursor-pointer text-sm text-secondary dark:text-secondary ${isUploading ? "cursor-not-allowed" : ""}`}
              >
                <span className="font-semibold text-veto-gold-dark">
                  {t("vault.browseFiles")}
                </span>
                <span className="text-secondary">
                  {t("vault.dragDropSuffix")}
                </span>
              </label>
              <p className="mt-2 text-xs text-muted">
                {t("vault.fileTypesHint")}
              </p>
            </div>
          </div>

          {picked.length > 0 && (
            <ul className="max-h-40 space-y-2 overflow-y-auto rounded-xl border border-subtle bg-surface-sunken p-2 backdrop-blur-md">
              {picked.map((f, i) => (
                <li
                  key={`${f.name}-${i}`}
                  className="flex items-center justify-between gap-2 rounded-lg border border-subtle bg-surface-overlay px-3 py-2 text-sm text-primary backdrop-blur-sm dark:bg-white/[0.04] dark:text-primary"
                >
                  <span className="truncate font-medium">{f.name}</span>
                  <Button
                    variant="link"
                    size="sm"
                    disabled={isUploading}
                    className="shrink-0 min-h-[44px] text-red-600 dark:text-red-400"
                    onClick={() =>
                      setPicked((prev) => prev.filter((_, idx) => idx !== i))
                    }
                  >
                    {t("vault.uploadRemoveSelected")}
                  </Button>
                </li>
              ))}
            </ul>
          )}

          {uploadError && (
            <p
              className="rounded-xl border border-red-500/40 bg-red-500/15 px-3 py-2 text-sm text-red-200 backdrop-blur-sm"
              role="alert"
            >
              {uploadError}
            </p>
          )}
        </div>

        <div className="flex gap-3 border-t border-subtle px-5 py-4">
          <Button variant="secondary" size="lg" className="flex-1" onClick={handleClose} disabled={isUploading}>
            {t("common.cancel")}
          </Button>
          <Button
            variant="primary"
            size="lg"
            className="flex-1"
            disabled={picked.length === 0 || isUploading}
            loading={isUploading}
            onClick={() => void submit()}
          >
            {isUploading
              ? t("vault.uploadingVault")
              : picked.length > 0
                ? t("vault.uploadAddCount").replace("{count}", String(picked.length))
                : t("vault.uploadAddFilesPlain")}
          </Button>
        </div>
      </div>
    </div>
  );
}
