import { Link, Stack } from "expo-router";
import { Text, View } from "react-native";

export default function NotFoundScreen() {
  return (
    <>
      <Stack.Screen options={{ title: "לא נמצא" }} />
      <View className="flex-1 items-center justify-center bg-background px-4">
        <Text className="mb-4 text-lg text-legal-slate">המסך לא קיים.</Text>
        <Link href="/(auth)/login" className="text-primary underline">
          חזרה להתחברות
        </Link>
      </View>
    </>
  );
}
