import { useEffect, useMemo, useState } from "react";
import { Alert, ScrollView, Switch, Text, View } from "react-native";
import * as Location from "expo-location";
import { useLocalSearchParams } from "expo-router";

import { Card, PrimaryButton, ScreenWrapper } from "@/components";
import { updateLawyerLocation } from "@/api/lawyerApi";
import { emitAcceptCase, emitLawyerAvailability, getSocket } from "@/services/socketManager";
import { useEmergencyFeedStore } from "@/store/emergencyFeedStore";
import { useAuthStore } from "@/store/authStore";

export default function LawyerDashboardScreen() {
  const user = useAuthStore((s) => s.user);
  const items = useEmergencyFeedStore((s) => s.items);
  const removeByEventId = useEmergencyFeedStore((s) => s.removeByEventId);
  const params = useLocalSearchParams<{ eventId?: string }>();
  const focusEventId = typeof params.eventId === "string" ? params.eventId : null;

  const [available, setAvailable] = useState(true);
  const [pendingMsg, setPendingMsg] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    const publish = async () => {
      try {
        const { status } = await Location.requestForegroundPermissionsAsync();
        if (status !== "granted" || cancelled) return;
        const pos = await Location.getCurrentPositionAsync({
          accuracy: Location.Accuracy.Balanced,
        });
        if (cancelled) return;
        await updateLawyerLocation(pos.coords.latitude, pos.coords.longitude);
      } catch {
        /* optional */
      }
    };
    void publish();
    const id = setInterval(() => void publish(), 3 * 60_000);
    return () => {
      cancelled = true;
      clearInterval(id);
    };
  }, []);

  useEffect(() => {
    const socket = getSocket();
    if (!socket) return;

    const onConfirmed = () => {
      setPendingMsg("ממתין לבחירת מצב שיחה מהלקוח…");
    };

    const onError = (payload: unknown) => {
      const p = payload as { message?: string };
      Alert.alert("שגיאה", p.message ?? "פעולה נכשלה");
    };

    const onTaken = (payload: unknown) => {
      const p = payload as { eventId?: string };
      if (p.eventId) removeByEventId(p.eventId);
    };

    socket.on("case_accepted_confirmed", onConfirmed);
    socket.on("veto_error", onError);
    socket.on("case_taken", onTaken);

    return () => {
      socket.off("case_accepted_confirmed", onConfirmed);
      socket.off("veto_error", onError);
      socket.off("case_taken", onTaken);
    };
  }, [removeByEventId]);

  function toggleAvail(next: boolean) {
    setAvailable(next);
    emitLawyerAvailability(next);
  }

  function accept(eventId: string) {
    emitAcceptCase(eventId);
  }

  const orderedItems = useMemo(() => {
    if (!focusEventId) return items;
    return [...items].sort((a, b) => {
      if (a.eventId === focusEventId) return -1;
      if (b.eventId === focusEventId) return 1;
      return 0;
    });
  }, [items, focusEventId]);

  return (
    <ScreenWrapper scroll>
      <Text className="mb-1 text-2xl font-bold text-primary">לוח בקרה — עורך דין</Text>
      <Text className="mb-6 text-sm text-legal-slate-muted">שלום {user?.full_name ?? ""}</Text>

      <Card className="mb-6">
        <View className="flex-row items-center justify-between">
          <View>
            <Text className="text-base font-semibold text-legal-slate">זמינות</Text>
            <Text className="text-xs text-legal-slate-muted">
              {available ? "אתה מוצג כזמין לחירום" : "לא תקבל התראות חדשות"}
            </Text>
          </View>
          <Switch value={available} onValueChange={toggleAvail} trackColor={{ true: "#1e3a8a" }} />
        </View>
      </Card>

      {pendingMsg ? (
        <Card className="mb-4 bg-surface">
          <Text className="text-center text-sm text-primary">{pendingMsg}</Text>
        </Card>
      ) : null}

      {focusEventId ? (
        <Card className="mb-4 border border-amber-500/40 bg-amber-500/10">
          <Text className="text-center text-sm font-semibold text-amber-900 dark:text-amber-100">
            נפתח מהתראת SOS · אירוע {focusEventId.slice(0, 8)}…
          </Text>
        </Card>
      ) : null}

      <Text className="mb-2 text-lg font-semibold text-legal-slate">בקשות חירום</Text>
      {orderedItems.length === 0 ? (
        <Text className="py-8 text-center text-legal-slate-muted">אין בקשות פתוחות</Text>
      ) : (
        <ScrollView className="max-h-96">
          {orderedItems.map((item) => (
            <Card
              key={item.eventId}
              className={`mb-3 ${item.eventId === focusEventId ? "border border-amber-500/50" : ""}`}
            >
              <Text className="font-bold text-legal-slate">{item.userName || "אזרח"}</Text>
              <Text className="text-xs text-legal-slate-muted">
                אירוע {item.eventId} · {item.language}
              </Text>
              <PrimaryButton
                title="קבל מקרה"
                onPress={() => accept(item.eventId)}
                className="mt-3"
                fullWidth
              />
            </Card>
          ))}
        </ScrollView>
      )}
    </ScreenWrapper>
  );
}
