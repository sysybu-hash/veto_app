"use server";

import { createHash } from "node:crypto";
import { revalidatePath } from "next/cache";
import type { Role } from "@prisma/client";
import { prisma } from "@/lib/prisma";
import {
  getVetoRoleFromCookies,
  getVetoUserIdFromCookies,
  getVetoJwtFromCookies,
} from "@/lib/jwtCookie";
import { getPublicApiOrigin, tunnelBypassHeaders } from "@/lib/env";

export type EvidenceDTO = {
  id: string;
  title: string;
  fileUrl: string;
  fileHash: string;
  category: string;
  isVerified: boolean;
  digitalSeal: string | null;
  createdAt: string;
};

function mapJwtRoleToPrisma(role: string | null | undefined): Role {
  if (role === "admin") return "ADMIN";
  if (role === "lawyer") return "LAWYER";
  return "CITIZEN";
}

async function ensureUserForExternalId(
  externalId: string,
  role: string | null | undefined,
) {
  const email = `citizen-${externalId}@veto-linked.local`;
  return prisma.user.upsert({
    where: { externalId },
    create: {
      externalId,
      email,
      role: mapJwtRoleToPrisma(role),
    },
    update: {},
  });
}

export async function listEvidenceForSession(): Promise<EvidenceDTO[]> {
  try {
    const externalId = await getVetoUserIdFromCookies();
    if (!externalId) return [];

    const user = await prisma.user.findUnique({
      where: { externalId },
    });
    if (!user) return [];

    const rows = await prisma.evidence.findMany({
      where: { ownerId: user.id },
      orderBy: { createdAt: "desc" },
    });

    return rows.map((e) => ({
      id: e.id,
      title: e.title,
      fileUrl: e.fileUrl,
      fileHash: e.fileHash,
      category: e.category,
      isVerified: e.isVerified,
      digitalSeal: e.digitalSeal,
      createdAt: e.createdAt.toISOString(),
    }));
  } catch (e) {
    console.error("[vault] listEvidenceForSession:", e);
    return [];
  }
}

export async function saveEvidence(data: {
  title: string;
  url: string;
  hash: string;
  category: string;
  isVerified?: boolean;
  digitalSeal?: string | null;
  sourceEmergencyEventId?: string | null;
}): Promise<
  { success: true; id: string } | { success: false; error: string }
> {
  const externalId = await getVetoUserIdFromCookies();
  if (!externalId) {
    return { success: false, error: "נדרשת התחברות" };
  }

  const role = await getVetoRoleFromCookies();

  try {
    const user = await ensureUserForExternalId(externalId, role);
    const evidence = await prisma.evidence.create({
      data: {
        title: data.title,
        fileUrl: data.url,
        fileHash: data.hash,
        category: data.category || "general",
        ownerId: user.id,
        isVerified: data.isVerified ?? false,
        digitalSeal: data.digitalSeal ?? null,
        sourceEmergencyEventId: data.sourceEmergencyEventId ?? null,
      },
    });
    revalidatePath("/vault");
    return { success: true, id: evidence.id };
  } catch (error) {
    console.error("saveEvidence:", error);
    return { success: false, error: "שגיאה בשמירה לכספת" };
  }
}

/** Fetch SOS recording/transcript artifacts from Mongo (via API) and upsert Prisma Evidence. */
export async function syncSosArtifactsToVault(): Promise<
  { success: true; added: number } | { success: false; error: string }
> {
  const externalId = await getVetoUserIdFromCookies();
  if (!externalId) {
    return { success: false, error: "נדרשת התחברות" };
  }

  const role = await getVetoRoleFromCookies();
  if (role !== "user" && role !== "admin") {
    return { success: false, error: "זמין לאזרחים בלבד" };
  }

  const token = await getVetoJwtFromCookies();
  const base = getPublicApiOrigin();
  if (!token?.trim()) {
    return { success: false, error: "נדרשת התחברות" };
  }
  if (!base) {
    return { success: false, error: "חסרה הגדרת API" };
  }

  let items: Array<{
    _id: string;
    recording_url?: string | null;
    call_transcript?: string | null;
    transcript_language?: string | null;
    triggered_at?: string | null;
  }>;

  try {
    const res = await fetch(`${base}/api/calls/my-sos-artifacts`, {
      method: "GET",
      headers: {
        Authorization: `Bearer ${token}`,
        ...tunnelBypassHeaders(),
      },
    });
    if (!res.ok) {
      const err = await res.text().catch(() => "");
      return {
        success: false,
        error: `טעינת ארכיון SOS נכשלה (${res.status})${err ? `: ${err.slice(0, 120)}` : ""}`,
      };
    }
    const data = (await res.json()) as {
      success?: boolean;
      items?: typeof items;
    };
    if (!data.success || !Array.isArray(data.items)) {
      return { success: false, error: "תגובת שרת לא צפויה" };
    }
    items = data.items;
  } catch (e) {
    console.error("[vault] sync SOS fetch:", e);
    return { success: false, error: "שגיאת רשת בארכיון SOS" };
  }

  const user = await ensureUserForExternalId(externalId, role);
  let added = 0;

  for (const row of items) {
    const mongoId = row._id;
    if (!mongoId) continue;

    const hasRec =
      typeof row.recording_url === "string" && row.recording_url.length > 0;
    const hasTr =
      typeof row.call_transcript === "string" &&
      row.call_transcript.trim().length > 0;
    if (!hasRec && !hasTr) continue;

    const when =
      row.triggered_at && !Number.isNaN(Date.parse(row.triggered_at))
        ? new Date(row.triggered_at).toISOString().slice(0, 16)
        : new Date().toISOString().slice(0, 16);

    if (hasRec) {
      const recId = mongoId;
      const existingRec = await prisma.evidence.findFirst({
        where: { ownerId: user.id, sourceEmergencyEventId: recId },
      });
      if (!existingRec) {
        const url = String(row.recording_url);
        const hash = createHash("sha512")
          .update(`rec|${mongoId}|${url}`)
          .digest("hex");
        await prisma.evidence.create({
          data: {
            title: `SOS · הקלטה · ${when}`,
            fileUrl: url,
            fileHash: hash,
            category: "sos_recording",
            ownerId: user.id,
            sourceEmergencyEventId: recId,
          },
        });
        added += 1;
      }
    }

    if (hasTr) {
      const trId = `${mongoId}:transcript`;
      const existingTr = await prisma.evidence.findFirst({
        where: { ownerId: user.id, sourceEmergencyEventId: trId },
      });
      if (!existingTr) {
        const text = String(row.call_transcript);
        const enc = encodeURIComponent(text);
        const dataUrl = `data:text/plain;charset=utf-8,${enc}`;
        const hash = createHash("sha512")
          .update(`tr|${mongoId}|${text.slice(0, 2000)}`)
          .digest("hex");
        await prisma.evidence.create({
          data: {
            title: `SOS · תמלול · ${when}`,
            fileUrl: dataUrl,
            fileHash: hash,
            category: "sos_transcript",
            ownerId: user.id,
            sourceEmergencyEventId: trId,
          },
        });
        added += 1;
      }
    }
  }

  if (added > 0) {
    revalidatePath("/vault");
  }
  return { success: true, added };
}

export async function deleteEvidence(
  evidenceId: string,
): Promise<{ success: true } | { success: false; error: string }> {
  const externalId = await getVetoUserIdFromCookies();
  if (!externalId) {
    return { success: false, error: "נדרשת התחברות" };
  }

  const user = await prisma.user.findUnique({ where: { externalId } });
  if (!user) {
    return { success: false, error: "משתמש לא נמצא" };
  }

  try {
    const row = await prisma.evidence.findFirst({
      where: { id: evidenceId, ownerId: user.id },
    });
    if (!row) {
      return { success: false, error: "הפריט לא נמצא או שאינו שלך" };
    }

    const legacyBase = process.env.LEGACY_API_URL?.replace(/\/$/, "") ?? "";
    const { fileUrl } = row;
    const isRemoteBinary =
      fileUrl.startsWith("http://") || fileUrl.startsWith("https://");

    if (legacyBase && isRemoteBinary) {
      const res = await fetch(`${legacyBase}/delete-file`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ fileUrl }),
      });
      if (!res.ok) {
        const detail = await res.text().catch(() => "");
        return {
          success: false,
          error: `מחיקה בשרת האחסון נכשלה (${res.status})${detail ? `: ${detail.slice(0, 160)}` : ""}`,
        };
      }
    }

    await prisma.evidence.delete({ where: { id: row.id } });
    revalidatePath("/vault");
    return { success: true };
  } catch (error) {
    console.error("deleteEvidence:", error);
    return { success: false, error: "מחיקה נכשלה" };
  }
}
