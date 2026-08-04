import { Text, View } from "react-native";

import { ScreenWrapper } from "@/components";
import { useAuthStore } from "@/store/authStore";

export default function AdminDashboardScreen() {
  const user = useAuthStore((s) => s.user);
  return (
    <ScreenWrapper>
      <Text className="text-2xl font-bold text-primary">לוח בקרה — מנהל</Text>
      <Text className="mt-2 text-legal-slate-muted">
        מסך פנימי בלבד (placeholder). ניהול מנהלים המלא הוא ב-web `/admin`. משתמש:{" "}
        {user?.full_name ?? ""}
      </Text>
    </ScreenWrapper>
  );
}
