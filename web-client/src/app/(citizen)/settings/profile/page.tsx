"use client";

import { useEffect } from "react";

export default function SettingsProfilePage() {
  useEffect(() => {
    window.location.replace("/settings?tab=profile");
  }, []);
  return null;
}
