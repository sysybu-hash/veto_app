import type { ReactNode } from "react";
import { ScrollView, View } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";

export type ScreenWrapperProps = {
  children: ReactNode;
  scroll?: boolean;
  className?: string;
};

export function ScreenWrapper({ children, scroll = false, className = "" }: ScreenWrapperProps) {
  return (
    <SafeAreaView className={`flex-1 bg-background ${className}`} edges={["top", "left", "right"]}>
      {scroll ? (
        <ScrollView
          className="flex-1"
          contentContainerClassName="flex-grow px-4 pb-8 pt-2"
          keyboardShouldPersistTaps="handled"
        >
          {children}
        </ScrollView>
      ) : (
        <View className="flex-1 px-4 pb-8 pt-2">{children}</View>
      )}
    </SafeAreaView>
  );
}
