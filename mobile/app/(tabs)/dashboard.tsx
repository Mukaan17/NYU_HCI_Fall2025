// mobile/app/(tabs)/dashboard.tsx
import React, { useEffect, useState } from "react";
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  Dimensions,
  TouchableOpacity,
  Platform,
} from "react-native";
import { LinearGradient } from "expo-linear-gradient";
import { BlurView } from "expo-blur";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import Animated, {
  FadeInDown,
  useSharedValue,
  useAnimatedStyle,
  withSpring,
} from "react-native-reanimated";
import { router } from "expo-router";

import RecommendationCard from "../../components/RecommendationCard";
import Notification from "../../components/Notification";
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

  const [showNotification, setShowNotification] = useState(false);
  const [temp, setTemp] = useState<number | null>(null);
  const [weatherEmoji, setWeatherEmoji] = useState<string>("☀️");

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

  /* ---------- SHOW DEMO NOTIFICATION ---------- */
  useEffect(() => {
    const timer = setTimeout(() => {
      setShowNotification(true);
    }, 3000);
    return () => clearTimeout(timer);
  }, []);

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

    return (
      <Animated.View entering={FadeInDown.delay(delay).springify()} style={animatedStyle}>
        <TouchableOpacity
          activeOpacity={0.9}
          onPressIn={() => (scale.value = withSpring(0.95))}
          onPressOut={() => (scale.value = withSpring(1))}
          onPress={() => handleQuickActionPress(prompt)}
          style={styles.quickActionCardWrapper}
        >
          <BlurView intensity={Platform.OS === "ios" ? 50 : 35} tint="dark" style={styles.quickActionBlur}>
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
        </TouchableOpacity>
      </Animated.View>
    );
  };

  return (
    <View style={styles.container}>
      <LinearGradient
        colors={[colors.background, colors.backgroundSecondary, colors.background]}
        locations={[0, 0.5, 1]}
        style={[styles.gradient, { paddingTop: insets.top }]}
      >
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
          <Animated.View entering={FadeInDown.delay(100)} style={styles.header}>
            <Text style={styles.greeting}>Hey there! 👋</Text>
            <Text style={styles.subtitle}>Here's what's happening around you</Text>
          </Animated.View>

          {/* Weather + Status Badges */}
          <Animated.View entering={FadeInDown.delay(200)} style={styles.badgesContainer}>
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
          <Animated.View entering={FadeInDown.delay(300)} style={styles.quickActionsContainer}>
            <Text style={styles.sectionTitle}>Quick Actions</Text>
            <View style={styles.quickActionsGrid}>
              {quickActions.map((qa, index) => (
                <QuickActionCard
                  key={qa.id}
                  icon={qa.icon}
                  label={qa.label}
                  color={qa.color}
                  prompt={qa.prompt}
                  delay={300 + index * 60}
                />
              ))}
            </View>
          </Animated.View>

          {/* Recommendations */}
          <Animated.View entering={FadeInDown.delay(500)} style={styles.recommendationsSection}>
            <Text style={styles.sectionTitle}>Top Recommendations</Text>
            {recommendations.map((rec, index) => (
              <Animated.View key={rec.id} entering={FadeInDown.delay(600 + index * 120)}>
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

      {/* Notification */}
      <Notification
        visible={showNotification}
        onDismiss={() => setShowNotification(false)}
        onViewEvent={() => {
          setShowNotification(false);
          router.push("/(tabs)/chat");
        }}
        notification={{
          message: "You're free till 8 PM — Live jazz at Fulton St starts soon (7 min walk).",
        }}
      />
    </View>
  );
}

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
  },
  subtitle: {
    fontSize: typography.fontSize.lg,
    color: colors.textSecondary,
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
  },

  moodBadge: {
    backgroundColor: colors.whiteOverlay,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: borderRadius.md,
    paddingHorizontal: spacing.xl,
    paddingVertical: spacing.sm,
  },
  moodText: { color: colors.textSecondary, fontWeight: typography.fontWeight.semiBold },

  quickActionsContainer: { marginBottom: spacing["4xl"] },
  sectionTitle: {
    fontSize: typography.fontSize["2xl"],
    color: colors.textPrimary,
    fontWeight: typography.fontWeight.bold,
    marginBottom: spacing["2xl"],
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
  quickActionIcon: { fontSize: 32 },
  quickActionLabel: {
    color: colors.textPrimary,
    fontWeight: typography.fontWeight.semiBold,
  },

  recommendationsSection: { marginBottom: spacing["4xl"] },

  scrollView: {
  flex: 1,
  },
});