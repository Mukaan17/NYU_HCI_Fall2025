<<<<<<< HEAD:mobile/components/PrimaryButton.tsx
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
=======
import React from 'react';
import { TouchableOpacity, Text, StyleSheet, View } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { colors, typography, borderRadius, shadows } from '../constants/theme';

export default function PrimaryButton({ title, onPress, style, disabled }) {
>>>>>>> main:mobile/components/PrimaryButton.js
  return (
    <TouchableOpacity
      onPress={onPress}
      disabled={disabled}
      activeOpacity={0.8}
      style={[styles.container, style]}
    >
      <LinearGradient
        colors={[colors.gradientStart, colors.gradientEnd]}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 1 }}
        style={styles.gradient}
      >
        <View style={styles.content}>
          <Text style={styles.text}>{title}</Text>
        </View>
      </LinearGradient>
    </TouchableOpacity>
  );
};

export default PrimaryButton;

const styles = StyleSheet.create({
<<<<<<< HEAD:mobile/components/PrimaryButton.tsx
  button: {
    backgroundColor: colors.gradientStart,
    paddingVertical: spacing.lg,
    paddingHorizontal: spacing["2xl"],
    borderRadius: borderRadius.md,
    alignItems: "center",
=======
  container: {
    borderRadius: borderRadius.full,
    ...shadows.primary,
  },
  gradient: {
    paddingVertical: 6,
    paddingHorizontal: 20,
    borderRadius: borderRadius.full,
    minHeight: 56,
    justifyContent: 'center',
    alignItems: 'center',
>>>>>>> main:mobile/components/PrimaryButton.js
  },
  content: {
    justifyContent: 'center',
    alignItems: 'center',
  },
  text: {
    fontSize: typography.fontSize.xl,
    fontWeight: typography.fontWeight.medium,
    color: colors.textPrimary,
    textAlign: 'center',
  },
});

