import React from "react";
import {
  Text,
  Pressable,
  StyleSheet,
  Platform,
  ActivityIndicator,
} from "react-native";
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSpring,
  interpolate,
} from "react-native-reanimated";
import { LiquidGlassView, isLiquidGlassSupported } from "@callstack/liquid-glass";
import { LinearGradient } from "expo-linear-gradient";
import * as Haptics from "expo-haptics";
import { colors, typography, spacing, borderRadius } from "../constants/theme";

const AnimatedPressable = Animated.createAnimatedComponent(Pressable);

interface LiquidGlassButtonProps {
  title: string;
  onPress: () => void;
  variant?: "primary" | "secondary" | "glass";
  disabled?: boolean;
  loading?: boolean;
  icon?: React.ReactNode;
}

export default function LiquidGlassButton({
  title,
  onPress,
  variant = "glass",
  disabled = false,
  loading = false,
  icon,
}: LiquidGlassButtonProps) {
  const pressed = useSharedValue(0);
  const hasLiquidGlass = isLiquidGlassSupported;

  const buttonAnimatedStyle = useAnimatedStyle(() => {
    const scale = interpolate(pressed.value, [0, 1], [1, 0.96]);
    return {
      transform: [{ scale }],
    };
  });

  const handlePress = () => {
    if (disabled || loading) return;
    if (Platform.OS === "ios") {
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    }
    onPress();
  };

  // Use Liquid Glass for iOS 26+ when variant is "glass"
  if (hasLiquidGlass && variant === "glass" && Platform.OS === "ios") {
    return (
      <AnimatedPressable
        onPress={handlePress}
        disabled={disabled || loading}
        onPressIn={() => {
          pressed.value = withSpring(1, { damping: 50, stiffness: 600 });
        }}
        onPressOut={() => {
          pressed.value = withSpring(0, { damping: 50, stiffness: 600 });
        }}
        style={buttonAnimatedStyle}
      >
        <LiquidGlassView
          effect="regular"
          style={[
            styles.button,
            styles.glassButton,
            disabled && styles.disabled,
          ]}
          tintColor="rgba(108, 99, 255, 0.65)"
        >
          {loading ? (
            <ActivityIndicator color={colors.textPrimary} />
          ) : (
            <>
              {icon}
              <Text style={styles.glassText}>{title}</Text>
            </>
          )}
        </LiquidGlassView>
      </AnimatedPressable>
    );
  }

  // Fallback: Gradient button for primary or when Liquid Glass not supported
  if (variant === "primary") {
    return (
      <AnimatedPressable
        onPress={handlePress}
        disabled={disabled || loading}
        onPressIn={() => {
          pressed.value = withSpring(1, { damping: 50, stiffness: 600 });
        }}
        onPressOut={() => {
          pressed.value = withSpring(0, { damping: 50, stiffness: 600 });
        }}
        style={buttonAnimatedStyle}
      >
        <LinearGradient
          colors={[colors.gradientStart, colors.gradientEnd]}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 1 }}
          style={[styles.button, disabled && styles.disabled]}
        >
          {loading ? (
            <ActivityIndicator color={colors.textPrimary} />
          ) : (
            <>
              {icon}
              <Text style={styles.primaryText}>{title}</Text>
            </>
          )}
        </LinearGradient>
      </AnimatedPressable>
    );
  }

  // Secondary or glass fallback
  return (
    <AnimatedPressable
      onPress={handlePress}
      disabled={disabled || loading}
      onPressIn={() => {
        pressed.value = withSpring(1, { damping: 50, stiffness: 600 });
      }}
      onPressOut={() => {
        pressed.value = withSpring(0, { damping: 50, stiffness: 600 });
      }}
      style={[styles.button, styles.secondaryButton, disabled && styles.disabled, buttonAnimatedStyle]}
    >
      {loading ? (
        <ActivityIndicator color={colors.textPrimary} />
      ) : (
        <>
          {icon}
          <Text style={styles.secondaryText}>{title}</Text>
        </>
      )}
    </AnimatedPressable>
  );
}

const styles = StyleSheet.create({
  button: {
    paddingVertical: spacing.lg,
    paddingHorizontal: spacing["2xl"],
    borderRadius: borderRadius.lg,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    gap: spacing.sm,
    minHeight: 56,
  },
  glassButton: {
    borderWidth: 1,
    borderColor: 'rgba(108, 99, 255, 0.5)',
    ...Platform.select({
      ios: {
        shadowColor: '#6c63ff',
        shadowOffset: { width: 0, height: 8 },
        shadowOpacity: 0.6,
        shadowRadius: 24,
      },
      android: {
        elevation: 12,
      },
    }),
  },
  secondaryButton: {
    backgroundColor: colors.backgroundCard,
    borderWidth: 1,
    borderColor: colors.border,
  },
  disabled: {
    opacity: 0.5,
  },
  primaryText: {
    fontSize: typography.fontSize.lg,
    fontWeight: typography.fontWeight.semiBold,
    color: colors.textPrimary,
    letterSpacing: -0.3,
    fontFamily: typography.fontFamily,
  },
  glassText: {
    fontSize: typography.fontSize.lg,
    fontWeight: typography.fontWeight.bold,
    color: colors.textPrimary,
    letterSpacing: -0.3,
    fontFamily: typography.fontFamily,
  },
  secondaryText: {
    fontSize: typography.fontSize.lg,
    fontWeight: typography.fontWeight.semiBold,
    color: colors.textPrimary,
    letterSpacing: -0.3,
    fontFamily: typography.fontFamily,
  },
});
