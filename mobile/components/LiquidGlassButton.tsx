// components/LiquidGlassButton.tsx
import React from "react";
import {
  TouchableOpacity,
  Text,
  StyleSheet,
  StyleProp,
  ViewStyle,
  ActivityIndicator,
  Platform,
} from "react-native";
import { LinearGradient } from "expo-linear-gradient";
import { BlurView } from "expo-blur";
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSpring,
} from "react-native-reanimated";
import * as Haptics from "expo-haptics";

import {
  colors,
  typography,
  spacing,
  borderRadius,
  shadows,
} from "../constants/theme";

const AnimatedTouchable = Animated.createAnimatedComponent(TouchableOpacity);

interface LiquidGlassButtonProps {
  title: string;
  onPress?: () => void;
  variant?: "glass" | "gradient";
  style?: StyleProp<ViewStyle>;
  disabled?: boolean;
  loading?: boolean;
}

export default function LiquidGlassButton({
  title,
  onPress = () => {},
  variant = "glass",
  style,
  disabled = false,
  loading = false,
}: LiquidGlassButtonProps) {
  const scale = useSharedValue(1);

  const handlePressIn = () => {
    if (!disabled && !loading) {
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
      scale.value = withSpring(0.95);
    }
  };

  const handlePressOut = () => {
    scale.value = withSpring(1);
  };

  const handlePress = () => {
    if (!disabled && !loading) {
      onPress();
    }
  };

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }],
  }));

  if (variant === "gradient") {
    return (
      <AnimatedTouchable
        onPress={handlePress}
        onPressIn={handlePressIn}
        onPressOut={handlePressOut}
        style={[styles.container, style, animatedStyle]}
        disabled={disabled || loading}
        activeOpacity={0.8}
      >
        <LinearGradient
          colors={
            disabled
              ? [colors.border, colors.border]
              : [colors.gradientStart, colors.gradientEnd]
          }
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 1 }}
          style={styles.gradient}
        >
          {loading ? (
            <ActivityIndicator size="small" color={colors.textPrimary} />
          ) : (
            <Text style={styles.text}>{title}</Text>
          )}
        </LinearGradient>
      </AnimatedTouchable>
    );
  }

  return (
    <AnimatedTouchable
      onPress={handlePress}
      onPressIn={handlePressIn}
      onPressOut={handlePressOut}
      style={[styles.container, style, animatedStyle]}
      disabled={disabled || loading}
      activeOpacity={0.8}
    >
      <BlurView
        intensity={Platform.OS === "ios" ? 60 : 40}
        tint="dark"
        style={styles.blurContainer}
      >
        <View style={styles.glassOverlay} />
        <View style={styles.content}>
          {loading ? (
            <ActivityIndicator size="small" color={colors.textPrimary} />
          ) : (
            <Text style={styles.text}>{title}</Text>
          )}
        </View>
      </BlurView>
    </AnimatedTouchable>
  );
}

const styles = StyleSheet.create({
  container: {
    borderRadius: borderRadius.md,
    overflow: "hidden",
    borderWidth: 1,
    borderColor: "rgba(255, 255, 255, 0.15)",
    ...Platform.select({
      ios: {
        ...shadows.primary,
      },
      android: {
        elevation: 8,
      },
    }),
  },
  blurContainer: {
    ...StyleSheet.absoluteFillObject,
  },
  glassOverlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: "rgba(28, 37, 65, 0.6)",
  },
  gradient: {
    paddingVertical: spacing.lg,
    paddingHorizontal: spacing["2xl"],
    alignItems: "center",
    justifyContent: "center",
    minHeight: 56,
  },
  content: {
    paddingVertical: spacing.lg,
    paddingHorizontal: spacing["2xl"],
    alignItems: "center",
    justifyContent: "center",
    minHeight: 56,
  },
  text: {
    fontSize: typography.fontSize.lg,
    fontWeight: typography.fontWeight.semiBold,
    color: colors.textPrimary,
  },
});

