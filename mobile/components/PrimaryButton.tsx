// components/PrimaryButton.tsx
import React from "react";
import {
  TouchableOpacity,
  Text,
  StyleSheet,
  StyleProp,
  ViewStyle,
} from "react-native";
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
  return (
    <TouchableOpacity
      onPress={onPress}
      style={[styles.button, style, disabled && { opacity: 0.5 }]}
      disabled={disabled}
      activeOpacity={0.8}
    >
      <Text style={styles.label}>{title}</Text>
    </TouchableOpacity>
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
  },
  label: {
    fontSize: typography.fontSize.lg,
    fontWeight: typography.fontWeight.bold,
    color: colors.textPrimary,
  },
});
