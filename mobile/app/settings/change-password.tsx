// app/settings/change-password.tsx
import React, { useState } from "react";
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  TextInput,
  Alert,
  Platform,
} from "react-native";
import { LinearGradient } from "expo-linear-gradient";
import { BlurView } from "expo-blur";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import Animated, { FadeInDown } from "react-native-reanimated";
import * as Haptics from "expo-haptics";

import LiquidGlassButton from "../../components/LiquidGlassButton";
import {
  colors,
  typography,
  spacing,
  borderRadius,
} from "../../constants/theme";
import { router } from "expo-router";

// Text Input Field Component (reused from login)
interface TextInputFieldProps {
  label: string;
  placeholder: string;
  value: string;
  onChangeText: (text: string) => void;
  secureTextEntry?: boolean;
  isValid?: boolean;
}

function TextInputField({
  label,
  placeholder,
  value,
  onChangeText,
  secureTextEntry = false,
  isValid = false,
}: TextInputFieldProps) {
  return (
    <View style={styles.inputContainer}>
      <Text style={styles.inputLabel}>{label}</Text>
      <View style={styles.inputWrapper}>
        <BlurView
          intensity={Platform.OS === "ios" ? 40 : 30}
          tint="dark"
          style={styles.inputBlur}
        >
          <View style={styles.inputGlassOverlay} />
          <TextInput
            style={styles.input}
            placeholder={placeholder}
            placeholderTextColor={colors.textSecondary}
            value={value}
            onChangeText={onChangeText}
            secureTextEntry={secureTextEntry}
            autoCapitalize="none"
            autoCorrect={false}
          />
        </BlurView>
        <View
          style={[
            styles.inputBorder,
            isValid && value.length > 0 && styles.inputBorderValid,
          ]}
        />
      </View>
    </View>
  );
}

export default function ChangePassword() {
  const insets = useSafeAreaInsets();
  const [currentPassword, setCurrentPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [isChanging, setIsChanging] = useState(false);

  // Validation states
  const [isCurrentPasswordValid, setIsCurrentPasswordValid] = useState(false);
  const [isNewPasswordValid, setIsNewPasswordValid] = useState(false);
  const [isConfirmPasswordValid, setIsConfirmPasswordValid] = useState(false);

  // Password validation
  const validatePassword = (password: string): boolean => {
    return password.length >= 8;
  };

  // Update validations
  React.useEffect(() => {
    setIsCurrentPasswordValid(validatePassword(currentPassword));
  }, [currentPassword]);

  React.useEffect(() => {
    setIsNewPasswordValid(validatePassword(newPassword));
    setIsConfirmPasswordValid(
      validatePassword(confirmPassword) && confirmPassword === newPassword
    );
  }, [newPassword, confirmPassword]);

  const handleChangePassword = async () => {
    if (
      !isCurrentPasswordValid ||
      !isNewPasswordValid ||
      !isConfirmPasswordValid
    ) {
      Alert.alert("Invalid Input", "Please check all password fields.");
      return;
    }

    if (newPassword !== confirmPassword) {
      Alert.alert("Error", "New passwords do not match.");
      return;
    }

    setIsChanging(true);
    try {
      // Mock password change - in production, call your API
      // Verify current password, then update to new password

      await new Promise((resolve) => setTimeout(resolve, 1000)); // Simulate API call

      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      Alert.alert("Success", "Password changed successfully", [
        {
          text: "OK",
          onPress: () => router.back(),
        },
      ]);
    } catch (error) {
      console.error("Error changing password:", error);
      Alert.alert("Error", "Failed to change password. Please try again.");
    } finally {
      setIsChanging(false);
    }
  };

  const canSubmit =
    isCurrentPasswordValid &&
    isNewPasswordValid &&
    isConfirmPasswordValid &&
    newPassword === confirmPassword;

  return (
    <View style={styles.container}>
      <LinearGradient
        colors={[colors.background, colors.backgroundSecondary, colors.background]}
        style={styles.gradient}
      />

      {/* Blur Shapes */}
      <View style={styles.blurShape1} />
      <View style={styles.blurShape2} />

      <ScrollView
        contentContainerStyle={[
          styles.scrollContent,
          { paddingTop: insets.top + 40, paddingBottom: insets.bottom + 20 },
        ]}
        showsVerticalScrollIndicator={false}
        keyboardShouldPersistTaps="handled"
      >
        <View style={styles.content}>
          {/* Title */}
          <Animated.View entering={FadeInDown.duration(400)} style={styles.titleContainer}>
            <Text style={styles.title}>Change Password</Text>
            <Text style={styles.subtitle}>
              Enter your current and new password
            </Text>
          </Animated.View>

          {/* Current Password Field */}
          <TextInputField
            label="Current Password"
            placeholder="Enter current password"
            value={currentPassword}
            onChangeText={setCurrentPassword}
            secureTextEntry
            isValid={isCurrentPasswordValid && currentPassword.length > 0}
          />

          {/* New Password Field */}
          <TextInputField
            label="New Password"
            placeholder="Enter new password"
            value={newPassword}
            onChangeText={setNewPassword}
            secureTextEntry
            isValid={isNewPasswordValid && newPassword.length > 0}
          />

          {/* Confirm Password Field */}
          <TextInputField
            label="Confirm New Password"
            placeholder="Confirm new password"
            value={confirmPassword}
            onChangeText={setConfirmPassword}
            secureTextEntry
            isValid={isConfirmPasswordValid && confirmPassword.length > 0}
          />

          {/* Change Button */}
          <LiquidGlassButton
            title="Change Password"
            onPress={handleChangePassword}
            variant="gradient"
            disabled={!canSubmit || isChanging}
            loading={isChanging}
            style={styles.submitButton}
          />
        </View>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  gradient: {
    ...StyleSheet.absoluteFillObject,
  },
  blurShape1: {
    position: "absolute",
    top: -100,
    left: -50,
    width: 300,
    height: 300,
    borderRadius: 150,
    backgroundColor: colors.accentPurpleMedium,
    opacity: 0.6,
  },
  blurShape2: {
    position: "absolute",
    bottom: -80,
    right: -80,
    width: 250,
    height: 250,
    borderRadius: 125,
    backgroundColor: colors.accentBlue,
    opacity: 0.5,
  },
  scrollContent: {
    flexGrow: 1,
    paddingHorizontal: spacing["2xl"],
  },
  content: {
    flex: 1,
    paddingTop: spacing["4xl"],
  },
  titleContainer: {
    alignItems: "center",
    marginBottom: spacing["4xl"],
  },
  title: {
    fontSize: typography.fontSize["3xl"],
    fontWeight: typography.fontWeight.bold,
    color: colors.textPrimary,
    marginBottom: spacing.sm,
    textAlign: "center",
  },
  subtitle: {
    fontSize: typography.fontSize.lg,
    fontWeight: typography.fontWeight.regular,
    color: colors.textSecondary,
    textAlign: "center",
  },
  inputContainer: {
    marginBottom: spacing["2xl"],
  },
  inputLabel: {
    fontSize: typography.fontSize.sm,
    fontWeight: typography.fontWeight.semiBold,
    color: colors.textSecondary,
    marginBottom: spacing.sm,
  },
  inputWrapper: {
    borderRadius: borderRadius.md,
    overflow: "hidden",
    borderWidth: 1,
    borderColor: colors.border,
  },
  inputBlur: {
    ...StyleSheet.absoluteFillObject,
  },
  inputGlassOverlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: colors.glassBackground,
  },
  input: {
    paddingHorizontal: spacing["2xl"],
    paddingVertical: spacing["2xl"],
    fontSize: typography.fontSize.base,
    color: colors.textPrimary,
    minHeight: 56,
  },
  inputBorder: {
    position: "absolute",
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: borderRadius.md,
    pointerEvents: "none",
  },
  inputBorderValid: {
    borderColor: colors.gradientStart + "4D", // 30% opacity
  },
  submitButton: {
    marginTop: spacing["2xl"],
  },
});

