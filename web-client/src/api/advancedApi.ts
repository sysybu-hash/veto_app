import { apiUrl, authFetch } from "@/api/apiClient";

async function parseJsonError(res: Response): Promise<string> {
  try {
    const data = (await res.json()) as { error?: string; message?: string };
    return data.error || data.message || res.statusText;
  } catch {
    return res.statusText;
  }
}

export type TransparencyLog = {
  _id: string;
  action: string;
  source: string;
  model?: string | null;
  produced_output: boolean;
  used_fallback: boolean;
  requires_lawyer_review: boolean;
  createdAt: string;
};

export async function fetchTransparencyLogs(): Promise<TransparencyLog[]> {
  const res = await authFetch(apiUrl("/api/ai/transparency-log"), { method: "GET" });
  if (!res.ok) throw new Error(await parseJsonError(res));
  const data = (await res.json()) as { logs?: TransparencyLog[] };
  return data.logs ?? [];
}

export type Entitlement = {
  allowed: boolean;
  status: string;
  reason: string;
  nextAction: string;
  planId?: string | null;
  subscriptionExpiry?: string | null;
  pendingOvertime?: number;
  paymentExempt?: boolean;
  consultationExempt?: boolean;
};

export async function fetchEntitlement(): Promise<Entitlement> {
  const res = await authFetch("/api/users/entitlement", { method: "GET" });
  if (!res.ok) throw new Error(await parseJsonError(res));
  return (await res.json()) as Entitlement;
}

export type TimelineItem = {
  id: string;
  type: "sos" | "document";
  title: string;
  at: string;
  status?: string;
  caseId?: string | null;
  hasRecording?: boolean;
  hasTranscript?: boolean;
  sharedWithLawyer?: boolean;
  mimeType?: string;
  metadata?: Record<string, unknown>;
};

export async function fetchVaultTimeline(): Promise<TimelineItem[]> {
  const res = await authFetch(apiUrl("/api/vault/timeline"), { method: "GET" });
  if (!res.ok) throw new Error(await parseJsonError(res));
  const data = (await res.json()) as { items?: TimelineItem[] };
  return data.items ?? [];
}

export type PrivacyRequest = {
  _id: string;
  type: "export" | "delete" | "correct";
  status: string;
  note?: string;
  createdAt: string;
};

export async function fetchPrivacyRequests(): Promise<PrivacyRequest[]> {
  const res = await authFetch(apiUrl("/api/users/privacy-requests"), { method: "GET" });
  if (!res.ok) throw new Error(await parseJsonError(res));
  const data = (await res.json()) as { requests?: PrivacyRequest[] };
  return data.requests ?? [];
}

export async function createPrivacyRequest(type: PrivacyRequest["type"], note = ""): Promise<void> {
  const res = await authFetch(apiUrl("/api/users/privacy-requests"), {
    method: "POST",
    body: JSON.stringify({ type, note }),
  });
  if (!res.ok) throw new Error(await parseJsonError(res));
}

export type LawyerCockpit = {
  lawyer: {
    full_name?: string;
    is_available?: boolean;
    is_online?: boolean;
    is_approved?: boolean;
    specializations?: string[];
    languages_spoken?: string[];
    total_cases_handled?: number;
    trust?: Record<string, unknown>;
  };
  status: {
    busy: boolean;
    activeEventId?: string | null;
    handledCount: number;
    avgResponseSeconds?: number | null;
  };
  recentEvents: Array<{
    id: string;
    status: string;
    callType?: string;
    triggeredAt?: string;
    citizen?: { name?: string; phone?: string; language?: string } | null;
    hasTranscript: boolean;
    hasRecording: boolean;
    chargeStatus?: string;
  }>;
};

export async function fetchLawyerCockpit(): Promise<LawyerCockpit> {
  const res = await authFetch(apiUrl("/api/lawyers/cockpit"), { method: "GET" });
  if (!res.ok) throw new Error(await parseJsonError(res));
  return (await res.json()) as LawyerCockpit;
}

export type ActionPlan = {
  eventId: string;
  minutes: number | null;
  callType?: string;
  charge: { status?: string; amountIls: number; overtimeMinutes: number };
  evidence: { hasRecording: boolean; hasTranscript: boolean; savedDecision?: string };
  ai: { configured: boolean; disclosure: string };
  steps: Array<{ key: string; title: string; action: string }>;
  suggestedDocuments: string[];
};

export async function createActionPlan(eventId: string): Promise<ActionPlan> {
  const res = await authFetch(apiUrl(`/api/calls/${encodeURIComponent(eventId)}/action-plan`), {
    method: "POST",
    body: JSON.stringify({}),
  });
  if (!res.ok) throw new Error(await parseJsonError(res));
  const data = (await res.json()) as { plan?: ActionPlan };
  if (!data.plan) throw new Error("Invalid action plan response");
  return data.plan;
}
