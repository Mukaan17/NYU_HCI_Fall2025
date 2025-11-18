// components/InputField.tsx
import React, { useState } from "react";
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  Platform,
  StyleProp,
  ViewStyle,
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
  borderRadius,
  spacing,
  shadows,
} from "../constants/theme";

const AnimatedTouchable = Animated.createAnimatedComponent(TouchableOpacity);

interface InputFieldProps {
  placeholder: string;
  onSend: (text: string) => void | Promise<void>;
  style?: StyleProp<ViewStyle>;
}

export default function InputField({
  placeholder,
  onSend,
  style,
}: InputFieldProps) {
  const [text, setText] = useState("");
  const sendButtonScale = useSharedValue(1);

  const handleSend = () => {
    if (!text.trim()) return;

    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    onSend(text.trim());
    setText("");
  };

  const handlePressIn = () => {
    sendButtonScale.value = withSpring(0.9);
  };

  const handlePressOut = () => {
    sendButtonScale.value = withSpring(1);
  };

  const animatedButtonStyle = useAnimatedStyle(() => ({
    transform: [{ scale: sendButtonScale.value }],
  }));

  return (
    <View style={[styles.container, style]}>
      <View style={styles.inputWrapper}>
        {/* Frosted background */}
        <BlurView
          intensity={Platform.OS === "ios" ? 60 : 40}
          tint="dark"
          style={styles.blurContainer}
        >
          <View style={styles.glassOverlay} />
        </BlurView>

        <View style={styles.inputContainer}>
          <TextInput
            style={styles.input}
            placeholder={placeholder}
            placeholderTextColor={colors.textSecondary}
            value={text}
            onChangeText={setText}
            returnKeyType="send"
            onSubmitEditing={handleSend}
          />

          {/* Animated Send Button */}
          <AnimatedTouchable
            onPress={handleSend}
            onPressIn={handlePressIn}
            onPressOut={handlePressOut}
            style={[styles.sendButton, animatedButtonStyle]}
            disabled={!text.trim()}
            activeOpacity={0.8}
          >
            <LinearGradient
              colors={
                text.trim()
                  ? [colors.gradientStart, colors.gradientEnd]
                  : [colors.border, colors.border]
              }
              start={{ x: 0, y: 0 }}
              end={{ x: 1, y: 1 }}
              style={styles.sendButtonGradient}
            >
              <Text style={styles.sendIcon}>→</Text>
            </LinearGradient>
          </AnimatedTouchable>
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: spacing["2xl"],
    paddingTop: spacing.lg,
    paddingBottom: spacing.sm,
  },
  inputWrapper: {
    borderRadius: borderRadius.md,
    overflow: "hidden",
    borderWidth: 1,
    borderColor: "rgba(255, 255, 255, 0.15)",
    ...Platform.select({
      ios: {
        shadowColor: "#000",
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.2,
        shadowRadius: 12,
      },
      android: {
        elevation: 4,
      },
    }),
  },
  blurContainer: {
    ...StyleSheet.absoluteFillObject,
  },
  glassOverlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: "rgba(28, 37, 65, 0.5)",
  },
  inputContainer: {
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: spacing["2xl"],
    paddingVertical: spacing.md,
    minHeight: 60,
    gap: spacing["2xl"],
    zIndex: 1,
  },
  input: {
    flex: 1,
    fontSize: typography.fontSize.lg,
    fontWeight: typography.fontWeight.regular,
    color: colors.textPrimary,
  },
  sendButton: {
    width: 44,
    height: 44,
    borderRadius: borderRadius.md,
    overflow: "hidden",
    ...shadows.primary,
  },
  sendButtonGradient: {
    width: "100%",
    height: "100%",
    justifyContent: "center",
    alignItems: "center",
  },
  sendIcon: {
    fontSize: 20,
    color: colors.textPrimary,
    fontWeight: "bold",
  },
});
