import { apiUrl, authJsonHeaders } from "@/api/apiClient";

const BASE = "/api/citizen-dashboard";

/** Matches `CitizenContract.status` enum in the backend. */
export type ApiCitizenContractStatus =
  | "draft"
  | "active"
  | "closed"
  | "at_risk";

export type ApiCitizenContract = {
  _id: string;
  title: string;
  counterparty?: string;
  status: ApiCitizenContractStatus;
  notes?: string;
  vaultFileIds?: string[];
  startDate?: string;
  endDate?: string;
  createdAt?: string;
  updatedAt?: string;
};

export type CreateCitizenContractPayload = {
  title: string;
  counterparty: string;
  status?: ApiCitizenContractStatus;
  notes?: string;
  vaultFileIds?: string[];
  startDate?: string;
  endDate?: string;
};

/** Matches `CitizenTask.status` enum. */
export type ApiCitizenTaskStatus = "open" | "done";

export type ApiCitizenTask = {
  _id: string;
  title: string;
  description?: string;
  dueAt?: string | null;
  status: ApiCitizenTaskStatus;
  relatedType?: string;
  relatedId?: string;
  createdAt?: string;
  updatedAt?: string;
};

export type CreateCitizenTaskPayload = {
  title: string;
  description?: string;
  /** ISO date string or YYYY-MM-DD (serialized as JSON). */
  dueAt?: string | null;
  status?: ApiCitizenTaskStatus;
  relatedType?: string;
  relatedId?: string;
};

async function readErrorMessage(res: Response): Promise<string> {
  try {
    const data = (await res.json()) as { error?: unknown; message?: unknown };
    if (typeof data.error === "string") return data.error;
    if (typeof data.message === "string") return data.message;
  } catch {
    /* ignore */
  }
  return `Request failed (${res.status})`;
}

/**
 * GET /api/citizen-dashboard/tasks — returns a JSON array of tasks.
 */
export async function fetchTasks(): Promise<ApiCitizenTask[]> {
  const res = await fetch(apiUrl(`${BASE}/tasks`), {
    method: "GET",
    headers: authJsonHeaders(),
  });
  if (!res.ok) {
    throw new Error(await readErrorMessage(res));
  }
  const data: unknown = await res.json();
  if (!Array.isArray(data)) {
    throw new Error("Invalid response: expected tasks array");
  }
  return data as ApiCitizenTask[];
}

/**
 * POST /api/citizen-dashboard/tasks
 */
export async function createTask(
  payload: CreateCitizenTaskPayload,
): Promise<ApiCitizenTask> {
  const res = await fetch(apiUrl(`${BASE}/tasks`), {
    method: "POST",
    headers: authJsonHeaders(),
    body: JSON.stringify(payload),
  });
  if (!res.ok) {
    throw new Error(await readErrorMessage(res));
  }
  return (await res.json()) as ApiCitizenTask;
}

/**
 * PATCH /api/citizen-dashboard/tasks/:taskId — backend merges `status` (and other fields).
 */
export async function updateTaskStatus(
  taskId: string,
  isDone: boolean,
): Promise<ApiCitizenTask> {
  const res = await fetch(
    apiUrl(`${BASE}/tasks/${encodeURIComponent(taskId)}`),
    {
      method: "PATCH",
      headers: authJsonHeaders(),
      body: JSON.stringify({ status: isDone ? "done" : "open" }),
    },
  );
  if (!res.ok) {
    throw new Error(await readErrorMessage(res));
  }
  return (await res.json()) as ApiCitizenTask;
}

/**
 * GET /api/citizen-dashboard/contracts — returns a JSON array of contracts.
 */
export async function fetchContracts(): Promise<ApiCitizenContract[]> {
  const res = await fetch(apiUrl(`${BASE}/contracts`), {
    method: "GET",
    headers: authJsonHeaders(),
  });
  if (!res.ok) {
    throw new Error(await readErrorMessage(res));
  }
  const data: unknown = await res.json();
  if (!Array.isArray(data)) {
    throw new Error("Invalid response: expected contracts array");
  }
  return data as ApiCitizenContract[];
}

/**
 * POST /api/citizen-dashboard/contracts
 */
export async function createContract(
  payload: CreateCitizenContractPayload,
): Promise<ApiCitizenContract> {
  const res = await fetch(apiUrl(`${BASE}/contracts`), {
    method: "POST",
    headers: authJsonHeaders(),
    body: JSON.stringify(payload),
  });
  if (!res.ok) {
    throw new Error(await readErrorMessage(res));
  }
  return (await res.json()) as ApiCitizenContract;
}

/**
 * PATCH /api/citizen-dashboard/contracts/:contractId
 */
export async function patchContract(
  contractId: string,
  patch: Partial<{
    title: string;
    counterparty: string;
    status: ApiCitizenContractStatus;
    notes: string;
    vaultFileIds: string[];
    startDate: string;
    endDate: string;
  }>,
): Promise<ApiCitizenContract> {
  const res = await fetch(
    apiUrl(`${BASE}/contracts/${encodeURIComponent(contractId)}`),
    {
      method: "PATCH",
      headers: authJsonHeaders(),
      body: JSON.stringify(patch),
    },
  );
  if (!res.ok) {
    throw new Error(await readErrorMessage(res));
  }
  return (await res.json()) as ApiCitizenContract;
}

/**
 * “Sign” = activate contract. Backend has no `/sign` route; draft → active via PATCH.
 */
export async function signContract(contractId: string): Promise<ApiCitizenContract> {
  return patchContract(contractId, { status: "active" });
}

/** Encode UI priority in `relatedType` (no dedicated field on CitizenTask). */
export function priorityRelatedType(
  priority: "high" | "medium" | "low",
): string {
  return `pri:${priority}`;
}

export function parsePriorityFromRelatedType(
  relatedType: string | undefined,
): "high" | "medium" | "low" {
  const m = relatedType?.match(/^pri:(high|medium|low)$/);
  if (m?.[1] === "high" || m?.[1] === "medium" || m?.[1] === "low") {
    return m[1];
  }
  return "medium";
}
