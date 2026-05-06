import { Phone, Shield } from "lucide-react-native";
import { useState } from "react";
import { Alert, Text, View } from "react-native";

import { requestOtp, verifyOtp } from "@/api/authApi";
import { Card, InputField, PrimaryButton, ScreenWrapper } from "@/components";
import { useAuthStore, type AuthUser, toAppRole, type ApiUserRole } from "@/store/authStore";
import { useRouter } from "expo-router";
import { ensureSocketForRole } from "@/services/socketManager";

export default function LoginScreen() {
  const router = useRouter();
  const setSession = useAuthStore((s) => s.setSession);

  const [phone, setPhone] = useState("");
  const [otp, setOtp] = useState("");
  const [showOtp, setShowOtp] = useState(false);
  const [loading, setLoading] = useState(false);

  async function onRequestOtp() {
    if (!phone.trim()) {
      Alert.alert("חסר מספר", "הזן מספר טלפון.");
      return;
    }
    setLoading(true);
    try {
      const res = await requestOtp(phone.trim());
      if (res.otp) {
        Alert.alert("קוד OTP (פיתוח)", String(res.otp));
      }
      setShowOtp(true);
    } catch (e: unknown) {
      const msg = e && typeof e === "object" && "response" in e &&
        e.response &&
        typeof e.response === "object" &&
        "data" in e.response &&
        e.response.data &&
        typeof e.response.data === "object" &&
        "error" in e.response.data
        ? String((e.response.data as { error: string }).error)
        : "לא ניתן לשלוח OTP";
      Alert.alert("שגיאה", msg);
    } finally {
      setLoading(false);
    }
  }

  async function onVerify() {
    if (!otp.trim() || otp.length < 4) {
      Alert.alert("קוד לא תקין", "הזן את קוד האימות.");
      return;
    }
    setLoading(true);
    try {
      const data = await verifyOtp(phone.trim(), otp.trim());
      const role = data.user.role as ApiUserRole;
      const authUser: AuthUser = {
        id: String(data.user.id),
        full_name: data.user.full_name,
        phone: data.user.phone,
        role,
        appRole: toAppRole(role),
        preferred_language: data.user.preferred_language,
      };
      await setSession(data.token, authUser);
      ensureSocketForRole(authUser);
      if (authUser.appRole === "citizen") router.replace("/(citizen)/hub");
      else if (authUser.appRole === "lawyer") router.replace("/(lawyer)/dashboard");
      else router.replace("/(admin)/dashboard");
    } catch (e: unknown) {
      const msg = e && typeof e === "object" && "response" in e &&
        e.response &&
        typeof e.response === "object" &&
        "data" in e.response &&
        e.response.data &&
        typeof e.response.data === "object" &&
        "error" in e.response.data
        ? String((e.response.data as { error: string }).error)
        : "אימות נכשל";
      Alert.alert("שגיאה", msg);
    } finally {
      setLoading(false);
    }
  }

  return (
    <ScreenWrapper scroll>
      <View className="mb-8 mt-6 items-center">
        <View className="mb-3 h-14 w-14 items-center justify-center rounded-2xl bg-primary">
          <Shield color="#ffffff" size={32} />
        </View>
        <Text className="text-2xl font-bold text-primary">VETO Legal</Text>
        <Text className="mt-1 text-center text-legal-slate-muted">
          התחברות מאובטחת באמצעות OTP
        </Text>
      </View>

      <Card className="mb-6">
        <Text className="mb-4 text-lg font-semibold text-legal-slate">כניסה</Text>
        <InputField
          placeholder="מספר טלפון"
          value={phone}
          onChangeText={setPhone}
          keyboardType="phone-pad"
          icon={Phone}
          className="mb-3"
        />
        {showOtp ? (
          <InputField
            placeholder="קוד SMS"
            value={otp}
            onChangeText={setOtp}
            keyboardType="numeric"
            secureTextEntry
            icon={Shield}
            className="mb-4"
          />
        ) : null}
        {!showOtp ? (
          <PrimaryButton title="שלח קוד" onPress={onRequestOtp} loading={loading} fullWidth />
        ) : (
          <PrimaryButton title="אמת והמשך" onPress={onVerify} loading={loading} fullWidth />
        )}
      </Card>

      <Text className="text-center text-xs text-legal-slate-muted">
        לשימוש עם השרת ב־{` http://localhost:5001`}. באנדרואיד אמולטור ייתכן שתידרש כתובת 10.0.2.2.
      </Text>
    </ScreenWrapper>
  );
}
