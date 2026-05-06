"use server";

import { revalidatePath } from "next/cache";
import type { Role } from "@prisma/client";
import { prisma } from "@/lib/prisma";
import {
  getVetoRoleFromCookies,
  getVetoUserIdFromCookies,
} from "@/lib/jwtCookie";

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
}

export async function saveEvidence(data: {
  title: string;
  url: string;
  hash: string;
  category: string;
  isVerified?: boolean;
  digitalSeal?: string | null;
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
      },
    });
    revalidatePath("/vault");
    return { success: true, id: evidence.id };
  } catch (error) {
    console.error("saveEvidence:", error);
    return { success: false, error: "שגיאה בשמירה לכספת" };
  }
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
