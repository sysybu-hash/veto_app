import { useEffect, useState } from "react";
import { Alert, ScrollView, Switch, Text, View } from "react-native";

import { Card, PrimaryButton, ScreenWrapper } from "@/components";
import { emitAcceptCase, emitLawyerAvailability, getSocket } from "@/services/socketManager";
import { useEmergencyFeedStore } from "@/store/emergencyFeedStore";
import { useAuthStore } from "@/store/authStore";

export default function LawyerDashboardScreen() {
  const user = useAuthStore((s) => s.user);
  const items = useEmergencyFeedStore((s) => s.items);
  const removeByEventId = useEmergencyFeedStore((s) => s.removeByEventId);

  const [available, setAvailable] = useState(true);
  const [pendingMsg, setPendingMsg] = useState<string | null>(null);

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

      <Text className="mb-2 text-lg font-semibold text-legal-slate">בקשות חירום</Text>
      {items.length === 0 ? (
        <Text className="py-8 text-center text-legal-slate-muted">אין בקשות פתוחות</Text>
      ) : (
        <ScrollView className="max-h-96">
          {items.map((item) => (
            <Card key={item.eventId} className="mb-3">
              <Text className="font-bold text-legal-slate">{item.userName}</Text>
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
