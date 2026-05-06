import "../../global.css";

import { Stack, useRouter, useSegments } from "expo-router";
import * as SplashScreen from "expo-splash-screen";
import { useEffect, useRef } from "react";
import "react-native-reanimated";

import {
  disconnectSocket,
  ensureSocketForRole,
  setCallNavigateHandler,
} from "@/services/socketManager";
import { useAuthStore } from "@/store/authStore";

SplashScreen.preventAutoHideAsync();

export default function RootLayout() {
  const router = useRouter();
  const segments = useSegments();
  const hydrated = useAuthStore((s) => s.hydrated);
  const token = useAuthStore((s) => s.token);
  const user = useAuthStore((s) => s.user);
  const routedRef = useRef(false);

  useEffect(() => {
    useAuthStore.getState().hydrateFromStorage();
  }, []);

  useEffect(() => {
    setCallNavigateHandler((roomId) => {
      router.push(`/call/${roomId}`);
    });
    return () => setCallNavigateHandler(() => {});
  }, [router]);

  useEffect(() => {
    if (!hydrated) return;
    ensureSocketForRole(user);
    return () => {
      if (!useAuthStore.getState().token) disconnectSocket();
    };
  }, [hydrated, user]);

  useEffect(() => {
    if (!hydrated) return;

    void SplashScreen.hideAsync();

    const root = segments[0];
    if (root === "call") {
      routedRef.current = true;
      return;
    }

    if (!token || !user) {
      if (root !== "(auth)") {
        router.replace("/(auth)/login");
      }
      return;
    }

    if (root === "(auth)") {
      if (user.appRole === "citizen") router.replace("/(citizen)/hub");
      else if (user.appRole === "lawyer") router.replace("/(lawyer)/dashboard");
      else if (user.appRole === "admin") router.replace("/(admin)/dashboard");
      return;
    }

    if (user.appRole === "citizen" && (root === "(lawyer)" || root === "(admin)")) {
      router.replace("/(citizen)/hub");
    } else if (user.appRole === "lawyer" && (root === "(citizen)" || root === "(admin)")) {
      router.replace("/(lawyer)/dashboard");
    } else if (user.appRole === "admin" && root === "(lawyer)") {
      router.replace("/(admin)/dashboard");
    }
  }, [hydrated, token, user, segments, router]);

  if (!hydrated) {
    return null;
  }

  return <Stack screenOptions={{ headerShown: false }} />;
}
