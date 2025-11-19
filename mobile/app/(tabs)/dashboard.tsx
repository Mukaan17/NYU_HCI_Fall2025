// mobile/app/(tabs)/dashboard.tsx
import React, { useEffect, useState, useRef } from "react";
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  Dimensions,
  Pressable,
  Platform,
} from "react-native";
import { LinearGradient } from "expo-linear-gradient";
import { BlurView } from "expo-blur";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import Animated, {
  FadeInDown,
  FadeIn,
  FadeOut,
  SlideInDown,
  SlideOutUp,
  useSharedValue,
  useAnimatedStyle,
  withSpring,
  withTiming,
  Easing,
} from "react-native-reanimated";
import { router } from "expo-router";
import { LiquidGlassView, isLiquidGlassSupported } from "@callstack/liquid-glass";
import * as Haptics from "expo-haptics";
import { SymbolView } from "expo-symbols";
import { Modal } from "react-native";

import RecommendationCard from "../../components/RecommendationCard";
import { colors, typography, spacing, borderRadius } from "../../constants/theme";
import useLocation from "../../hooks/useLocation";
import { getWeather } from "../../utils/getWeather";

const { width, height } = Dimensions.get("window");

type QuickAction = {
  id: number;
  icon: string;
  label: string;
  color: string;
  prompt: string;
};

export default function Dashboard() {
  const insets = useSafeAreaInsets();
  const { location } = useLocation();
  const hasAnimated = useRef(false);

  const [temp, setTemp] = useState<number | null>(null);
  const [weatherEmoji, setWeatherEmoji] = useState<string>("☀️");
  const [showProfileMenu, setShowProfileMenu] = useState(false);
  const menuScale = useSharedValue(0);
  const menuOpacity = useSharedValue(0);

  useEffect(() => {
    // Mark that initial animations have been shown
    const timer = setTimeout(() => {
      hasAnimated.current = true;
    }, 1000);
    return () => clearTimeout(timer);
  }, []);

  /* ---------------- WEATHER ---------------- */
  useEffect(() => {
    async function loadWeather() {
      if (!location) return;

      const w = await getWeather(location.latitude, location.longitude);
      if (w) {
        setTemp(w.temp);
        setWeatherEmoji(w.emoji);
      }
    }
    loadWeather();
  }, [location]);

  /* ---------- SAMPLE TOP RECOMMENDATIONS ---------- */
  const recommendations = [
    {
      id: 1,
      title: "Fulton Jazz Lounge",
      description: "Live jazz tonight at 8 PM",
      image: "https://via.placeholder.com/96",
      walkTime: "7 min walk",
      popularity: "High",
    },
    {
      id: 2,
      title: "Brooklyn Rooftop",
      description: "Great vibes & skyline views",
      image: "https://via.placeholder.com/96",
      walkTime: "12 min walk",
      popularity: "Medium",
    },
    {
      id: 3,
      title: "Butler Café",
      description: "Great for study breaks",
      image: "https://via.placeholder.com/96",
      walkTime: "3 min walk",
      popularity: "Low",
    },
  ];

  /* ---------------- QUICK ACTIONS ---------------- */
  const quickActions: QuickAction[] = [
    { id: 1, icon: "🍔", label: "Quick Bites", color: colors.accentPurple, prompt: "quick_bites" },
    { id: 2, icon: "☕", label: "Chill Cafes", color: colors.accentPurple, prompt: "chill_cafes" },
    { id: 3, icon: "🎵", label: "Events", color: colors.accentBlue, prompt: "events" },
    { id: 4, icon: "🎯", label: "Explore", color: colors.accentBlue, prompt: "explore" },
  ];

  const handleQuickActionPress = (category: string) => {
    router.push(`/quick/${category}`);
  };

  const QuickActionCard = ({
    icon,
    label,
    color,
    prompt,
    delay = 0,
  }: {
    icon: string;
    label: string;
    color: string;
    prompt: string;
    delay?: number;
  }) => {
    const scale = useSharedValue(1);
    const animatedStyle = useAnimatedStyle(() => ({
      transform: [{ scale: scale.value }],
    }));

    const hasLiquidGlass = isLiquidGlassSupported;

    return (
      <Animated.View
        entering={hasAnimated.current ? undefined : FadeInDown.delay(delay).duration(400).easing(Easing.out(Easing.ease))}
        style={animatedStyle}
      >
        <Pressable
          onPressIn={() => (scale.value = withSpring(0.96))}
          onPressOut={() => (scale.value = withSpring(1))}
          onPress={() => {
            if (Platform.OS === "ios") {
              Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
            }
            handleQuickActionPress(prompt);
          }}
          style={styles.quickActionCardWrapper}
        >
          {hasLiquidGlass && Platform.OS === "ios" ? (
            <LiquidGlassView
              effect="regular"
              style={styles.quickActionCardLiquid}
              tintColor={`${color}55`}
            >
              <Text style={styles.quickActionIcon}>{icon}</Text>
              <Text style={styles.quickActionLabel}>{label}</Text>
            </LiquidGlassView>
          ) : (
            <>
          <BlurView intensity={Platform.OS === "ios" ? 50 : 35} tint="systemChromeMaterialDark" style={styles.quickActionBlur}>
            <View style={[styles.quickActionGlassOverlay, { backgroundColor: `${color}30` }]} />
          </BlurView>

          <LinearGradient
            colors={[`${color}40`, `${color}20`]}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 1 }}
            style={styles.quickActionCard}
          >
            <Text style={styles.quickActionIcon}>{icon}</Text>
            <Text style={styles.quickActionLabel}>{label}</Text>
          </LinearGradient>
            </>
          )}
        </Pressable>
      </Animated.View>
    );
  };

  const handleProfilePress = () => {
    if (Platform.OS === "ios") {
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    }
    setShowProfileMenu(true);
    // Animate menu in - faster and less bouncy
    menuScale.value = withSpring(1, { damping: 40, stiffness: 500 });
    menuOpacity.value = withTiming(1, { duration: 150, easing: Easing.out(Easing.ease) });
  };

  const handleMenuClose = () => {
    if (Platform.OS === "ios") {
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    }
    // Animate menu out - faster
    menuScale.value = withTiming(0.9, { duration: 120, easing: Easing.in(Easing.ease) });
    menuOpacity.value = withTiming(0, { duration: 120, easing: Easing.in(Easing.ease) });
    setTimeout(() => {
      setShowProfileMenu(false);
      menuScale.value = 0;
      menuOpacity.value = 0;
    }, 120);
  };

  const menuAnimatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: menuScale.value }],
    opacity: menuOpacity.value,
  }));

  const handleMenuAction = (action: string) => {
    if (Platform.OS === "ios") {
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    }
    setShowProfileMenu(false);
    // Handle navigation or actions here
    console.log(`Selected: ${action}`);
  };

  const hasLiquidGlass = isLiquidGlassSupported;

  return (
    <View style={styles.container}>
      <LinearGradient
        colors={[colors.background, colors.backgroundSecondary, colors.background]}
        locations={[0, 0.5, 1]}
        style={[styles.gradient, { paddingTop: insets.top }]}
      >
        {/* Profile Circle Button */}
        <Pressable
          style={[
            styles.profileButton,
            {
              top:
                insets.top +
                spacing["3xl"] +
                typography.fontSize["3xl"] / 2 -
                24 + 4, // Center with greeting text (24 = half of 48px circle, +4 to lower it)
            },
          ]}
          onPress={handleProfilePress}
        >
          <View style={styles.profileCircle}>
            {Platform.OS === "ios" ? (
              <SymbolView
                name="person.crop.circle"
                size={32}
                type="hierarchical"
                tintColor={colors.textPrimary}
              />
            ) : (
              <Text style={styles.profileMemoji}>😊</Text>
            )}
          </View>
        </Pressable>

        {/* Decorative Blurs */}
        <View style={styles.blurContainer1}>
          <BlurView intensity={80} style={styles.blur1} />
        </View>
        <View style={styles.blurContainer2}>
          <BlurView intensity={60} style={styles.blur2} />
        </View>

        <ScrollView
          style={styles.scrollView}
          contentContainerStyle={styles.scrollContent}
          showsVerticalScrollIndicator={false}
        >
          {/* Greeting Header */}
          <Animated.View
            entering={hasAnimated.current ? undefined : FadeInDown.delay(100)}
            style={styles.header}
          >
            <Text style={styles.greeting}>Hey there! 👋</Text>
            <Text style={styles.subtitle}>Here's what's happening around you</Text>
          </Animated.View>

          {/* Weather + Status Badges */}
          <Animated.View
            entering={hasAnimated.current ? undefined : FadeInDown.delay(200)}
            style={styles.badgesContainer}
          >
            <View style={styles.weatherBadge}>
              <Text style={styles.weatherText}>{weatherEmoji} {temp ? `${temp}°F` : "—"}</Text>
            </View>

            <View style={styles.scheduleBadge}>
              <Text style={styles.scheduleText}>Free until 6:30 PM</Text>
            </View>

            <View style={styles.moodBadge}>
              <Text style={styles.moodText}>Chill ✨</Text>
            </View>
          </Animated.View>

          {/* Quick Actions */}
          <Animated.View
            entering={hasAnimated.current ? undefined : FadeInDown.delay(300)}
            style={styles.quickActionsContainer}
          >
            <Text style={styles.sectionTitle}>Quick Actions</Text>
            <View style={styles.quickActionsGrid}>
              {quickActions.map((qa, index) => (
                <QuickActionCard
                  key={qa.id}
                  icon={qa.icon}
                  label={qa.label}
                  color={qa.color}
                  prompt={qa.prompt}
                  delay={hasAnimated.current ? 0 : 300 + index * 60}
                />
              ))}
            </View>
          </Animated.View>

          {/* Recommendations */}
          <Animated.View
            entering={hasAnimated.current ? undefined : FadeInDown.delay(500)}
            style={styles.recommendationsSection}
          >
            <Text style={styles.sectionTitle}>Top Recommendations</Text>
            {recommendations.map((rec, index) => (
              <Animated.View
                key={rec.id}
                entering={hasAnimated.current ? undefined : FadeInDown.delay(600 + index * 120)}
              >
                <RecommendationCard
                  title={rec.title}
                  description={rec.description}
                  walkTime={rec.walkTime}
                  popularity={rec.popularity}
                  image={rec.image}
                />
              </Animated.View>
            ))}
          </Animated.View>
        </ScrollView>
      </LinearGradient>

      {/* Profile Dropdown Menu */}
      <Modal
        visible={showProfileMenu}
        transparent
        animationType="none"
        onRequestClose={handleMenuClose}
      >
        <Animated.View
          entering={FadeIn.duration(150)}
          exiting={FadeOut.duration(150)}
          style={StyleSheet.absoluteFill}
        >
          <Pressable style={styles.menuOverlay} onPress={handleMenuClose}>
            <Animated.View
              style={[
                styles.menuContainer,
                {
                  top:
                    insets.top +
                    spacing["3xl"] +
                    typography.fontSize["3xl"] / 2 -
                    24 +
                    4 +
                    48 +
                    spacing.md,
                  right: spacing["2xl"],
                },
                menuAnimatedStyle,
              ]}
            >
              <Pressable onPress={(e) => e.stopPropagation()}>
                {hasLiquidGlass && Platform.OS === "ios" ? (
                  <LiquidGlassView
                    effect="regular"
                    style={styles.menuContent}
                    tintColor="rgba(28, 37, 65, 0.95)"
                  >
                    <MenuItems onAction={handleMenuAction} />
                  </LiquidGlassView>
                ) : (
                  <View style={styles.menuContent}>
                    <BlurView
                      intensity={Platform.OS === "ios" ? 100 : 60}
                      tint="systemChromeMaterialDark"
                      style={StyleSheet.absoluteFill}
                    />
                    <View style={styles.menuContentOverlay} />
                    <MenuItems onAction={handleMenuAction} />
                  </View>
                )}
              </Pressable>
            </Animated.View>
          </Pressable>
        </Animated.View>
      </Modal>
    </View>
  );
}

// Profile Menu Component
const MenuItems = ({
  onAction,
}: {
  onAction: (action: string) => void;
}) => {
  const menuItems = [
    { id: "account", label: "Account Settings", icon: "gearshape.fill" },
    { id: "about", label: "About", icon: "info.circle" },
  ];

  return (
    <>
      {/* Profile Section */}
      <Animated.View
        entering={FadeInDown.delay(100).duration(400).easing(Easing.out(Easing.ease))}
        style={styles.profileSection}
      >
        <View style={styles.profileAvatarContainer}>
          <View style={styles.profileAvatar}>
            {Platform.OS === "ios" ? (
              <SymbolView
                name="person.fill"
                size={40}
                type="hierarchical"
                tintColor={colors.textPrimary}
              />
            ) : (
              <Text style={styles.profileAvatarText}>A</Text>
            )}
          </View>
        </View>
        <View style={styles.profileInfo}>
          <View style={styles.profileHeader}>
            <Text style={styles.profileName}>Antoine</Text>
            <View style={styles.proBadge}>
              <Text style={styles.proBadgeText}>PRO</Text>
            </View>
          </View>
          <Text style={styles.profileEmail}>antoine@domain.com</Text>
        </View>
      </Animated.View>

      {/* Separator */}
      <Animated.View
        entering={FadeIn.delay(150)}
        style={styles.menuSeparator}
      />

      {/* Menu Items */}
      {menuItems.map((item, index) => (
        <Animated.View
          key={item.id}
          entering={FadeInDown.delay(200 + index * 50).duration(400).easing(Easing.out(Easing.ease))}
        >
          <Pressable
            onPress={() => onAction(item.id)}
            style={({ pressed }) => [
              styles.menuItem,
              pressed && styles.menuItemPressed,
              index < menuItems.length - 1 && styles.menuItemBorder,
            ]}
          >
            <View style={styles.menuItemContent}>
              {Platform.OS === "ios" ? (
                <SymbolView
                  name={item.icon}
                  size={20}
                  type="hierarchical"
                  tintColor={colors.textPrimary}
                />
              ) : (
                <View style={styles.menuItemIconPlaceholder} />
              )}
              <Text style={styles.menuItemText}>{item.label}</Text>
            </View>
            {Platform.OS === "ios" ? (
              <SymbolView
                name="chevron.right"
                size={14}
                type="hierarchical"
                tintColor="rgba(255, 255, 255, 0.3)"
              />
            ) : (
              <Text style={styles.menuChevron}>›</Text>
            )}
          </Pressable>
        </Animated.View>
      ))}

      {/* Separator */}
      <Animated.View
        entering={FadeIn.delay(400)}
        style={styles.menuSeparator}
      />

      {/* Logout */}
      <Animated.View entering={FadeInDown.delay(450).duration(400).easing(Easing.out(Easing.ease))}>
        <Pressable
        onPress={() => onAction("logout")}
        style={({ pressed }) => [
          styles.menuItem,
          pressed && styles.menuItemPressed,
        ]}
      >
        <View style={styles.menuItemContent}>
          {Platform.OS === "ios" ? (
            <SymbolView
              name="rectangle.portrait.and.arrow.right"
              size={20}
              type="hierarchical"
              tintColor={colors.textPrimary}
            />
          ) : (
            <View style={styles.menuItemIconPlaceholder} />
          )}
          <Text style={styles.menuItemText}>Logout</Text>
        </View>
        {Platform.OS === "ios" ? (
          <SymbolView
            name="chevron.right"
            size={14}
            type="hierarchical"
            tintColor="rgba(255, 255, 255, 0.3)"
          />
        ) : (
            <Text style={styles.menuChevron}>›</Text>
          )}
        </Pressable>
      </Animated.View>
    </>
  );
};

/* ------------------------------ STYLES ------------------------------ */

const styles = StyleSheet.create({
  container: { flex: 1 },
  gradient: { flex: 1 },

  blurContainer1: {
    position: "absolute",
    left: -width * 0.2,
    top: height * 0.1,
    width: width * 0.75,
    height: width * 0.75,
    borderRadius: 9999,
    overflow: "hidden",
  },
  blur1: {
    width: "100%",
    height: "100%",
    backgroundColor: colors.accentPurpleMedium,
    opacity: 0.85,
  },
  blurContainer2: {
    position: "absolute",
    left: width * 0.22,
    top: height * 0.35,
    width,
    height: width,
    borderRadius: 9999,
    overflow: "hidden",
  },
  blur2: {
    width: "100%",
    height: "100%",
    backgroundColor: colors.accentBlue,
    opacity: 0.6,
  },

  scrollContent: {
    paddingHorizontal: spacing["2xl"],
    paddingTop: spacing["3xl"],
    paddingBottom: 120,
  },

  header: { marginBottom: spacing["3xl"] },
  greeting: {
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

  badgesContainer: {
    flexDirection: "row",
    justifyContent: "center",
    gap: spacing.lg,
    marginBottom: spacing["4xl"],
  },

  weatherBadge: {
    flexDirection: "row",
    alignItems: "center",
    backgroundColor: colors.accentBlue,
    borderWidth: 1,
    borderColor: colors.accentBlueMedium,
    borderRadius: borderRadius.md,
    paddingHorizontal: spacing.xl,
    paddingVertical: spacing.sm,
  },
  weatherText: {
    color: colors.textBlue,
    fontWeight: typography.fontWeight.semiBold,
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily,
  },

  scheduleBadge: {
    flexDirection: "row",
    alignItems: "center",
    backgroundColor: colors.glassBackground,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: borderRadius.md,
    paddingHorizontal: spacing.xl,
    paddingVertical: spacing.sm,
  },
  scheduleText: {
    color: colors.textPrimary,
    fontWeight: typography.fontWeight.semiBold,
    fontFamily: typography.fontFamily,
  },

  moodBadge: {
    backgroundColor: colors.whiteOverlay,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: borderRadius.md,
    paddingHorizontal: spacing.xl,
    paddingVertical: spacing.sm,
  },
  moodText: {
    color: colors.textSecondary,
    fontWeight: typography.fontWeight.semiBold,
    fontFamily: typography.fontFamily,
  },

  quickActionsContainer: { marginBottom: spacing["4xl"] },
  sectionTitle: {
    fontSize: typography.fontSize["2xl"],
    color: colors.textPrimary,
    fontWeight: typography.fontWeight.bold,
    marginBottom: spacing["2xl"],
    fontFamily: typography.fontFamily,
  },
  quickActionsGrid: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: spacing["2xl"],
  },

  quickActionCardWrapper: {
    width: (width - spacing["2xl"] * 2 - spacing["2xl"]) / 2,
    aspectRatio: 1.2,
    borderRadius: borderRadius.md,
    overflow: "hidden",
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.15)",
  },
  quickActionBlur: { ...StyleSheet.absoluteFillObject },
  quickActionGlassOverlay: { ...StyleSheet.absoluteFillObject },
  quickActionCard: {
    width: "100%",
    height: "100%",
    padding: spacing["2xl"],
    justifyContent: "center",
    alignItems: "center",
  },
  quickActionCardLiquid: {
    width: "100%",
    height: "100%",
    padding: spacing["2xl"],
    justifyContent: "center",
    alignItems: "center",
    borderRadius: borderRadius.md,
  },
  quickActionIcon: { fontSize: 32 },
  quickActionLabel: {
    color: colors.textPrimary,
    fontWeight: typography.fontWeight.semiBold,
    fontFamily: typography.fontFamily,
  },

  recommendationsSection: { marginBottom: spacing["4xl"] },

  scrollView: {
  flex: 1,
  },
  profileButton: {
    position: "absolute",
    right: spacing["2xl"],
    zIndex: 10,
  },
  profileCircle: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: "transparent",
    borderWidth: 2,
    borderColor: "rgba(255, 255, 255, 0.2)",
    justifyContent: "center",
    alignItems: "center",
    overflow: "hidden",
    ...Platform.select({
      ios: {
        shadowColor: "#000",
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.2,
        shadowRadius: 4,
      },
      android: {
        elevation: 4,
      },
    }),
  },
  profileMemoji: {
    fontSize: 28,
  },
  menuOverlay: {
    flex: 1,
    backgroundColor: "rgba(0, 0, 0, 0.4)",
  },
  menuContainer: {
    position: "absolute",
    width: 280,
    borderRadius: borderRadius.md,
    overflow: "hidden",
    borderWidth: 0.5,
    borderColor: "rgba(255, 255, 255, 0.1)",
    ...Platform.select({
      ios: {
        shadowColor: "#000",
        shadowOffset: { width: 0, height: 8 },
        shadowOpacity: 0.4,
        shadowRadius: 20,
      },
      android: {
        elevation: 12,
      },
    }),
  },
  menuContent: {
    borderRadius: borderRadius.md,
    overflow: "hidden",
    backgroundColor: "rgba(28, 37, 65, 0.7)",
  },
  menuContentOverlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: "rgba(28, 37, 65, 0.6)",
  },
  profileSection: {
    flexDirection: "row",
    padding: spacing["3xl"],
    alignItems: "center",
    gap: spacing["2xl"],
  },
  profileAvatarContainer: {
    width: 56,
    height: 56,
  },
  profileAvatar: {
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: "rgba(108, 99, 255, 0.3)",
    borderWidth: 2,
    borderColor: "rgba(255, 255, 255, 0.2)",
    justifyContent: "center",
    alignItems: "center",
    overflow: "hidden",
  },
  profileAvatarText: {
    fontSize: 24,
    fontWeight: typography.fontWeight.bold,
    color: colors.textPrimary,
    fontFamily: typography.fontFamily,
  },
  profileInfo: {
    flex: 1,
    gap: spacing.xs,
  },
  profileHeader: {
    flexDirection: "row",
    alignItems: "center",
    gap: spacing.md,
  },
  profileName: {
    fontSize: typography.fontSize.xl,
    fontWeight: typography.fontWeight.bold,
    color: colors.textPrimary,
    fontFamily: typography.fontFamily,
  },
  proBadge: {
    backgroundColor: colors.gradientBlueStart,
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.xs,
    borderRadius: borderRadius.full,
  },
  proBadgeText: {
    fontSize: typography.fontSize.xs,
    fontWeight: typography.fontWeight.bold,
    color: colors.textPrimary,
    fontFamily: typography.fontFamily,
  },
  profileEmail: {
    fontSize: typography.fontSize.base,
    color: colors.textSecondary,
    fontFamily: typography.fontFamily,
  },
  menuSeparator: {
    height: 0.5,
    backgroundColor: "rgba(255, 255, 255, 0.1)",
    marginHorizontal: spacing["2xl"],
  },
  menuItem: {
    paddingVertical: spacing["2xl"],
    paddingHorizontal: spacing["3xl"],
    minHeight: 56,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
  },
  menuItemPressed: {
    opacity: 0.7,
  },
  menuItemBorder: {
    borderBottomWidth: 0.5,
    borderBottomColor: "rgba(255, 255, 255, 0.1)",
  },
  menuItemContent: {
    flexDirection: "row",
    alignItems: "center",
    gap: spacing["2xl"],
    flex: 1,
  },
  menuItemIconPlaceholder: {
    width: 20,
    height: 20,
    backgroundColor: colors.textPrimary,
    borderRadius: 4,
  },
  menuItemText: {
    fontSize: typography.fontSize.lg,
    fontWeight: typography.fontWeight.medium,
    color: colors.textPrimary,
    fontFamily: typography.fontFamily,
  },
  menuChevron: {
    fontSize: 18,
    color: "rgba(255, 255, 255, 0.3)",
    fontWeight: "300",
  },
});