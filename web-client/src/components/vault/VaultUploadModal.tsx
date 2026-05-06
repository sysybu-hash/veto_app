"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { uploadFile } from "@/api/vaultApi";

export type VaultFolderOption = { id: string; name: string };

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
  const inputRef = useRef<HTMLInputElement>(null);
  const [folderId, setFolderId] = useState(defaultFolderId);
  const [picked, setPicked] = useState<File[]>([]);
  const [dragActive, setDragActive] = useState(false);
  const [isUploading, setIsUploading] = useState(false);
  const [uploadError, setUploadError] = useState<string | null>(null);

  useEffect(() => {
    if (open) {
      setFolderId(defaultFolderId);
      setUploadError(null);
    }
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
      for (const file of picked) {
        await uploadFile(file, folderId);
      }
      reset();
      onUploadSuccess();
      onClose();
    } catch (e) {
      setUploadError(e instanceof Error ? e.message : "Upload failed");
    } finally {
      setIsUploading(false);
    }
  };

  if (!open) return null;

  return (
    <div
      className="fixed inset-0 z-[60] flex items-end justify-center bg-slate-900/50 p-4 sm:items-center"
      role="presentation"
      onMouseDown={(e) => {
        if (e.target === e.currentTarget && !isUploading) handleClose();
      }}
    >
      <div
        className="flex max-h-[min(90dvh,640px)] w-full max-w-lg flex-col overflow-hidden rounded-2xl bg-white shadow-2xl"
        role="dialog"
        aria-modal="true"
        aria-labelledby="vault-upload-title"
        onMouseDown={(e) => e.stopPropagation()}
      >
        <div className="flex items-start justify-between border-b border-slate-100 px-5 py-4">
          <div>
            <h2
              id="vault-upload-title"
              className="text-lg font-semibold text-slate-900"
            >
              Upload to vault
            </h2>
            <p className="mt-0.5 text-sm text-slate-500">
              Add documents or photos to your chosen folder.
            </p>
          </div>
          <button
            type="button"
            onClick={handleClose}
            disabled={isUploading}
            className="rounded-lg p-2 text-slate-500 hover:bg-slate-100 hover:text-slate-800 disabled:cursor-not-allowed disabled:opacity-40"
            aria-label="Close upload dialog"
          >
            <svg
              className="h-5 w-5"
              fill="none"
              stroke="currentColor"
              strokeWidth={2}
              viewBox="0 0 24 24"
            >
              <path d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <div className="min-h-0 flex-1 space-y-4 overflow-y-auto px-5 py-4">
          <div>
            <label
              htmlFor="vault-folder-select"
              className="mb-1.5 block text-xs font-semibold uppercase tracking-wide text-slate-500"
            >
              Destination folder
            </label>
            <select
              id="vault-folder-select"
              value={folderId}
              disabled={isUploading}
              onChange={(e) => setFolderId(e.target.value)}
              className="w-full rounded-xl border border-slate-200 bg-white px-3 py-2.5 text-sm text-slate-900 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20 disabled:cursor-not-allowed disabled:bg-slate-50"
            >
              {folders.map((f) => (
                <option key={f.id || "__unsorted"} value={f.id}>
                  {f.name}
                </option>
              ))}
            </select>
          </div>

          <div>
            <p className="mb-1.5 text-xs font-semibold uppercase tracking-wide text-slate-500">
              Files
            </p>
            <div
              onDrop={onDrop}
              onDragOver={onDragOver}
              onDragLeave={onDragLeave}
              className={`rounded-2xl border-2 border-dashed px-4 py-10 text-center transition ${
                dragActive
                  ? "border-blue-500 bg-blue-50"
                  : "border-slate-200 bg-slate-50 hover:border-slate-300"
              } ${isUploading ? "pointer-events-none opacity-60" : ""}`}
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
                className={`cursor-pointer text-sm text-slate-600 ${isUploading ? "cursor-not-allowed" : ""}`}
              >
                <span className="font-semibold text-blue-600">
                  Browse files
                </span>
                <span className="text-slate-500"> or drag and drop here</span>
              </label>
              <p className="mt-2 text-xs text-slate-400">
                PDF, images, Word — uploaded securely to your VETO vault
              </p>
            </div>
          </div>

          {picked.length > 0 && (
            <ul className="max-h-40 space-y-2 overflow-y-auto rounded-xl border border-slate-100 bg-white p-2">
              {picked.map((f, i) => (
                <li
                  key={`${f.name}-${i}`}
                  className="flex items-center justify-between gap-2 rounded-lg bg-slate-50 px-3 py-2 text-sm text-slate-800"
                >
                  <span className="truncate font-medium">{f.name}</span>
                  <button
                    type="button"
                    disabled={isUploading}
                    className="shrink-0 text-xs font-semibold text-red-600 hover:underline disabled:cursor-not-allowed disabled:opacity-40"
                    onClick={() =>
                      setPicked((prev) => prev.filter((_, idx) => idx !== i))
                    }
                  >
                    Remove
                  </button>
                </li>
              ))}
            </ul>
          )}

          {uploadError && (
            <p
              className="rounded-xl border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-800"
              role="alert"
            >
              {uploadError}
            </p>
          )}
        </div>

        <div className="flex gap-3 border-t border-slate-100 px-5 py-4">
          <button
            type="button"
            onClick={handleClose}
            disabled={isUploading}
            className="flex-1 rounded-xl border border-slate-200 py-3 text-sm font-semibold text-slate-700 hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-50"
          >
            Cancel
          </button>
          <button
            type="button"
            disabled={picked.length === 0 || isUploading}
            onClick={() => void submit()}
            className="flex-1 rounded-xl bg-blue-600 py-3 text-sm font-semibold text-white hover:bg-blue-500 disabled:cursor-not-allowed disabled:opacity-50"
          >
            {isUploading
              ? "Uploading…"
              : `Add ${picked.length > 0 ? `(${picked.length})` : "files"}`}
          </button>
        </div>
      </div>
    </div>
  );
}
