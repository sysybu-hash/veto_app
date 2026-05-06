"use client";

import { useRouter } from "next/navigation";
import { useCallback, useEffect, useMemo, useState } from "react";
import {
  approveLawyer,
  fetchEmergencyEvents,
  fetchPendingLawyers,
  fetchSystemStats,
  rejectLawyer,
  type AdminStats,
  type ApiEmergencyEvent,
  type ApiPendingLawyer,
} from "@/api/adminApi";
import { getJwt, getRoleFromJwt } from "@/lib/authToken";

type PendingLawyer = {
  id: string;
  name: string;
  licenseNumber: string;
  signupDate: string;
};

type LogStatus = "success" | "warning" | "info" | "danger";

type SystemLog = {
  id: string;
  timestamp: string;
  message: string;
  status: LogStatus;
};

function mapPendingLawyer(row: ApiPendingLawyer): PendingLawyer {
  const created = row.createdAt ? new Date(row.createdAt) : new Date();
  const dateLabel = Number.isNaN(created.getTime())
    ? new Date().toISOString().slice(0, 10)
    : created.toISOString().slice(0, 10);
  return {
    id: String(row._id),
    name: row.full_name?.trim() || row.phone || "—",
    licenseNumber: row.license_number?.trim() || "—",
    signupDate: dateLabel,
  };
}

function emergencyStatusToLogStatus(status: string | undefined): LogStatus {
  const s = (status || "").toLowerCase();
  if (s === "completed") return "success";
  if (s === "failed" || s === "cancelled") return "danger";
  if (s === "dispatching") return "warning";
  return "info";
}

function mapEventToLog(ev: ApiEmergencyEvent): SystemLog {
  const u = ev.user_id;
  let label = "User";
  if (u && typeof u === "object") {
    const parts = [u.full_name, u.phone].filter(
      (x): x is string => typeof x === "string" && x.length > 0,
    );
    label = parts.length ? parts.join(" · ") : "User";
  }
  const rawTs = ev.triggered_at ?? ev.createdAt ?? new Date().toISOString();
  const timestamp =
    typeof rawTs === "string" ? rawTs : new Date(rawTs).toISOString();
  return {
    id: String(ev._id),
    timestamp,
    message: `SOS · ${ev.status ?? "unknown"} · ${label}`,
    status: emergencyStatusToLogStatus(ev.status),
  };
}

function statusBadgeClass(status: LogStatus): string {
  switch (status) {
    case "success":
      return "bg-emerald-50 text-emerald-800 ring-emerald-200";
    case "warning":
      return "bg-amber-50 text-amber-900 ring-amber-200";
    case "info":
      return "bg-blue-50 text-blue-800 ring-blue-200";
    case "danger":
      return "bg-red-50 text-red-800 ring-red-200";
    default:
      return "bg-slate-100 text-slate-700 ring-slate-200";
  }
}

function formatTs(iso: string): string {
  try {
    return new Intl.DateTimeFormat("en-IL", {
      dateStyle: "medium",
      timeStyle: "short",
    }).format(new Date(iso));
  } catch {
    return iso;
  }
}

function AdminDashboardSkeleton() {
  return (
    <div className="animate-pulse space-y-8" aria-busy="true" aria-label="Loading dashboard">
      <div className="space-y-2">
        <div className="h-9 w-48 rounded-lg bg-slate-200 sm:w-64" />
        <div className="h-4 w-full max-w-lg rounded-lg bg-slate-200" />
      </div>
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {[1, 2, 3, 4].map((i) => (
          <div
            key={i}
            className="h-28 rounded-2xl border border-slate-100 bg-white p-5 shadow-sm"
          >
            <div className="mb-3 h-3 w-24 rounded bg-slate-200" />
            <div className="h-8 w-20 rounded bg-slate-200" />
            <div className="mt-3 h-3 w-32 rounded bg-slate-100" />
          </div>
        ))}
      </div>
      <div className="h-96 rounded-2xl border border-slate-100 bg-white shadow-sm" />
    </div>
  );
}

const defaultStats: AdminStats = {
  totalUsers: 0,
  activeLawyers: 0,
  pendingLawyers: 0,
  eventsToday: 0,
  eventsWeek: 0,
  eventsMonth: 0,
};

/**
 * Admin dashboard: `/admin/dashboard`. Lawyer workspace stays at `/dashboard`.
 */
export default function AdminDashboardPage() {
  const router = useRouter();
  const [mounted, setMounted] = useState(false);
  const [tab, setTab] = useState<"lawyers" | "logs">("lawyers");
  const [pendingLawyers, setPendingLawyers] = useState<PendingLawyer[]>([]);
  const [logs, setLogs] = useState<SystemLog[]>([]);
  const [stats, setStats] = useState<AdminStats>(defaultStats);

  const [isLoading, setIsLoading] = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [actionError, setActionError] = useState<string | null>(null);
  const [rowBusyId, setRowBusyId] = useState<string | null>(null);

  const loadDashboard = useCallback(async () => {
    if (!getJwt() || getRoleFromJwt() !== "admin") return;
    setIsLoading(true);
    setLoadError(null);
    try {
      const [lawyerRows, statRow, events] = await Promise.all([
        fetchPendingLawyers(),
        fetchSystemStats(),
        fetchEmergencyEvents(),
      ]);
      setPendingLawyers(lawyerRows.map(mapPendingLawyer));
      setStats(statRow);
      const mappedLogs = events.map(mapEventToLog);
      mappedLogs.sort(
        (a, b) =>
          new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime(),
      );
      setLogs(mappedLogs);
    } catch (e) {
      setLoadError(
        e instanceof Error ? e.message : "Could not load admin dashboard",
      );
      setPendingLawyers([]);
      setLogs([]);
      setStats(defaultStats);
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    setMounted(true);
    if (!getJwt()) {
      router.replace("/login");
      return;
    }
    if (getRoleFromJwt() !== "admin") {
      router.replace("/hub");
      return;
    }
    void loadDashboard();
  }, [router, loadDashboard]);

  const displayStats = useMemo(
    () => ({
      totalUsers: stats.totalUsers,
      pendingApprovals: stats.pendingLawyers,
      sosToday: stats.eventsToday,
      activeLawyers: stats.activeLawyers,
    }),
    [stats],
  );

  const approve = async (lawyer: PendingLawyer) => {
    setActionError(null);
    setRowBusyId(lawyer.id);
    try {
      await approveLawyer(lawyer.id);
      await loadDashboard();
    } catch (e) {
      setActionError(
        e instanceof Error ? e.message : "Could not approve lawyer",
      );
    } finally {
      setRowBusyId(null);
    }
  };

  const reject = async (lawyer: PendingLawyer) => {
    setActionError(null);
    setRowBusyId(lawyer.id);
    try {
      await rejectLawyer(lawyer.id);
      await loadDashboard();
    } catch (e) {
      setActionError(
        e instanceof Error ? e.message : "Could not reject lawyer",
      );
    } finally {
      setRowBusyId(null);
    }
  };

  if (!mounted) {
    return (
      <div className="flex flex-1 items-center justify-center p-8 text-sm text-slate-500">
        Loading…
      </div>
    );
  }

  if (!getJwt() || getRoleFromJwt() !== "admin") {
    return null;
  }

  return (
    <main className="mx-auto w-full max-w-7xl flex-1 px-4 py-8 sm:px-6 lg:px-8">
      <div className="mb-8">
        <h1 className="text-2xl font-bold tracking-tight text-slate-900 sm:text-3xl">
          Dashboard
        </h1>
        <p className="mt-1 text-sm text-slate-600 sm:text-base">
          Overview of users, compliance queue, and platform activity.
        </p>
      </div>

      {loadError && (
        <div
          className="mb-6 flex flex-col gap-3 rounded-xl border border-red-200 bg-red-50 px-4 py-4 text-sm text-red-800 sm:flex-row sm:items-center sm:justify-between"
          role="alert"
        >
          <p>{loadError}</p>
          <button
            type="button"
            onClick={() => void loadDashboard()}
            className="shrink-0 rounded-lg bg-red-700 px-4 py-2 text-sm font-semibold text-white hover:bg-red-600"
          >
            Retry
          </button>
        </div>
      )}

      {actionError && !loadError && (
        <div
          className="mb-6 rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-900"
          role="status"
        >
          {actionError}
        </div>
      )}

      {isLoading && !loadError && <AdminDashboardSkeleton />}

      {!isLoading && !loadError && (
        <>
          <section className="mb-10 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <div className="rounded-2xl border border-slate-100 bg-white p-5 shadow-sm shadow-slate-900/5">
              <p className="text-xs font-semibold uppercase tracking-wide text-slate-500">
                Total users
              </p>
              <p className="mt-2 text-2xl font-bold tabular-nums text-slate-900 sm:text-3xl">
                {displayStats.totalUsers.toLocaleString()}
              </p>
              <p className="mt-1 text-xs text-slate-500">
                Registered citizen accounts
              </p>
            </div>
            <div className="rounded-2xl border border-slate-100 bg-white p-5 shadow-sm shadow-slate-900/5">
              <p className="text-xs font-semibold uppercase tracking-wide text-slate-500">
                Pending lawyer approvals
              </p>
              <p className="mt-2 text-2xl font-bold tabular-nums text-amber-600 sm:text-3xl">
                {displayStats.pendingApprovals}
              </p>
              <p className="mt-1 text-xs text-slate-500">Awaiting manual review</p>
            </div>
            <div className="rounded-2xl border border-slate-100 bg-white p-5 shadow-sm shadow-slate-900/5">
              <p className="text-xs font-semibold uppercase tracking-wide text-slate-500">
                SOS events today
              </p>
              <p className="mt-2 text-2xl font-bold tabular-nums text-slate-900 sm:text-3xl">
                {displayStats.sosToday}
              </p>
              <p className="mt-1 text-xs text-slate-500">
                Emergency dispatches (24h)
              </p>
            </div>
            <div className="rounded-2xl border border-slate-100 bg-white p-5 shadow-sm shadow-slate-900/5">
              <p className="text-xs font-semibold uppercase tracking-wide text-slate-500">
                Active lawyers
              </p>
              <p className="mt-2 text-2xl font-bold tabular-nums text-emerald-600 sm:text-3xl">
                {displayStats.activeLawyers}
              </p>
              <p className="mt-1 text-xs text-slate-500">Online &amp; available</p>
            </div>
          </section>

          <section className="overflow-hidden rounded-2xl border border-slate-100 bg-white shadow-sm shadow-slate-900/5">
            <div className="border-b border-slate-100 px-4 sm:px-6">
              <div className="flex gap-0">
                <button
                  type="button"
                  onClick={() => setTab("lawyers")}
                  className={`relative flex-1 border-b-2 py-4 text-sm font-semibold transition sm:flex-none sm:px-8 ${
                    tab === "lawyers"
                      ? "border-blue-600 text-blue-600"
                      : "border-transparent text-slate-500 hover:text-slate-800"
                  }`}
                >
                  Pending lawyers
                </button>
                <button
                  type="button"
                  onClick={() => setTab("logs")}
                  className={`relative flex-1 border-b-2 py-4 text-sm font-semibold transition sm:flex-none sm:px-8 ${
                    tab === "logs"
                      ? "border-blue-600 text-blue-600"
                      : "border-transparent text-slate-500 hover:text-slate-800"
                  }`}
                >
                  System logs
                </button>
              </div>
            </div>

            <div className="p-4 sm:p-6">
              {tab === "lawyers" && (
                <div className="overflow-x-auto rounded-xl border border-slate-100">
                  <table className="min-w-full divide-y divide-slate-100 text-left text-sm">
                    <thead className="bg-slate-50/80">
                      <tr>
                        <th className="whitespace-nowrap px-4 py-3 font-semibold text-slate-700 sm:px-6">
                          Name
                        </th>
                        <th className="whitespace-nowrap px-4 py-3 font-semibold text-slate-700 sm:px-6">
                          License number
                        </th>
                        <th className="whitespace-nowrap px-4 py-3 font-semibold text-slate-700 sm:px-6">
                          Signup date
                        </th>
                        <th className="whitespace-nowrap px-4 py-3 text-right font-semibold text-slate-700 sm:px-6">
                          Actions
                        </th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100 bg-white">
                      {pendingLawyers.length === 0 ? (
                        <tr>
                          <td
                            colSpan={4}
                            className="px-4 py-10 text-center text-slate-500 sm:px-6"
                          >
                            No pending lawyer applications. Great work.
                          </td>
                        </tr>
                      ) : (
                        pendingLawyers.map((row) => (
                          <tr key={row.id} className="hover:bg-slate-50/80">
                            <td className="whitespace-nowrap px-4 py-3 font-medium text-slate-900 sm:px-6">
                              {row.name}
                            </td>
                            <td className="whitespace-nowrap px-4 py-3 text-slate-600 sm:px-6">
                              {row.licenseNumber}
                            </td>
                            <td className="whitespace-nowrap px-4 py-3 text-slate-600 sm:px-6">
                              {row.signupDate}
                            </td>
                            <td className="whitespace-nowrap px-4 py-3 text-right sm:px-6">
                              <div className="flex flex-wrap justify-end gap-2">
                                <button
                                  type="button"
                                  disabled={rowBusyId === row.id}
                                  onClick={() => void approve(row)}
                                  className="rounded-lg bg-emerald-600 px-3 py-1.5 text-xs font-semibold text-white shadow-sm hover:bg-emerald-500 disabled:cursor-not-allowed disabled:opacity-50"
                                >
                                  Approve
                                </button>
                                <button
                                  type="button"
                                  disabled={rowBusyId === row.id}
                                  onClick={() => void reject(row)}
                                  className="rounded-lg bg-red-600 px-3 py-1.5 text-xs font-semibold text-white shadow-sm hover:bg-red-500 disabled:cursor-not-allowed disabled:opacity-50"
                                >
                                  Reject
                                </button>
                              </div>
                            </td>
                          </tr>
                        ))
                      )}
                    </tbody>
                  </table>
                </div>
              )}

              {tab === "logs" && (
                <div className="overflow-x-auto rounded-xl border border-slate-100">
                  <table className="min-w-full divide-y divide-slate-100 text-left text-sm">
                    <thead className="bg-slate-50/80">
                      <tr>
                        <th className="whitespace-nowrap px-4 py-3 font-semibold text-slate-700 sm:px-6">
                          Time
                        </th>
                        <th className="whitespace-nowrap px-4 py-3 font-semibold text-slate-700 sm:px-6">
                          Event
                        </th>
                        <th className="whitespace-nowrap px-4 py-3 font-semibold text-slate-700 sm:px-6">
                          Status
                        </th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100 bg-white">
                      {logs.length === 0 ? (
                        <tr>
                          <td
                            colSpan={3}
                            className="px-4 py-10 text-center text-slate-500 sm:px-6"
                          >
                            No emergency events recorded yet.
                          </td>
                        </tr>
                      ) : (
                        logs.map((row) => (
                          <tr key={row.id} className="hover:bg-slate-50/80">
                            <td className="whitespace-nowrap px-4 py-3 text-slate-600 sm:px-6">
                              {formatTs(row.timestamp)}
                            </td>
                            <td className="px-4 py-3 text-slate-900 sm:px-6">
                              {row.message}
                            </td>
                            <td className="whitespace-nowrap px-4 py-3 sm:px-6">
                              <span
                                className={`inline-flex rounded-full px-2.5 py-0.5 text-xs font-semibold ring-1 ring-inset ${statusBadgeClass(row.status)}`}
                              >
                                {row.status}
                              </span>
                            </td>
                          </tr>
                        ))
                      )}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          </section>
        </>
      )}
    </main>
  );
}
