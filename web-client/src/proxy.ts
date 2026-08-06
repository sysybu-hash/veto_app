import type { NextRequest } from "next/server";
import { NextResponse } from "next/server";

/** תואם ל־`src/lib/authToken.ts` — אחסון JWT בצד לקוח */
const JWT_COOKIE_PRIMARY = "veto_jwt";

const protectedRoutes = [
  "/vault",
  "/settings",
  "/dashboard",
  "/hub",
  "/onboarding",
  "/admin",
  "/call",
  "/calendar",
  "/family",
  "/plans",
  "/productivity",
  "/sos",
];

const authRoutes = ["/login", "/register"];

function readSessionToken(request: NextRequest): string | null {
  const raw =
    request.cookies.get(JWT_COOKIE_PRIMARY)?.value ||
    request.cookies.get("veto_session")?.value ||
    request.cookies.get("jwt")?.value;
  if (!raw?.trim()) return null;
  try {
    return decodeURIComponent(raw);
  } catch {
    return raw;
  }
}

function jwtRoleFromToken(token: string): string | null {
  try {
    const parts = token.split(".");
    if (parts.length < 2) return null;
    const json = atob(parts[1].replace(/-/g, "+").replace(/_/g, "/"));
    const payload = JSON.parse(json) as { role?: string };
    return typeof payload.role === "string" ? payload.role : null;
  } catch {
    return null;
  }
}

function homePathForRole(role: string | null): string {
  if (role === "admin") return "/admin/dashboard";
  if (role === "lawyer") return "/dashboard";
  return "/hub";
}

export function proxy(request: NextRequest) {
  const token = readSessionToken(request);
  const { pathname } = request.nextUrl;

  /** Admins stay in the admin shell — avoid citizen hub/onboarding and duplicate settings/vault URLs. */
  if (token) {
    const role = jwtRoleFromToken(token);
    const isCitizenOnlyRoute =
      pathname === "/hub" ||
      pathname.startsWith("/hub/") ||
      pathname === "/onboarding" ||
      pathname.startsWith("/onboarding/") ||
      pathname === "/calendar" ||
      pathname.startsWith("/calendar/") ||
      pathname === "/productivity" ||
      pathname.startsWith("/productivity/");
    const isLawyerOnlyRoute =
      pathname === "/dashboard" || pathname.startsWith("/dashboard/");
    const isAdminOnlyRoute =
      pathname === "/admin" || pathname.startsWith("/admin/");

    if (role !== "admin" && isAdminOnlyRoute) {
      return NextResponse.redirect(new URL(homePathForRole(role), request.url));
    }

    if (role !== "lawyer" && isLawyerOnlyRoute) {
      return NextResponse.redirect(new URL(homePathForRole(role), request.url));
    }

    if (role === "lawyer" && isCitizenOnlyRoute) {
      return NextResponse.redirect(new URL("/dashboard", request.url));
    }

    if (role === "lawyer" && (pathname === "/settings" || pathname.startsWith("/settings/"))) {
      return NextResponse.redirect(new URL("/dashboard", request.url));
    }

    if (role === "admin") {
      if (pathname === "/hub" || pathname.startsWith("/hub/")) {
        return NextResponse.redirect(new URL("/admin/dashboard", request.url));
      }
      if (pathname === "/onboarding" || pathname.startsWith("/onboarding/")) {
        return NextResponse.redirect(new URL("/admin/dashboard", request.url));
      }
      if (pathname === "/settings" || pathname.startsWith("/settings/")) {
        const url = request.nextUrl.clone();
        const rest = pathname.replace(/^\/settings\/?/, "");
        const tabFromPath =
          rest === "" || rest === "/"
            ? null
            : rest.replace(/^\//, "").split("/")[0];
        const allowed = ["profile", "notifications", "security", "billing"] as const;
        url.pathname = "/admin/settings";
        if (
          tabFromPath &&
          (allowed as readonly string[]).includes(tabFromPath)
        ) {
          url.searchParams.set("tab", tabFromPath);
        }
        return NextResponse.redirect(url);
      }
      if (pathname === "/vault" || pathname.startsWith("/admin/vault")) {
        return NextResponse.redirect(new URL("/admin/finance", request.url));
      }
    }
  }

  const isProtectedRoute = protectedRoutes.some((route) =>
    pathname.startsWith(route),
  );
  if (isProtectedRoute && !token) {
    const loginUrl = new URL("/login", request.url);
    loginUrl.searchParams.set("redirect", pathname);
    return NextResponse.redirect(loginUrl);
  }

  const isAuthRoute = authRoutes.some((route) => pathname.startsWith(route));
  if (isAuthRoute && token) {
    const role = jwtRoleFromToken(token);
    return NextResponse.redirect(
      new URL(homePathForRole(role), request.url),
    );
  }

  const response = NextResponse.next();

  response.headers.set("X-DNS-Prefetch-Control", "on");
  if (request.nextUrl.protocol === "https:") {
    response.headers.set(
      "Strict-Transport-Security",
      "max-age=63072000; includeSubDomains; preload",
    );
  }
  response.headers.set("X-XSS-Protection", "1; mode=block");
  response.headers.set("X-Frame-Options", "SAMEORIGIN");
  response.headers.set("X-Content-Type-Options", "nosniff");
  response.headers.set("Referrer-Policy", "strict-origin-when-cross-origin");

  return response;
}

export const config = {
  matcher: [
    "/((?!api|_next/static|_next/image|favicon.ico|.*\\.svg|.*\\.png|.*\\.jpg).*)",
  ],
};
