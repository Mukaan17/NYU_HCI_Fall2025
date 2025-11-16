import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  Dimensions,
  TouchableOpacity,
  Platform,
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { BlurView } from 'expo-blur';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import Animated, {
  FadeInDown,
  useSharedValue,
  useAnimatedStyle,
  withSpring,
} from 'react-native-reanimated';

import RecommendationCard from '../../components/RecommendationCard.js';
import { colors, typography, spacing, borderRadius, shadows } from '../../constants/theme';

const { width, height } = Dimensions.get('window');

export default function Dashboard() {
  const insets = useSafeAreaInsets();

  const recommendations = [
    {
      id: 1,
      title: 'Fulton Jazz Lounge',
      description: 'Live jazz tonight at 8 PM',
      image: 'https://via.placeholder.com/96',
      walkTime: '7 min walk',
      popularity: 'High',
    },
    {
      id: 2,
      title: 'Brooklyn Rooftop',
      description: 'Great vibes & skyline views',
      image: 'https://via.placeholder.com/96',
      walkTime: '12 min walk',
      popularity: 'Medium',
    },
    {
      id: 3,
      title: 'Butler Café',
      description: 'Great for study breaks',
      image: 'https://via.placeholder.com/96',
      walkTime: '3 min walk',
      popularity: 'Low',
    },
  ];

  const quickActions = [
    { id: 1, icon: '🍔', label: 'Find Food', color: colors.accentPurple },
    { id: 2, icon: '🎵', label: 'Events', color: colors.accentBlue },
    { id: 3, icon: '☕', label: 'Cafés', color: colors.accentPurple },
    { id: 4, icon: '🎯', label: 'Explore', color: colors.accentBlue },
  ];

  const QuickActionCard = ({
    icon,
    label,
    color,
    delay = 0,
  }: {
    icon: string;
    label: string;
    color: string;
    delay?: number;
  }) => {
    const scale = useSharedValue(1);

    const animatedStyle = useAnimatedStyle(() => ({
      transform: [{ scale: scale.value }],
    }));

    const handlePressIn = () => (scale.value = withSpring(0.94));
    const handlePressOut = () => (scale.value = withSpring(1));

    return (
      <Animated.View
        entering={FadeInDown.delay(delay).springify()}
        style={animatedStyle}
      >
        <TouchableOpacity
          onPressIn={handlePressIn}
          onPressOut={handlePressOut}
          activeOpacity={0.9}
          style={styles.quickActionCardWrapper}
        >
          <BlurView intensity={Platform.OS === 'ios' ? 50 : 35} style={styles.quickActionBlur} />

          <LinearGradient
            colors={[color + '40', color + '20']}
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
        style={[styles.gradient, { paddingTop: insets.top, paddingBottom: insets.bottom }]}
      >
        <ScrollView style={styles.scrollView} contentContainerStyle={styles.scrollContent}>
          <Animated.View entering={FadeInDown.delay(100)} style={styles.header}>
            <Text style={styles.greeting}>Hey there! 👋</Text>
            <Text style={styles.subtitle}>Here's what's happening around you</Text>
          </Animated.View>

          <Animated.View entering={FadeInDown.delay(200)} style={styles.badgesContainer}>
            <View style={styles.weatherBadge}>
              <Text style={styles.weatherIcon}>🌡️</Text>
              <Text style={styles.weatherText}>72°F</Text>
            </View>
            <View style={styles.scheduleBadge}>
              <Text style={styles.scheduleIcon}>⏰</Text>
              <Text style={styles.scheduleText}>Free until 6:30 PM</Text>
            </View>
            <View style={styles.moodBadge}>
              <Text style={styles.moodText}>Chill ✨</Text>
            </View>
          </Animated.View>

          <Animated.View entering={FadeInDown.delay(300)} style={styles.quickActionsContainer}>
            <Text style={styles.sectionTitle}>Quick Actions</Text>
            <View style={styles.quickActionsGrid}>
              {quickActions.map((action, index) => (
                <QuickActionCard
                  key={action.id}
                  icon={action.icon}
                  label={action.label}
                  color={action.color}
                  delay={300 + index * 80}
                />
              ))}
            </View>
          </Animated.View>

          <Animated.View entering={FadeInDown.delay(500)} style={styles.recommendationsSection}>
            <Text style={styles.sectionTitle}>Top Recommendations</Text>

            {recommendations.map((rec, index) => (
              <Animated.View key={rec.id} entering={FadeInDown.delay(600 + index * 120)}>
                <RecommendationCard
                  title={rec.title}
                  description={rec.description}
                  image={rec.image}
                  walkTime={rec.walkTime}
                  popularity={rec.popularity}
                />
              </Animated.View>
            ))}
          </Animated.View>
        </ScrollView>
      </LinearGradient>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  gradient: { flex: 1 },
  scrollView: { flex: 1 },
  scrollContent: {
    paddingHorizontal: spacing['2xl'],
    paddingTop: spacing['3xl'],
    paddingBottom: 180,
  },
  header: { marginBottom: spacing['3xl'] },
  greeting: {
    fontSize: typography.fontSize['3xl'],
    fontWeight: typography.fontWeight.bold,
    color: colors.textPrimary,
  },
  subtitle: {
    fontSize: typography.fontSize.lg,
    color: colors.textSecondary,
  },
  badgesContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    gap: spacing.xl,
    marginBottom: spacing['4xl'],
  },
  weatherBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.accentBlue,
    borderRadius: borderRadius.md,
    paddingHorizontal: spacing['2xl'],
    paddingVertical: spacing.xs,
  },
  weatherIcon: { fontSize: 16 },
  weatherText: {
    fontSize: typography.fontSize.sm,
    color: colors.textBlue,
  },
  scheduleBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: borderRadius.md,
    paddingHorizontal: spacing['2xl'],
    paddingVertical: spacing.xs,
    borderWidth: 1,
    borderColor: colors.border,
    flex: 1,
  },
  scheduleIcon: { fontSize: 16 },
  scheduleText: {
    fontSize: typography.fontSize.sm,
    fontWeight: typography.fontWeight.semiBold,
    color: colors.textPrimary,
  },
  moodBadge: {
    backgroundColor: colors.whiteOverlay,
    borderRadius: borderRadius.md,
    paddingHorizontal: spacing['2xl'],
    paddingVertical: spacing.xs,
  },
  moodText: {
    color: colors.textSecondary,
    fontSize: typography.fontSize.sm,
  },

  /* QUICK ACTIONS */
  quickActionsContainer: { marginBottom: spacing['4xl'] },
  sectionTitle: {
    fontSize: typography.fontSize['2xl'],
    fontWeight: typography.fontWeight.bold,
    color: colors.textPrimary,
    marginBottom: spacing['2xl'],
  },
  quickActionsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing['2xl'],
  },
  quickActionCardWrapper: {
    width: (width - spacing['2xl'] * 3) / 2,
    aspectRatio: 1.2,
    borderRadius: borderRadius.md,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.15)',
  },
  quickActionBlur: {
    ...StyleSheet.absoluteFillObject,
  },
  quickActionCard: {
    width: '100%',
    height: '100%',
    justifyContent: 'center',
    alignItems: 'center',
    padding: spacing['2xl'],
    gap: spacing.md,
  },
  quickActionIcon: { fontSize: 32 },
  quickActionLabel: {
    fontSize: typography.fontSize.base,
    color: colors.textPrimary,
  },

  recommendationsSection: { marginBottom: spacing['4xl'] },
});
