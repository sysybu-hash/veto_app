"use client";

import { useCallback, useState } from "react";
import { syncSosArtifactsToVault } from "@/app/actions/vault";

type SaveStatus = "idle" | "saving" | "saved" | "error";

/**
 * Pulls the citizen's most recent SOS artifacts (recording + transcript)
 * out of MongoDB and pushes them into the Postgres `Evidence` vault with
 * a digital seal so the citizen can later reference them as evidence.
 *
 * Wraps the existing `syncSosArtifactsToVault` server action so we don't
 * leak Postgres concerns into the call UI.
 */
export function useSaveToVault() {
  const [status, setStatus] = useState<SaveStatus>("idle");
  const [error, setError] = useState<string | null>(null);
  const [savedCount, setSavedCount] = useState<number>(0);

  const save = useCallback(async () => {
    setStatus("saving");
    setError(null);
    try {
      const result = await syncSosArtifactsToVault();
      if (result.success) {
        setSavedCount(result.added);
        setStatus("saved");
      } else {
        setStatus("error");
        setError(result.error);
      }
    } catch (err) {
      setStatus("error");
      setError(err instanceof Error ? err.message : String(err));
    }
  }, []);

  return { status, error, savedCount, save };
}
