"use client";

import { useCallback, useState } from "react";
import { saveCallArtifactsToVault } from "@/app/actions/vault";

type SaveStatus = "idle" | "saving" | "saved" | "error";

/**
 * Marks the current call's recording/transcript as saved on the API (Mongo +
 * VaultFile), then optionally mirrors rows into Postgres Evidence when
 * DATABASE_URL is configured.
 */
export function useSaveToVault(eventId: string | null) {
  const [status, setStatus] = useState<SaveStatus>("idle");
  const [error, setError] = useState<string | null>(null);
  const [savedCount, setSavedCount] = useState<number>(0);

  const save = useCallback(async () => {
    if (!eventId?.trim()) {
      setStatus("error");
      setError("חסר מזהה שיחה — לא ניתן לשמור.");
      return;
    }
    setStatus("saving");
    setError(null);
    try {
      const result = await saveCallArtifactsToVault(eventId);
      if (result.success) {
        setSavedCount(result.prismaAdded);
        setStatus("saved");
      } else {
        setStatus("error");
        setError(result.error);
      }
    } catch (err) {
      setStatus("error");
      setError(err instanceof Error ? err.message : String(err));
    }
  }, [eventId]);

  return { status, error, savedCount, save };
}
