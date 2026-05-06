"use client";

import { useEffect } from "react";
import { syncJwtCookieFromStorage } from "@/lib/authToken";

export function JwtCookieSync() {
  useEffect(() => {
    syncJwtCookieFromStorage();
  }, []);
  return null;
}
