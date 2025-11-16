import React from 'react';
import { TouchableOpacity, Text, StyleSheet } from 'react-native';
import { colors, typography, spacing, borderRadius } from '../constants/theme';

export default function PrimaryButton({
  title,
  onPress = () => {},
  style = {},
  disabled = false,
}) {
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
}

const styles = StyleSheet.create({
  button: {
    backgroundColor: colors.gradientStart,
    paddingVertical: spacing.lg,
    paddingHorizontal: spacing['2xl'],
    borderRadius: borderRadius.md,
    alignItems: 'center',
  },
  label: {
    fontSize: typography.fontSize.lg,
    fontWeight: typography.fontWeight.bold,
    color: colors.textPrimary,
  },
});
