import { FileText, FolderLock, Sparkles, User } from "lucide-react-native";
import * as Location from "expo-location";
import { useCallback, useEffect, useRef, useState } from "react";
import { ActivityIndicator, Alert, Modal, Pressable, Text, View } from "react-native";
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withRepeat,
  withSequence,
  withTiming,
} from "react-native-reanimated";

import { Card, ScreenWrapper } from "@/components";
import { theme } from "@/constants/theme";
import {
  emitCitizenChoseSession,
  emitStartVeto,
  getSocket,
} from "@/services/socketManager";
import { useAuthStore } from "@/store/authStore";

const DEFAULT_LOC = { lat: 32.0853, lng: 34.7818 };

export default function CitizenHubScreen() {
  const user = useAuthStore((s) => s.user);
  const [searching, setSearching] = useState(false);
  const [statusMsg, setStatusMsg] = useState<string | null>(null);
  const searchingRef = useRef(false);
  const lawyerFoundRef = useRef(false);

  useEffect(() => {
    searchingRef.current = searching;
  }, [searching]);

  const scale = useSharedValue(1);
  const pulseStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }],
  }));

  useEffect(() => {
    scale.value = withRepeat(
      withSequence(withTiming(1.06, { duration: 900 }), withTiming(1, { duration: 900 })),
      -1,
      false,
    );
  }, [scale]);

  const attachListeners = useCallback(() => {
    const socket = getSocket();
    if (!socket) return () => {};

    const onLawyerFound = (payload: unknown) => {
      const p = payload as { eventId?: string };
      if (p.eventId) {
        lawyerFoundRef.current = true;
        emitCitizenChoseSession(p.eventId, "video");
        setStatusMsg("מתחבר לעורך הדין…");
      }
    };

    const onNoLawyers = () => {
      setSearching(false);
      setStatusMsg(null);
      Alert.alert("אין עורכי דין", "אין עורכי דין זמינים כרגע. נסה שוב בעוד רגע.");
    };

    const onVetoError = (payload: unknown) => {
      const p = payload as { message?: string };
      setSearching(false);
      setStatusMsg(null);
      Alert.alert("שגיאה", p.message ?? "בקשת החירום נכשלה");
    };

    const onCaseTaken = (_payload: unknown) => {
      // Backend broadcasts `case_taken` to every socket except the lawyer
      // who accepted, which includes us. After our lawyer_found has fired
      // the broadcast is just informational for OTHER lawyers — never
      // surface it to the citizen whose case was successfully accepted.
      if (lawyerFoundRef.current) return;
      if (!searchingRef.current) return;
      setSearching(false);
      setStatusMsg(null);
      Alert.alert("עודכן", "המקרה כבר לא זמין.");
    };

    socket.on("lawyer_found", onLawyerFound);
    socket.on("no_lawyers_available", onNoLawyers);
    socket.on("veto_error", onVetoError);
    socket.on("case_taken", onCaseTaken);

    return () => {
      socket.off("lawyer_found", onLawyerFound);
      socket.off("no_lawyers_available", onNoLawyers);
      socket.off("veto_error", onVetoError);
      socket.off("case_taken", onCaseTaken);
    };
  }, []);

  useEffect(() => {
    let off: (() => void) | undefined;
    const socket = getSocket();
    if (socket?.connected) {
      off = attachListeners();
    }
    const onConnect = () => {
      off?.();
      off = attachListeners();
    };
    socket?.on("connect", onConnect);
    return () => {
      socket?.off("connect", onConnect);
      off?.();
    };
  }, [attachListeners, user?.id]);

  async function resolveLocation(): Promise<{ lat: number; lng: number }> {
    const { status } = await Location.requestForegroundPermissionsAsync();
    if (status !== "granted") {
      return DEFAULT_LOC;
    }
    const pos = await Location.getCurrentPositionAsync({});
    return { lat: pos.coords.latitude, lng: pos.coords.longitude };
  }

  async function onSos() {
    lawyerFoundRef.current = false;
    setSearching(true);
    setStatusMsg("מחפש עורך דין זמין…");
    try {
      const location = await resolveLocation();
      const lang = user?.preferred_language ?? "he";
      emitStartVeto({ location, preferredLanguage: lang });
    } catch {
      setSearching(false);
      setStatusMsg(null);
      Alert.alert("מיקום", "לא ניתן לקרוא מיקום, נסה שוב.");
    }
  }

  return (
    <ScreenWrapper>
      <View className="flex-row items-start justify-between border-b border-slate-100 pb-4">
        <View className="flex-1 pr-2">
          <Text className="text-lg text-legal-slate-muted">שלום,</Text>
          <Text className="text-2xl font-bold text-primary">
            {user?.full_name ?? "אזרח"}
          </Text>
          <Text className="mt-1 text-sm text-legal-slate-muted">
            מצב חירום — לחיצה אחת לעורך דין
          </Text>
        </View>
        <View className="h-12 w-12 items-center justify-center rounded-full bg-surface">
          <User color={theme.colors.primary} size={22} />
        </View>
      </View>

      <View className="flex-1 items-center justify-center py-8">
        <Animated.View style={pulseStyle} className="items-center">
          <Pressable
            onPress={onSos}
            disabled={searching}
            className={`h-52 w-52 items-center justify-center rounded-full bg-accent-sos shadow-2xl shadow-black/40 ${searching ? "opacity-70" : ""}`}
          >
            <Text className="text-center text-2xl font-black tracking-wide text-white">SOS</Text>
            <Text className="mt-1 px-4 text-center text-sm font-semibold text-white/90">
              חירום משפטי
            </Text>
          </Pressable>
        </Animated.View>
      </View>

      <View className="mb-4 flex-row flex-wrap justify-between gap-3">
        <MenuTile icon={FolderLock} label="כספת" />
        <MenuTile icon={Sparkles} label="עוזר AI" />
        <MenuTile icon={FileText} label="חוזים" />
      </View>

      <Modal visible={searching} transparent animationType="fade">
        <View className="flex-1 items-center justify-center bg-black/50 px-6">
          <Card className="w-full max-w-sm items-center">
            <ActivityIndicator size="large" color={theme.colors.primary} />
            <Text className="mt-4 text-center text-base font-semibold text-legal-slate">
              {statusMsg ?? "מחפש עורך דין…"}
            </Text>
          </Card>
        </View>
      </Modal>
    </ScreenWrapper>
  );
}

function MenuTile({ icon: Icon, label }: { icon: typeof FolderLock; label: string }) {
  return (
    <Pressable className="mb-2 min-w-[30%] flex-1 items-center rounded-2xl border border-slate-100 bg-white py-4 shadow-sm shadow-slate-900/5">
      <Icon color="#1e3a8a" size={26} />
      <Text className="mt-2 text-center text-xs font-semibold text-legal-slate">{label}</Text>
    </Pressable>
  );
}
