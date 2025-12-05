// app/(onboarding)/login.tsx
import React, { useState, useEffect } from "react";
import {
  View,
  Text,
  TextInput,
  ScrollView,
  StyleSheet,
  Dimensions,
  Platform,
  Alert,
} from "react-native";
import { LinearGradient } from "expo-linear-gradient";
import { BlurView } from "expo-blur";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import AsyncStorage from "@react-native-async-storage/async-storage";
import Animated, {
  FadeIn,
  FadeInDown,
  useSharedValue,
  useAnimatedStyle,
  withTiming,
} from "react-native-reanimated";
import * as Haptics from "expo-haptics";

import LiquidGlassButton from "../../components/LiquidGlassButton";
import { colors, typography, spacing, borderRadius } from "../../constants/theme";
import { router } from "expo-router";
import { useAuth } from "../../context/AuthContext";

const { width } = Dimensions.get("window");

// Tab Selector Component
interface TabSelectorProps {
  isSignUpMode: boolean;
  onModeChange: (mode: boolean) => void;
}

function TabSelector({ isSignUpMode, onModeChange }: TabSelectorProps) {
  const translateX = useSharedValue(isSignUpMode ? width / 2 : 0);

  useEffect(() => {
    translateX.value = withTiming(isSignUpMode ? width / 2 : 0, {
      duration: 300,
    });
  }, [isSignUpMode]);

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ translateX: translateX.value }],
  }));

  return (
    <View style={styles.tabContainer}>
      <View style={styles.tabBackground}>
        <Animated.View style={[styles.tabIndicator, animatedStyle]} />
        <View style={styles.tabContent}>
          <Text
            style={[
              styles.tabText,
              !isSignUpMode && styles.tabTextActive,
            ]}
            onPress={() => {
              Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
              onModeChange(false);
            }}
          >
            Log In
          </Text>
          <Text
            style={[
              styles.tabText,
              isSignUpMode && styles.tabTextActive,
            ]}
            onPress={() => {
              Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
              onModeChange(true);
            }}
          >
            Sign Up
          </Text>
        </View>
      </View>
    </View>
  );
}

// Text Input Field Component
interface TextInputFieldProps {
  label: string;
  placeholder: string;
  value: string;
  onChangeText: (text: string) => void;
  secureTextEntry?: boolean;
  keyboardType?: "default" | "email-address";
  autoCapitalize?: "none" | "words" | "sentences";
  isValid?: boolean;
}

function TextInputField({
  label,
  placeholder,
  value,
  onChangeText,
  secureTextEntry = false,
  keyboardType = "default",
  autoCapitalize = "none",
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
            keyboardType={keyboardType}
            autoCapitalize={autoCapitalize}
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

export default function Login() {
  const insets = useSafeAreaInsets();
  const { login, signup } = useAuth();
  const [isSignUpMode, setIsSignUpMode] = useState(false);
  const [email, setEmail] = useState("");
  const [firstName, setFirstName] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [isLoggingIn, setIsLoggingIn] = useState(false);
  const [isSigningUp, setIsSigningUp] = useState(false);
  const [welcomeTextOpacity, setWelcomeTextOpacity] = useState(0);
  const [hasCheckedDefaultMode, setHasCheckedDefaultMode] = useState(false);

  // Validation states
  const [isEmailValid, setIsEmailValid] = useState(false);
  const [isPasswordValid, setIsPasswordValid] = useState(false);
  const [isConfirmPasswordValid, setIsConfirmPasswordValid] = useState(false);

  // Check default mode on mount
  useEffect(() => {
    const checkDefaultMode = async () => {
      try {
        const userAccount = await AsyncStorage.getItem("userAccount");
        if (userAccount) {
          const account = JSON.parse(userAccount);
          setIsSignUpMode(!account.hasLoggedIn);
        } else {
          setIsSignUpMode(true); // Default to signup for new users
        }
        setHasCheckedDefaultMode(true);
        // Animate welcome text
        setTimeout(() => setWelcomeTextOpacity(1), 100);
      } catch (error) {
        console.error("Error checking default mode:", error);
        setIsSignUpMode(true);
        setHasCheckedDefaultMode(true);
        setTimeout(() => setWelcomeTextOpacity(1), 100);
      }
    };

    checkDefaultMode();
  }, []);

  // Animate welcome text when mode changes
  useEffect(() => {
    setWelcomeTextOpacity(0);
    setTimeout(() => setWelcomeTextOpacity(1), 150);
  }, [isSignUpMode]);

  // Email validation
  const validateNYUEmail = (email: string): boolean => {
    const nyuEmailRegex = /^[a-zA-Z0-9._%+-]+@(nyu|stern)\.edu$/i;
    return nyuEmailRegex.test(email);
  };

  const validateEmail = (email: string): boolean => {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  };

  // Password validation
  const validatePassword = (password: string): boolean => {
    return password.length >= 8;
  };

  // Update validations
  useEffect(() => {
    if (isSignUpMode) {
      setIsEmailValid(validateNYUEmail(email));
    } else {
      setIsEmailValid(validateEmail(email));
    }
  }, [email, isSignUpMode]);

  useEffect(() => {
    setIsPasswordValid(validatePassword(password));
    if (isSignUpMode) {
      setIsConfirmPasswordValid(
        validatePassword(confirmPassword) && confirmPassword === password
      );
    }
  }, [password, confirmPassword, isSignUpMode]);

  const handleEmailLogin = async () => {
    if (!isEmailValid || !isPasswordValid) {
      Alert.alert("Invalid Input", "Please check your email and password.");
      return;
    }

    setIsLoggingIn(true);
    try {
      // Real API login
      await login(email, password);

      // Save user account data
      const userAccount = {
        id: Date.now().toString(), // Will be replaced with actual user ID from API
        email,
        firstName: "User", // Will be replaced with actual first name from API
        hasLoggedIn: true,
      };

      await AsyncStorage.setItem("userAccount", JSON.stringify(userAccount));
      await AsyncStorage.setItem("hasLoggedIn", "true");

      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      router.replace("/(onboarding)/survey");
    } catch (error) {
      console.error("Login error:", error);
      const errorMessage = error instanceof Error ? error.message : "Failed to log in. Please try again.";
      Alert.alert("Error", errorMessage);
    } finally {
      setIsLoggingIn(false);
    }
  };

  const handleSignUp = async () => {
    if (
      !isEmailValid ||
      !isPasswordValid ||
      !isConfirmPasswordValid ||
      firstName.trim().length === 0
    ) {
      Alert.alert("Invalid Input", "Please fill in all fields correctly.");
      return;
    }

    setIsSigningUp(true);
    try {
      // Real API signup
      await signup(email, password, firstName.trim());

      // Save user account data
      const userAccount = {
        id: Date.now().toString(), // Will be replaced with actual user ID from API
        email,
        firstName: firstName.trim(),
        hasLoggedIn: true,
      };

      await AsyncStorage.setItem("userAccount", JSON.stringify(userAccount));
      await AsyncStorage.setItem("hasLoggedIn", "true");

      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      router.replace("/(onboarding)/survey");
    } catch (error) {
      console.error("Signup error:", error);
      const errorMessage = error instanceof Error ? error.message : "Failed to sign up. Please try again.";
      Alert.alert("Error", errorMessage);
    } finally {
      setIsSigningUp(false);
    }
  };

  const canSubmit = isSignUpMode
    ? isEmailValid &&
      isPasswordValid &&
      isConfirmPasswordValid &&
      firstName.trim().length > 0
    : isEmailValid && isPasswordValid;

  if (!hasCheckedDefaultMode) {
    return null; // Or a loading indicator
  }

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
          {/* Tab Selector */}
          <TabSelector
            isSignUpMode={isSignUpMode}
            onModeChange={setIsSignUpMode}
          />

          {/* Animated Welcome Text */}
          <Animated.View
            entering={FadeInDown.duration(400)}
            style={[styles.welcomeContainer, { opacity: welcomeTextOpacity }]}
          >
            <Text style={styles.welcomeTitle}>
              {isSignUpMode ? "Welcome" : "Welcome Back"}
            </Text>
            <Text style={styles.welcomeSubtitle}>
              {isSignUpMode
                ? "Create your account"
                : "Sign in to continue"}
            </Text>
          </Animated.View>

          {/* First Name Field (Sign Up Only) */}
          {isSignUpMode && (
            <Animated.View entering={FadeIn.duration(300)}>
              <TextInputField
                label="First Name"
                placeholder="Enter your first name"
                value={firstName}
                onChangeText={setFirstName}
                autoCapitalize="words"
              />
            </Animated.View>
          )}

          {/* Email Field */}
          <TextInputField
            label={isSignUpMode ? "NYU Email" : "Email"}
            placeholder={
              isSignUpMode ? "Enter your NYU email" : "Enter your email"
            }
            value={email}
            onChangeText={setEmail}
            keyboardType="email-address"
            autoCapitalize="none"
            isValid={isEmailValid && email.length > 0}
          />

          {/* Password Field */}
          <TextInputField
            label="Password"
            placeholder="Enter your password"
            value={password}
            onChangeText={setPassword}
            secureTextEntry
            isValid={isPasswordValid && password.length > 0}
          />

          {/* Confirm Password Field (Sign Up Only) */}
          {isSignUpMode && (
            <Animated.View entering={FadeIn.duration(300)}>
              <TextInputField
                label="Confirm Password"
                placeholder="Confirm your password"
                value={confirmPassword}
                onChangeText={setConfirmPassword}
                secureTextEntry
                isValid={isConfirmPasswordValid && confirmPassword.length > 0}
              />
            </Animated.View>
          )}

          {/* Action Button */}
          <LiquidGlassButton
            title={isSignUpMode ? "Sign Up" : "Log In"}
            onPress={isSignUpMode ? handleSignUp : handleEmailLogin}
            variant="gradient"
            disabled={!canSubmit || isLoggingIn || isSigningUp}
            loading={isLoggingIn || isSigningUp}
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
  tabContainer: {
    marginBottom: spacing["4xl"],
  },
  tabBackground: {
    flexDirection: "row",
    backgroundColor: colors.glassBackground,
    borderRadius: borderRadius.md,
    padding: 4,
    borderWidth: 1,
    borderColor: colors.border,
    overflow: "hidden",
  },
  tabIndicator: {
    position: "absolute",
    top: 4,
    bottom: 4,
    left: 4,
    width: (width - spacing["2xl"] * 2 - 8) / 2,
    backgroundColor: colors.gradientStart,
    borderRadius: borderRadius.md - 4,
  },
  tabContent: {
    flex: 1,
    flexDirection: "row",
    zIndex: 1,
  },
  tabText: {
    flex: 1,
    textAlign: "center",
    paddingVertical: spacing.lg,
    fontSize: typography.fontSize.base,
    fontWeight: typography.fontWeight.medium,
    color: colors.textSecondary,
  },
  tabTextActive: {
    fontWeight: typography.fontWeight.semiBold,
    color: colors.textPrimary,
  },
  welcomeContainer: {
    alignItems: "center",
    marginBottom: spacing["4xl"],
  },
  welcomeTitle: {
    fontSize: typography.fontSize["3xl"],
    fontWeight: typography.fontWeight.bold,
    color: colors.textPrimary,
    marginBottom: spacing.sm,
    textAlign: "center",
  },
  welcomeSubtitle: {
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

