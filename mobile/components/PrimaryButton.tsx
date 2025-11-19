// components/PrimaryButton.tsx
import React from "react";
import {
  Pressable,
  Text,
  StyleSheet,
  StyleProp,
  ViewStyle,
  Platform,
} from "react-native";
import * as Haptics from "expo-haptics";
import {
  colors,
  typography,
  spacing,
  borderRadius,
} from "../constants/theme";

type PrimaryButtonProps = {
  title: string;
  onPress?: () => void;
  style?: StyleProp<ViewStyle>;
  disabled?: boolean;
};

const PrimaryButton: React.FC<PrimaryButtonProps> = ({
  title,
  onPress = () => {},
  style,
  disabled = false,
}) => {
  const handlePress = () => {
    if (disabled) return;
    if (Platform.OS === "ios") {
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    }
    onPress();
  };

  return (
    <Pressable
      onPress={handlePress}
      style={({ pressed }) => [
        styles.button,
        style,
        disabled && styles.disabled,
        pressed && styles.pressed,
      ]}
      disabled={disabled}
    >
      <Text style={styles.label}>{title}</Text>
    </Pressable>
  );
};

export default PrimaryButton;

const styles = StyleSheet.create({
  button: {
    backgroundColor: colors.gradientStart,
    paddingVertical: spacing.lg,
    paddingHorizontal: spacing["2xl"],
    borderRadius: borderRadius.md,
    alignItems: "center",
    minHeight: 44, // iOS minimum touch target
  },
  pressed: {
    opacity: 0.8,
  },
  disabled: {
    opacity: 0.5,
  },
  label: {
    fontSize: typography.fontSize.lg,
    fontWeight: typography.fontWeight.bold,
    color: colors.textPrimary,
    fontFamily: typography.fontFamily,
  },
});
