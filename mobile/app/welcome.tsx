import React from "react";
import { View, Text, StyleSheet, Dimensions } from "react-native";
import { LinearGradient } from "expo-linear-gradient";
import { BlurView } from "expo-blur";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import AsyncStorage from "@react-native-async-storage/async-storage";
import Animated, {
  FadeIn,
  FadeInDown,
  FadeInUp,
  SlideInDown,
  withSpring,
  useSharedValue,
  useAnimatedStyle,
  Easing,
} from "react-native-reanimated";

import LiquidGlassButton from "../components/LiquidGlassButton";
import SvgIcon from "../components/SvgIcon";

import { colors, typography, spacing, borderRadius } from "../constants/theme";
import { router } from "expo-router";

const { width, height } = Dimensions.get("window");

export default function Welcome() {
  const insets = useSafeAreaInsets();

  const handleLetsGo = async () => {
    try {
      await AsyncStorage.setItem("hasSeenWelcome", "true");
    } catch (err) {
      console.warn("Error setting welcome flag:", err);
    }
    router.replace("/permissions");
  };

  return (
    <View style={styles.container}>
      {/* BACKGROUND GRADIENT */}
      <LinearGradient
        colors={[colors.background, colors.backgroundSecondary]}
        style={[styles.gradient, { paddingTop: insets.top, paddingBottom: insets.bottom }]}
      />

      {/* BLUR SHAPES */}
      <View style={styles.blurContainer1}>
        <BlurView intensity={80} style={styles.blur1} />
      </View>

      <View style={styles.blurContainer2}>
        <BlurView intensity={60} style={styles.blur2} />
      </View>

      {/* CONTENT */}
      <View style={styles.content}>
        {/* Icon Bubble */}
        <Animated.View
          entering={FadeInDown.delay(200).duration(400).easing(Easing.out(Easing.ease))}
          style={styles.iconContainer}
        >
          <View style={styles.iconBlur}>
            <BlurView intensity={40} style={styles.iconBlurView} />
          </View>

          <View style={styles.icon}>
            <SvgIcon name="icon" size={Math.min(width * 0.25, 100)} color="#FFFFFF" />
          </View>
        </Animated.View>

        {/* Heading */}
        <Animated.View
          entering={FadeInDown.delay(400).duration(400).easing(Easing.out(Easing.ease))}
          style={styles.headingContainer}
        >
          <Text style={styles.heading}>Hey There 👋</Text>
        </Animated.View>

        {/* Description */}
        <Animated.View
          entering={FadeInDown.delay(600).duration(400).easing(Easing.out(Easing.ease))}
          style={styles.descriptionContainer}
        >
          <Text style={styles.description}>
            I'm <Text style={styles.violetText}>Violet</Text>, your AI concierge for Downtown
          </Text>
          <Text style={styles.description}>Brooklyn. Let's find your next vibe.</Text>
        </Animated.View>

        {/* Button */}
        <Animated.View
          entering={SlideInDown.delay(800).duration(400).easing(Easing.out(Easing.ease))}
          style={styles.buttonContainer}
        >
          <LiquidGlassButton title="Let's Go" onPress={handleLetsGo} variant="glass" />
        </Animated.View>
      </View>
    </View>
  );
}

/* ---------------- STYLES ---------------- */

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  gradient: {
    ...StyleSheet.absoluteFillObject,
  },

  /* BACKGROUND BLUR BLOBS */
  blurContainer1: {
    position: "absolute",
    left: -width * 0.2,
    top: 0,
    width: width * 0.75,
    height: width * 0.75,
    borderRadius: 1000000,
    overflow: "hidden",
  },
  blur1: {
    width: "100%",
    height: "100%",
    backgroundColor: colors.accentPurpleMedium,
    opacity: 0.881,
  },
  blurContainer2: {
    position: "absolute",
    left: width * 0.22,
    top: height * 0.3,
    width: width,
    height: width,
    borderRadius: 1000000,
    overflow: "hidden",
  },
  blur2: {
    width: "100%",
    height: "100%",
    backgroundColor: colors.accentBlue,
    opacity: 0.619,
  },

  /* CONTENT */
  content: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
    paddingHorizontal: spacing["2xl"],
    width: "100%",
    minHeight: "100%",
  },

  /* ICON BUBBLE */
  iconContainer: {
    width: width * 0.35,
    height: width * 0.35,
    maxWidth: 140,
    maxHeight: 140,
    marginBottom: spacing["5xl"],
    position: "relative",
  },
  iconBlur: {
    position: "absolute",
    width: "100%",
    height: "100%",
    borderRadius: borderRadius.full,
    overflow: "hidden",
  },
  iconBlurView: {
    width: "100%",
    height: "100%",
    backgroundColor: colors.accentPurple,
    opacity: 0.348,
  },
  icon: {
    width: "100%",
    height: "100%",
    borderRadius: borderRadius.full,
    backgroundColor: colors.backgroundCard,
    justifyContent: "center",
    alignItems: "center",
    borderWidth: 1,
    borderColor: colors.border,
  },

  /* TEXT */
  headingContainer: {
    marginBottom: spacing["2xl"],
  },
  heading: {
    fontSize: typography.fontSize["3xl"],
    fontWeight: typography.fontWeight.bold,
    color: colors.textPrimary,
    textAlign: "center",
    lineHeight: typography.lineHeight["3xl"],
    letterSpacing: -0.64,
    fontFamily: typography.fontFamily,
  },
  descriptionContainer: {
    marginBottom: spacing["6xl"],
    alignItems: "center",
  },
  description: {
    fontSize: typography.fontSize.lg,
    fontWeight: typography.fontWeight.regular,
    color: colors.textSecondary,
    textAlign: "center",
    lineHeight: typography.lineHeight["2xl"],
    marginBottom: spacing.xs,
    paddingHorizontal: spacing.xl,
    fontFamily: typography.fontFamily,
  },
  violetText: {
    fontWeight: typography.fontWeight.semiBold,
    color: colors.textAccent,
    fontFamily: typography.fontFamily,
  },

  /* BUTTON */
  buttonContainer: {
    width: "100%",
    maxWidth: width * 0.85,
    paddingHorizontal: spacing["2xl"],
    marginTop: spacing["5xl"],
  },
});
