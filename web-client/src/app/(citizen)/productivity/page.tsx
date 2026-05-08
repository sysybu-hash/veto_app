"use client";

import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import {
  createContract,
  fetchContracts,
  fetchTasks,
  signContract as requestSignContract,
  updateTaskStatus,
  type ApiCitizenContract,
  type ApiCitizenContractStatus,
  type ApiCitizenTask,
  parsePriorityFromRelatedType,
} from "@/api/productivityApi";
import { getJwt } from "@/lib/authToken";
import { useTranslation } from "@/lib/i18n/LocaleProvider";
import { CitizenBottomNav } from "@/components/citizen/CitizenBottomNav";
import { CreateTaskModal } from "@/components/productivity/CreateTaskModal";
import {
  btnPrimaryDark,
  btnPrimaryGold,
  btnSecondaryGlass,
  glassInput,
  glassPanel,
  glassPanelNested,
} from "@/lib/vetoGlass";

/** UI contract status — maps to backend `CitizenContract.status`. */
type ContractStatus = "pending_signature" | "active" | "expired" | "at_risk";

type Contract = {
  id: string;
  title: string;
  partyName: string;
  status: ContractStatus;
  updatedAt: string;
};

type TaskPriority = "high" | "medium" | "low";

type Task = {
  id: string;
  title: string;
  description: string;
  dueDate: string;
  priority: TaskPriority;
  done: boolean;
};

function contractStatusLabel(
  status: ContractStatus,
  tr: (key: string) => string,
): string {
  switch (status) {
    case "pending_signature":
      return tr("productivity.statusPendingSignature");
    case "active":
      return tr("productivity.statusActive");
    case "expired":
      return tr("productivity.statusExpired");
    case "at_risk":
      return tr("productivity.statusAtRisk");
    default:
      return tr("productivity.statusActive");
  }
}

function taskPriorityLabel(
  p: TaskPriority,
  tr: (key: string) => string,
): string {
  switch (p) {
    case "high":
      return tr("productivity.priorityHigh");
    case "medium":
      return tr("productivity.priorityMedium");
    case "low":
      return tr("productivity.priorityLow");
    default:
      return p;
  }
}

function apiStatusToUi(s: ApiCitizenContractStatus): ContractStatus {
  switch (s) {
    case "draft":
      return "pending_signature";
    case "active":
      return "active";
    case "closed":
      return "expired";
    case "at_risk":
      return "at_risk";
    default:
      return "active";
  }
}

function uiStatusToApi(s: ContractStatus): ApiCitizenContractStatus {
  switch (s) {
    case "pending_signature":
      return "draft";
    case "active":
      return "active";
    case "expired":
      return "closed";
    case "at_risk":
      return "at_risk";
    default:
      return "active";
  }
}

function formatApiDate(iso?: string): string {
  if (!iso) return new Date().toISOString().slice(0, 10);
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return iso.slice(0, 10);
  return d.toISOString().slice(0, 10);
}

function mapApiContract(row: ApiCitizenContract): Contract {
  return {
    id: String(row._id),
    title: row.title,
    partyName: row.counterparty ?? "",
    status: apiStatusToUi(row.status),
    updatedAt: formatApiDate(row.updatedAt),
  };
}

function dueAtToInputDate(dueAt?: string | null): string {
  if (dueAt == null || dueAt === "") return "";
  const d = new Date(dueAt);
  if (Number.isNaN(d.getTime())) return "";
  return d.toISOString().slice(0, 10);
}

function mapApiTask(row: ApiCitizenTask): Task {
  return {
    id: String(row._id),
    title: row.title,
    description: row.description ?? "",
    dueDate: dueAtToInputDate(row.dueAt),
    priority: parsePriorityFromRelatedType(row.relatedType),
    done: row.status === "done",
  };
}

function statusStyles(status: ContractStatus): string {
  switch (status) {
    case "pending_signature":
      return "bg-amber-400/20 text-amber-900 ring-amber-400/50";
    case "active":
      return "bg-emerald-400/20 text-emerald-900 ring-emerald-400/50";
    case "expired":
      return "bg-white/40 text-slate-700 ring-white/50";
    case "at_risk":
      return "bg-orange-400/20 text-orange-950 ring-orange-400/50";
    default:
      return "bg-white/35 text-slate-800 ring-white/45";
  }
}

function priorityStyles(p: TaskPriority): string {
  switch (p) {
    case "high":
      return "bg-red-400/20 text-red-900 ring-red-400/45";
    case "medium":
      return "bg-amber-400/20 text-amber-900 ring-amber-400/45";
    case "low":
      return "bg-white/40 text-slate-700 ring-white/50";
    default:
      return "bg-white/35 text-slate-800 ring-white/45";
  }
}

type ContractFormPayload = {
  title: string;
  partyName: string;
  status: ContractStatus;
};

function CreateContractModal({
  open,
  onClose,
  onSave,
}: {
  open: boolean;
  onClose: () => void;
  onSave: (c: ContractFormPayload) => Promise<void>;
}) {
  const { t } = useTranslation();
  const [title, setTitle] = useState("");
  const [partyName, setPartyName] = useState("");
  const [status, setStatus] = useState<ContractStatus>("pending_signature");
  const [saving, setSaving] = useState(false);
  const [saveErr, setSaveErr] = useState<string | null>(null);
  const titleRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (!open) return;
    queueMicrotask(() => {
      setTitle("");
      setPartyName("");
      setStatus("pending_signature");
      setSaveErr(null);
      setSaving(false);
      queueMicrotask(() => titleRef.current?.focus());
    });
  }, [open]);

  if (!open) return null;

  const save = async () => {
    const titleTrimmed = title.trim();
    const partyTrimmed = partyName.trim();
    if (!titleTrimmed || !partyTrimmed || saving) return;
    setSaveErr(null);
    setSaving(true);
    try {
      await onSave({
        title: titleTrimmed,
        partyName: partyTrimmed,
        status,
      });
      onClose();
    } catch (e) {
      setSaveErr(
        e instanceof Error ? e.message : t("productivity.saveContractFailed"),
      );
    } finally {
      setSaving(false);
    }
  };

  return (
    <div
      className="fixed inset-0 z-[60] flex items-end justify-center bg-slate-900/50 p-4 sm:items-center"
      role="presentation"
      onMouseDown={(e) => {
        if (e.target === e.currentTarget && !saving) onClose();
      }}
    >
      <div
        className={`w-full max-w-lg overflow-hidden shadow-2xl shadow-slate-900/20 ${glassPanel}`}
        role="dialog"
        aria-modal="true"
        aria-labelledby="contract-modal-title"
        onMouseDown={(e) => e.stopPropagation()}
      >
        <div className="border-b border-white/40 px-5 py-4 backdrop-blur-sm">
          <h2
            id="contract-modal-title"
            className="font-frank text-lg font-bold text-slate-900"
          >
            {t("productivity.modalContractTitle")}
          </h2>
          <p className="mt-0.5 text-sm text-slate-600">
            {t("productivity.modalContractSubtitle")}
          </p>
        </div>
        <div className="space-y-4 px-5 py-4">
          <div>
            <label
              htmlFor="c-title"
              className="mb-1.5 block text-xs font-semibold uppercase tracking-wide text-slate-600"
            >
              {t("productivity.contractTitleField")}
            </label>
            <input
              ref={titleRef}
              id="c-title"
              value={title}
              disabled={saving}
              onChange={(e) => setTitle(e.target.value)}
              className={glassInput}
            />
          </div>
          <div>
            <label
              htmlFor="c-party"
              className="mb-1.5 block text-xs font-semibold uppercase tracking-wide text-slate-600"
            >
              {t("productivity.partyNameField")}
            </label>
            <input
              id="c-party"
              value={partyName}
              disabled={saving}
              onChange={(e) => setPartyName(e.target.value)}
              className={glassInput}
              placeholder={t("productivity.partyNamePlaceholder")}
            />
          </div>
          <div>
            <label
              htmlFor="c-status"
              className="mb-1.5 block text-xs font-semibold uppercase tracking-wide text-slate-600"
            >
              {t("productivity.contractStatusField")}
            </label>
            <select
              id="c-status"
              value={status}
              disabled={saving}
              onChange={(e) => setStatus(e.target.value as ContractStatus)}
              className={glassInput}
            >
              <option value="pending_signature">
                {t("productivity.statusPendingSignature")}
              </option>
              <option value="active">{t("productivity.statusActive")}</option>
              <option value="expired">{t("productivity.statusExpired")}</option>
              <option value="at_risk">{t("productivity.statusAtRisk")}</option>
            </select>
          </div>
          {saveErr && (
            <p
              className="rounded-xl border border-red-300/70 bg-red-100/50 px-3 py-2 text-sm text-red-900 backdrop-blur-sm"
              role="alert"
            >
              {saveErr}
            </p>
          )}
        </div>
        <div className="flex gap-3 border-t border-white/40 px-5 py-4">
          <button
            type="button"
            onClick={() => !saving && onClose()}
            disabled={saving}
            className={`flex-1 py-3 text-sm ${btnSecondaryGlass} disabled:cursor-not-allowed disabled:opacity-50`}
          >
            {t("common.cancel")}
          </button>
          <button
            type="button"
            onClick={() => void save()}
            disabled={!title.trim() || !partyName.trim() || saving}
            className={`flex-1 py-3 text-sm ${btnPrimaryGold} disabled:cursor-not-allowed disabled:opacity-50`}
          >
            {saving ? t("settings.saving") : t("productivity.saveContract")}
          </button>
        </div>
      </div>
    </div>
  );
}

function ContractViewModal({
  contract,
  onClose,
}: {
  contract: Contract | null;
  onClose: () => void;
}) {
  const { t } = useTranslation();
  if (!contract) return null;
  return (
    <div
      className="fixed inset-0 z-[60] flex items-end justify-center bg-slate-900/50 p-4 sm:items-center"
      onMouseDown={(e) => {
        if (e.target === e.currentTarget) onClose();
      }}
    >
      <div
        className={`w-full max-w-md p-6 shadow-2xl shadow-slate-900/20 ${glassPanel}`}
        onMouseDown={(e) => e.stopPropagation()}
        role="dialog"
        aria-modal="true"
        aria-labelledby="view-contract-title"
      >
        <h2
          id="view-contract-title"
          className="font-frank text-lg font-bold text-slate-900"
        >
          {contract.title}
        </h2>
        <div className={`mt-4 rounded-xl border border-white/40 p-4 ${glassPanelNested}`}>
          <p className="text-sm text-slate-700">
            {t("productivity.labelParty")}: {contract.partyName}
          </p>
          <p className="mt-2 text-sm text-slate-700">
            {t("productivity.labelStatus")}:{" "}
            {contractStatusLabel(contract.status, t)}
          </p>
          <p className="mt-2 text-xs text-slate-600">
            {t("productivity.viewLastUpdated")} {contract.updatedAt}
          </p>
        </div>
        <button
          type="button"
          onClick={onClose}
          className={`mt-6 w-full py-3 text-sm ${btnPrimaryDark}`}
        >
          {t("common.close")}
        </button>
      </div>
    </div>
  );
}

function ProductivityLoadingSkeleton() {
  const { t } = useTranslation();
  return (
    <div
      className="animate-pulse space-y-4 p-4 sm:p-6"
      aria-busy="true"
      aria-label={t("productivity.loadingAria")}
    >
      <div className="grid gap-4 sm:grid-cols-2">
        {[1, 2, 3, 4].map((i) => (
          <div
            key={i}
            className="h-36 rounded-xl border border-white/30 bg-white/35 backdrop-blur-md"
          />
        ))}
      </div>
    </div>
  );
}

export default function ProductivityPage() {
  const { t } = useTranslation();
  const router = useRouter();
  const [tab, setTab] = useState<"contracts" | "tasks">("contracts");
  const [contracts, setContracts] = useState<Contract[]>([]);
  const [tasks, setTasks] = useState<Task[]>([]);
  const [contractModalOpen, setContractModalOpen] = useState(false);
  const [taskModalOpen, setTaskModalOpen] = useState(false);
  const [viewContract, setViewContract] = useState<Contract | null>(null);
  const [menuOpenId, setMenuOpenId] = useState<string | null>(null);
  const menuRef = useRef<HTMLDivElement>(null);

  const [isLoading, setIsLoading] = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [actionError, setActionError] = useState<string | null>(null);
  const [updatingTaskId, setUpdatingTaskId] = useState<string | null>(null);
  const [signingContractId, setSigningContractId] = useState<string | null>(
    null,
  );

  const loadData = useCallback(async () => {
    if (!getJwt()) return;
    setIsLoading(true);
    setLoadError(null);
    try {
      const [apiContracts, apiTasks] = await Promise.all([
        fetchContracts(),
        fetchTasks(),
      ]);
      setContracts(apiContracts.map(mapApiContract));
      setTasks(apiTasks.map(mapApiTask));
    } catch (e) {
      const raw =
        e instanceof Error ? e.message : t("productivity.loadFailed");
      let msg = raw;
      if (/unauthorized/i.test(raw) || /invalid value for user_id/i.test(raw)) {
        msg = t("productivity.errAuth");
      } else if (/forbidden/i.test(raw)) {
        msg = t("productivity.errForbidden");
      }
      setLoadError(msg);
      setContracts([]);
      setTasks([]);
    } finally {
      setIsLoading(false);
    }
  }, [t]);

  useEffect(() => {
    if (!getJwt()) {
      router.replace("/login");
      return;
    }
    queueMicrotask(() => {
      void loadData();
    });
  }, [router, loadData]);

  useEffect(() => {
    const onDoc = (e: MouseEvent) => {
      if (!menuRef.current?.contains(e.target as Node)) {
        setMenuOpenId(null);
      }
    };
    document.addEventListener("click", onDoc);
    return () => document.removeEventListener("click", onDoc);
  }, []);

  const sortedContracts = useMemo(
    () =>
      [...contracts].sort((a, b) =>
        a.title.localeCompare(b.title, undefined, { sensitivity: "base" }),
      ),
    [contracts],
  );

  const sortedTasks = useMemo(() => {
    const prioOrder: Record<TaskPriority, number> = {
      high: 0,
      medium: 1,
      low: 2,
    };
    return [...tasks].sort((a, b) => {
      if (a.done !== b.done) return a.done ? 1 : -1;
      const pd = (a.dueDate || "").localeCompare(b.dueDate || "");
      if (pd !== 0) return pd;
      return prioOrder[a.priority] - prioOrder[b.priority];
    });
  }, [tasks]);

  const handleNewClick = () => {
    if (tab === "contracts") setContractModalOpen(true);
    else setTaskModalOpen(true);
  };

  const saveNewContract = async (payload: ContractFormPayload) => {
    await createContract({
      title: payload.title,
      counterparty: payload.partyName,
      status: uiStatusToApi(payload.status),
    });
    await loadData();
  };

  const signContract = async (id: string) => {
    setActionError(null);
    setSigningContractId(id);
    try {
      await requestSignContract(id);
      await loadData();
      setMenuOpenId(null);
    } catch (e) {
      setActionError(
        e instanceof Error ? e.message : t("productivity.signFailed"),
      );
    } finally {
      setSigningContractId(null);
    }
  };

  const toggleTaskDone = async (id: string) => {
    const row = tasks.find((x) => x.id === id);
    if (!row || updatingTaskId) return;
    const nextDone = !row.done;
    setActionError(null);
    setUpdatingTaskId(id);
    try {
      const updated = await updateTaskStatus(id, nextDone);
      setTasks((prev) =>
        prev.map((r) =>
          r.id === id ? mapApiTask(updated) : r,
        ),
      );
    } catch (e) {
      setActionError(
        e instanceof Error ? e.message : t("productivity.updateTaskFailed"),
      );
    } finally {
      setUpdatingTaskId(null);
    }
  };

  return (
    <div className="mx-auto min-h-0 w-full max-w-4xl flex-1 px-4 pb-28 pt-6 md:px-6">
      <div className={`overflow-hidden ${glassPanel}`}>
        <div className="border-b border-white/40 bg-white/35 px-4 py-4 backdrop-blur-md sm:flex sm:items-center sm:justify-between sm:px-6">
          <div className="mb-4 sm:mb-0">
            <p className="text-xs font-semibold uppercase tracking-wider text-[#8a6d3d]">
              {t("productivity.heroEyebrow")}
            </p>
            <h1 className="font-frank mt-1 text-xl font-bold tracking-tight text-slate-900 sm:text-2xl">
              {t("productivity.heroTitle")}
            </h1>
            <p className="mt-1 text-sm text-slate-600">
              {t("productivity.heroSubtitle")}
            </p>
          </div>
          <button
            type="button"
            onClick={handleNewClick}
            disabled={isLoading || !!loadError}
            className={`w-full px-4 py-3 text-sm disabled:cursor-not-allowed disabled:opacity-50 sm:w-auto ${btnPrimaryGold}`}
          >
            {tab === "contracts"
              ? t("productivity.newContract")
              : t("productivity.newTask")}
          </button>
        </div>

        <div className="border-b border-white/40 px-4 sm:px-6">
          <div className="flex gap-0">
            <button
              type="button"
              onClick={() => setTab("contracts")}
              className={`relative flex-1 border-b-2 py-3 text-sm font-semibold transition sm:flex-none sm:px-6 ${
                tab === "contracts"
                  ? "border-[#C5A059] text-slate-900 shadow-[0_2px_12px_rgba(197,160,89,0.25)]"
                  : "border-transparent text-slate-600 hover:text-slate-900"
              }`}
            >
              {t("productivity.tabContracts")}
            </button>
            <button
              type="button"
              onClick={() => setTab("tasks")}
              className={`relative flex-1 border-b-2 py-3 text-sm font-semibold transition sm:flex-none sm:px-6 ${
                tab === "tasks"
                  ? "border-[#C5A059] text-slate-900 shadow-[0_2px_12px_rgba(197,160,89,0.25)]"
                  : "border-transparent text-slate-600 hover:text-slate-900"
              }`}
            >
              {t("productivity.tabTasks")}
            </button>
          </div>
        </div>

        {isLoading && <ProductivityLoadingSkeleton />}

        {!isLoading && loadError && (
          <div
            className="m-4 flex flex-col gap-3 rounded-xl border border-red-300/70 bg-white/45 px-4 py-4 text-sm text-red-900 backdrop-blur-xl sm:m-6 sm:flex-row sm:items-center sm:justify-between"
            role="alert"
          >
            <p>{loadError}</p>
            <button
              type="button"
              onClick={() => void loadData()}
              className="shrink-0 rounded-lg bg-red-800 px-4 py-2 text-sm font-semibold text-white hover:bg-red-700"
            >
              {t("common.retry")}
            </button>
          </div>
        )}

        {!isLoading && !loadError && (
          <div className="p-4 sm:p-6">
            {actionError && (
              <div
                className="mb-4 rounded-xl border border-amber-300/70 bg-white/45 px-4 py-3 text-sm text-amber-950 backdrop-blur-xl"
                role="status"
              >
                {actionError}
              </div>
            )}
            {tab === "contracts" && (
              <div className="grid gap-4 sm:grid-cols-2">
                {sortedContracts.length === 0 && (
                  <p className="col-span-full py-10 text-center text-sm text-slate-600">
                    {t("productivity.contractEmpty")}
                  </p>
                )}
                {sortedContracts.map((c) => (
                  <article
                    key={c.id}
                    className={`flex flex-col rounded-xl border border-white/50 p-4 shadow-sm backdrop-blur-xl transition hover:border-white hover:shadow-md ${glassPanelNested}`}
                  >
                    <div className="flex items-start justify-between gap-2">
                      <div className="min-w-0">
                        <h3 className="font-frank font-bold text-slate-900">{c.title}</h3>
                        <p className="mt-1 text-sm text-slate-600">{c.partyName}</p>
                      </div>
                      <span
                        className={`shrink-0 rounded-full px-2.5 py-0.5 text-xs font-medium ring-1 ring-inset backdrop-blur-sm ${statusStyles(c.status)}`}
                      >
                        {contractStatusLabel(c.status, t)}
                      </span>
                    </div>
                    <p className="mt-3 text-xs text-slate-500">
                      {t("productivity.updatedPrefix")} {c.updatedAt}
                    </p>
                    <div
                      className="relative mt-4"
                      ref={menuOpenId === c.id ? menuRef : undefined}
                    >
                      <button
                        type="button"
                        onClick={(e) => {
                          e.stopPropagation();
                          setMenuOpenId((id) => (id === c.id ? null : c.id));
                        }}
                        className={`flex w-full items-center justify-center gap-2 py-2 text-sm font-medium ${btnSecondaryGlass}`}
                      >
                        {t("productivity.actions")}
                        <svg
                          className="h-4 w-4"
                          fill="none"
                          stroke="currentColor"
                          strokeWidth={2}
                          viewBox="0 0 24 24"
                        >
                          <path d="M19 9l-7 7-7-7" />
                        </svg>
                      </button>
                      {menuOpenId === c.id && (
                        <div className="absolute inset-x-0 z-10 mt-1 overflow-hidden rounded-xl border border-white/40 bg-white/55 py-1 shadow-lg backdrop-blur-xl">
                          <button
                            type="button"
                            className="block w-full px-4 py-2.5 text-start text-sm text-slate-800 hover:bg-white/50"
                            onClick={() => {
                              setViewContract(c);
                              setMenuOpenId(null);
                            }}
                          >
                            {t("productivity.view")}
                          </button>
                          <button
                            type="button"
                            className="block w-full px-4 py-2.5 text-start text-sm font-semibold text-[#8a6d3d] hover:bg-[#C5A059]/15 disabled:cursor-not-allowed disabled:opacity-40"
                            disabled={
                              c.status !== "pending_signature" ||
                              signingContractId === c.id
                            }
                            onClick={() => void signContract(c.id)}
                          >
                            {signingContractId === c.id
                              ? t("productivity.signing")
                              : t("productivity.sign")}
                          </button>
                        </div>
                      )}
                    </div>
                  </article>
                ))}
              </div>
            )}

            {tab === "tasks" && (
              <ul className="divide-y divide-white/30 overflow-hidden rounded-2xl border border-white/40 bg-white/45 backdrop-blur-xl">
                {sortedTasks.length === 0 && (
                  <li className="px-4 py-10 text-center text-sm text-slate-600">
                    {t("productivity.tasksEmpty")}
                  </li>
                )}
                {sortedTasks.map((task) => (
                  <li
                    key={task.id}
                    className={`flex flex-col gap-3 p-4 transition sm:flex-row sm:items-center sm:gap-4 ${
                      task.done ? "bg-white/35" : "bg-white/20"
                    }`}
                  >
                    <label className="flex flex-1 cursor-pointer items-start gap-3">
                      <input
                        type="checkbox"
                        checked={task.done}
                        disabled={updatingTaskId === task.id}
                        onChange={() => void toggleTaskDone(task.id)}
                        className="mt-1 h-4 w-4 shrink-0 rounded border-slate-400 text-[#C5A059] focus:ring-[#C5A059]/40 disabled:cursor-wait disabled:opacity-50"
                      />
                      <span className="min-w-0">
                        <span
                          className={`block font-medium text-slate-900 ${
                            task.done ? "text-slate-500 line-through" : ""
                          }`}
                        >
                          {task.title}
                        </span>
                        {task.description && (
                          <span className="mt-0.5 block text-sm text-slate-600">
                            {task.description}
                          </span>
                        )}
                      </span>
                    </label>
                    <div className="flex shrink-0 flex-wrap items-center gap-2 sm:flex-col sm:items-end">
                      <span
                        className={`rounded-full px-2.5 py-0.5 text-xs font-medium ring-1 ring-inset backdrop-blur-sm ${priorityStyles(task.priority)}`}
                      >
                        {taskPriorityLabel(task.priority, t)}
                      </span>
                      <span className="text-xs font-medium text-slate-600">
                        {t("productivity.duePrefix")}{" "}
                        {task.dueDate || "—"}
                      </span>
                    </div>
                  </li>
                ))}
              </ul>
            )}
          </div>
        )}
      </div>

      <p className="mt-4 text-center text-xs text-slate-600">
        {t("productivity.vaultHint")}{" "}
        <Link href="/vault" className="font-semibold text-[#8a6d3d] hover:text-slate-900">
          {t("productivity.vaultLink")}
        </Link>
      </p>

      <CreateContractModal
        open={contractModalOpen}
        onClose={() => setContractModalOpen(false)}
        onSave={saveNewContract}
      />
      <CreateTaskModal
        open={taskModalOpen}
        onClose={() => setTaskModalOpen(false)}
        onTaskCreated={() => void loadData()}
      />
      <ContractViewModal
        contract={viewContract}
        onClose={() => setViewContract(null)}
      />

      <CitizenBottomNav active="productivity" />
    </div>
  );
}
