import { ActivityIndicator, Pressable, Text } from "react-native";

type Variant = "solid" | "outline";

export type PrimaryButtonProps = {
  title: string;
  onPress: () => void;
  variant?: Variant;
  loading?: boolean;
  fullWidth?: boolean;
  disabled?: boolean;
  className?: string;
};

export function PrimaryButton({
  title,
  onPress,
  variant = "solid",
  loading = false,
  fullWidth = false,
  disabled = false,
  className = "",
}: PrimaryButtonProps) {
  const isDisabled = disabled || loading;
  const base =
    "rounded-xl py-3.5 px-5 items-center justify-center min-h-[52px] active:opacity-90";
  const width = fullWidth ? "w-full" : "";
  const solid = "bg-primary border-2 border-primary";
  const outline = "bg-transparent border-2 border-primary";
  const variantCls = variant === "solid" ? solid : outline;

  return (
    <Pressable
      onPress={onPress}
      disabled={isDisabled}
      className={`${base} ${variantCls} ${width} ${isDisabled ? "opacity-50" : ""} ${className}`}
    >
      {loading ? (
        <ActivityIndicator color={variant === "solid" ? "#ffffff" : "#1e3a8a"} />
      ) : (
        <Text
          className={`text-base font-semibold ${variant === "solid" ? "text-white" : "text-primary"}`}
        >
          {title}
        </Text>
      )}
    </Pressable>
  );
}
