import type { LucideIcon } from "lucide-react-native";
import { useState } from "react";
import { TextInput, View } from "react-native";

export type InputFieldProps = {
  placeholder: string;
  value: string;
  onChangeText: (t: string) => void;
  secureTextEntry?: boolean;
  icon?: LucideIcon;
  keyboardType?: "default" | "phone-pad" | "numeric";
  autoCapitalize?: "none" | "sentences" | "words" | "characters";
  className?: string;
};

export function InputField({
  placeholder,
  value,
  onChangeText,
  secureTextEntry = false,
  icon: Icon,
  keyboardType = "default",
  autoCapitalize = "none",
  className = "",
}: InputFieldProps) {
  const [focused, setFocused] = useState(false);

  return (
    <View
      className={`flex-row items-center rounded-xl border-2 bg-white px-3 ${
        focused ? "border-primary border-primary/90" : "border-slate-200"
      } ${className}`}
    >
      {Icon ? (
        <View className="mr-2 pl-1">
          <Icon size={20} color={focused ? "#1e3a8a" : "#64748b"} />
        </View>
      ) : null}
      <TextInput
        className="flex-1 py-3.5 text-base text-legal-slate"
        placeholder={placeholder}
        placeholderTextColor="#94a3b8"
        value={value}
        onChangeText={onChangeText}
        secureTextEntry={secureTextEntry}
        keyboardType={keyboardType}
        autoCapitalize={autoCapitalize}
        onFocus={() => setFocused(true)}
        onBlur={() => setFocused(false)}
      />
    </View>
  );
}
