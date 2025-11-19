import React from "react";
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  Pressable,
  Linking,
  Alert,
  Dimensions,
  Platform,
} from "react-native";
import { LinearGradient } from "expo-linear-gradient";
import { BlurView } from "expo-blur";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import * as Haptics from "expo-haptics";
import Animated, {
  FadeIn,
  FadeInDown,
  FadeInUp,
  SlideInDown,
  Easing,
} from "react-native-reanimated";

import { colors, typography, spacing, borderRadius } from "../../constants/theme";

const { width, height } = Dimensions.get("window");

export default function Safety() {
  const insets = useSafeAreaInsets();

  /* -------------------------
      ACTION HANDLERS
  ------------------------- */

  const handleCallNYU = () => {
    Linking.openURL("tel:2129982222").catch(() =>
      Alert.alert("Error", "Unable to make phone call")
    );
  };

  const handleCall911 = () => {
    Linking.openURL("tel:911").catch(() =>
      Alert.alert("Error", "Unable to make phone call")
    );
  };

  const handleShareLocation = () => {
    Alert.alert("Share Location", "Location sharing feature coming soon");
  };

  const handleFindSafeRoute = () => {
    Alert.alert("Find Safe Route", "Safe route feature coming soon");
  };

  return (
    <View style={styles.container}>
      <LinearGradient
        colors={[colors.background, colors.backgroundSecondary, colors.background]}
        locations={[0, 0.5, 1]}
        style={[
          styles.gradient,
          { paddingTop: insets.top, paddingBottom: insets.bottom },
        ]}
      >
        {/* ---- BLUR BACKGROUND ---- */}
        <View style={styles.blurContainer}>
          <BlurView intensity={100} style={styles.blur} />
        </View>

        <ScrollView
          contentContainerStyle={styles.scrollContent}
          showsVerticalScrollIndicator={false}
        >
          {/* --------------------------------------
              HEADER
          --------------------------------------- */}
          <Animated.View
            entering={FadeInDown.delay(200).duration(400).easing(Easing.out(Easing.ease))}
            style={styles.header}
          >
            <View style={styles.iconBlurContainer}>
              <BlurView intensity={40} style={styles.iconBlur} />
            </View>

            <View style={styles.iconContainer}>
              <Text style={styles.iconText}>🛡️</Text>
            </View>

            <Text style={styles.title}>Safety Center</Text>
            <Text style={styles.subtitle}>We're here to keep you safe</Text>
          </Animated.View>

          {/* --------------------------------------
              ACTION BUTTONS
          --------------------------------------- */}
          <View style={styles.actionsContainer}>
            {/* CALL NYU PUBLIC SAFETY */}
            <Animated.View entering={FadeInDown.delay(400).duration(400).easing(Easing.out(Easing.ease))}>
              <Pressable
              style={({ pressed }) => [
                styles.emergencyButton,
                pressed && styles.buttonPressed,
              ]}
              onPress={() => {
                if (Platform.OS === "ios") {
                  Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
                }
                handleCallNYU();
              }}
            >
              <View style={styles.emergencyButtonContent}>
                <View style={styles.emergencyIconContainer}>
                  <Text style={styles.emergencyIcon}>📞</Text>
                </View>

                <Text style={styles.emergencyButtonText}>Call NYU Public Safety</Text>
                <Text style={styles.emergencyArrow}>→</Text>
              </View>
            </Pressable>
            </Animated.View>

            {/* SHARE LIVE LOCATION */}
            <Animated.View entering={FadeInDown.delay(500).duration(400).easing(Easing.out(Easing.ease))}>
              <Pressable
              style={({ pressed }) => [
                styles.actionButton,
                pressed && styles.buttonPressed,
              ]}
              onPress={() => {
                if (Platform.OS === "ios") {
                  Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
                }
                handleShareLocation();
              }}
            >
              <LinearGradient
                colors={[colors.gradientStart, colors.gradientEnd]}
                style={styles.actionButtonGradient}
              >
                <View style={styles.actionButtonContent}>
                  <View style={styles.actionIconContainer}>
                    <Text style={styles.actionIcon}>📍</Text>
                  </View>

                  <View style={styles.actionTextContainer}>
                    <Text style={styles.actionButtonText}>Share Live Location</Text>
                    <Text style={styles.actionButtonSubtext}>With trusted contacts</Text>
                  </View>
                </View>
              </LinearGradient>
            </Pressable>
            </Animated.View>

            {/* FIND SAFE ROUTE */}
            <Animated.View entering={FadeInDown.delay(600).duration(400).easing(Easing.out(Easing.ease))}>
              <Pressable
              style={({ pressed }) => [
                styles.actionButton,
                pressed && styles.buttonPressed,
              ]}
              onPress={() => {
                if (Platform.OS === "ios") {
                  Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
                }
                handleFindSafeRoute();
              }}
            >
              <LinearGradient
                colors={[colors.gradientBlueStart, colors.gradientBlueEnd]}
                style={styles.actionButtonGradient}
              >
                <View style={styles.actionButtonContent}>
                  <View style={styles.actionIconContainer}>
                    <Text style={styles.actionIcon}>🛣️</Text>
                  </View>

                  <View style={styles.actionTextContainer}>
                    <Text style={styles.actionButtonText}>Find a Safe Route Home</Text>
                    <Text style={styles.actionButtonSubtext}>Well-lit paths</Text>
                  </View>
                </View>
              </LinearGradient>
            </Pressable>
            </Animated.View>
          </View>

          {/* --------------------------------------
              EMERGENCY CONTACTS
          --------------------------------------- */}
          <Animated.View
            entering={FadeInUp.delay(700).duration(400).easing(Easing.out(Easing.ease))}
            style={styles.contactsContainer}
          >
            {/* 911 */}
            <View style={styles.contactRow}>
              <Text style={styles.contactLabel}>Emergency Services</Text>
              <Pressable
                onPress={() => {
                  if (Platform.OS === "ios") {
                    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
                  }
                  handleCall911();
                }}
              >
                <Text style={styles.contactValue}>911</Text>
              </Pressable>
            </View>

            <View style={styles.contactDivider} />

            {/* NYU PUBLIC SAFETY */}
            <View style={styles.contactRow}>
              <Text style={styles.contactLabel}>NYU Public Safety</Text>
              <Pressable
                onPress={() => {
                  if (Platform.OS === "ios") {
                    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
                  }
                  handleCallNYU();
                }}
              >
                <Text style={styles.contactValue}>(212) 998-2222</Text>
              </Pressable>
            </View>
          </Animated.View>
        </ScrollView>
      </LinearGradient>
    </View>
  );
}

/* -----------------------------------------------------
      STYLES — MATCHING JS EXACTLY
----------------------------------------------------- */
const styles = StyleSheet.create({
  container: { flex: 1 },
  gradient: { flex: 1 },

  blurContainer: {
    position: "absolute",
    left: 0,
    top: 0,
    width: width,
    height: width,
    borderRadius: 900,
    overflow: "hidden",
  },
  blur: {
    width: "100%",
    height: "100%",
    backgroundColor: colors.accentError,
    opacity: 0.05,
  },

  scrollContent: {
    paddingHorizontal: spacing["2xl"],
    paddingTop: spacing["6xl"],
    paddingBottom: 180,
  },

  /* ----- HEADER ----- */
  header: {
    alignItems: "center",
    marginBottom: spacing["6xl"],
  },
  iconBlurContainer: {
    position: "absolute",
    width: width * 0.2,
    height: width * 0.2,
    borderRadius: borderRadius.lg,
    overflow: "hidden",
  },
  iconBlur: {
    width: "100%",
    height: "100%",
    backgroundColor: colors.accentError,
    opacity: 0.1,
  },
  iconContainer: {
    width: width * 0.2,
    height: width * 0.2,
    borderRadius: borderRadius.lg,
    backgroundColor: colors.backgroundCard,
    borderWidth: 1,
    borderColor: colors.border,
    justifyContent: "center",
    alignItems: "center",
    marginBottom: spacing["2xl"],
  },
  iconText: {
    fontSize: Math.min(width * 0.1, 40),
  },
  title: {
    fontSize: typography.fontSize["3xl"],
    fontWeight: typography.fontWeight.bold,
    color: colors.textPrimary,
    marginBottom: spacing.xs,
    fontFamily: typography.fontFamily,
  },
  subtitle: {
    fontSize: typography.fontSize.lg,
    color: colors.textSecondary,
    fontFamily: typography.fontFamily,
  },
  buttonPressed: {
    opacity: 0.8,
  },

  /* ----- ACTION BUTTONS ----- */
  actionsContainer: {
    gap: spacing["2xl"],
    marginBottom: spacing["4xl"],
  },

  emergencyButton: {
    borderWidth: 2,
    borderColor: colors.accentErrorBorder,
    borderRadius: borderRadius.md,
    padding: spacing["2xl"],
  },
  emergencyButtonContent: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
  },
  emergencyIconContainer: {
    width: 48,
    height: 48,
    borderRadius: borderRadius.md,
    backgroundColor: colors.accentError,
    justifyContent: "center",
    alignItems: "center",
  },
  emergencyIcon: { fontSize: 24 },
  emergencyButtonText: {
    flex: 1,
    marginLeft: spacing["2xl"],
    fontSize: typography.fontSize.lg,
    fontWeight: typography.fontWeight.semiBold,
    color: colors.textError,
    fontFamily: typography.fontFamily,
  },
  emergencyArrow: {
    fontSize: 20,
    color: colors.textPrimary,
  },

  actionButton: {
    borderRadius: borderRadius.md,
    overflow: "hidden",
  },
  actionButtonGradient: { padding: spacing["3xl"] },
  actionButtonContent: {
    flexDirection: "row",
    alignItems: "center",
    gap: spacing["2xl"],
  },
  actionIconContainer: {
    width: 48,
    height: 48,
    borderRadius: borderRadius.md,
    backgroundColor: colors.whiteOverlayMedium,
    justifyContent: "center",
    alignItems: "center",
  },
  actionIcon: { fontSize: 24 },
  actionTextContainer: { flex: 1 },
  actionButtonText: {
    fontSize: typography.fontSize.lg,
    fontWeight: typography.fontWeight.semiBold,
    color: colors.textPrimary,
    marginBottom: spacing.xs,
    fontFamily: typography.fontFamily,
  },
  actionButtonSubtext: {
    fontSize: typography.fontSize.sm,
    color: "rgba(255,255,255,0.7)",
    fontFamily: typography.fontFamily,
  },

  /* ----- CONTACTS ----- */
  contactsContainer: {
    borderWidth: 1,
    borderColor: colors.border,
    padding: spacing["3xl"],
    borderRadius: borderRadius.lg,
    backgroundColor: colors.glassBackground,
  },
  contactRow: {
    flexDirection: "row",
    justifyContent: "space-between",
    paddingVertical: spacing["2xl"],
  },
  contactLabel: {
    color: colors.textSecondary,
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily,
  },
  contactValue: {
    color: colors.textPrimary,
    fontSize: typography.fontSize.md,
    fontWeight: typography.fontWeight.semiBold,
    fontFamily: typography.fontFamily,
  },
  contactDivider: {
    height: 1,
    backgroundColor: colors.whiteOverlay,
    marginVertical: spacing.xs,
  },
});