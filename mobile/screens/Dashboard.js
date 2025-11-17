/**
 * @Author: Mukhil Sundararaj
 * @Date:   2025-11-14 15:32:51
 * @Last Modified by:   Mukhil Sundararaj
 * @Last Modified time: 2025-11-17 12:58:11
 */
import React, { useEffect, useState } from 'react';
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
  useSharedValue,
  useAnimatedStyle,
  withTiming,
  withSpring,
  withDelay,
  FadeInDown,
} from 'react-native-reanimated';
import RecommendationCard from '../components/RecommendationCard';
import Notification from '../components/Notification';
import { colors, typography, spacing, borderRadius, shadows } from '../constants/theme';

const { width, height } = Dimensions.get('window');

const AnimatedView = Animated.createAnimatedComponent(View);

export default function Dashboard({ navigation }) {
  const insets = useSafeAreaInsets();
  const [showNotification, setShowNotification] = useState(false);

  // Demo: Show notification after 3 seconds (simulating calendar-based trigger)
  useEffect(() => {
    const timer = setTimeout(() => {
      setShowNotification(true);
    }, 3000);
    return () => clearTimeout(timer);
  }, []);

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
    { id: 1, icon: '🍔', label: 'Find Food', color: colors.accentPurple, prompt: 'Find me a good place to eat nearby' },
    { id: 2, icon: '🎵', label: 'Events', color: colors.accentBlue, prompt: 'What events are happening nearby tonight?' },
    { id: 3, icon: '☕', label: 'Cafés', color: colors.accentPurple, prompt: 'Find a quiet café for studying' },
    { id: 4, icon: '🎯', label: 'Explore', color: colors.accentBlue, prompt: 'What are some interesting places to explore nearby?' },
  ];


  const QuickActionCard = ({ icon, label, color, delay = 0, prompt, onPress }) => {
    const scale = useSharedValue(1);

    const animatedStyle = useAnimatedStyle(() => {
      return {
        transform: [{ scale: scale.value }],
      };
    });

    const handlePressIn = () => {
      scale.value = withSpring(0.95);
    };

    const handlePressOut = () => {
      scale.value = withSpring(1);
    };

    const handlePress = () => {
      if (onPress && prompt) {
        onPress(prompt);
      }
    };

    return (
      <Animated.View
        entering={FadeInDown.delay(delay).springify()}
        style={animatedStyle}
      >
        <TouchableOpacity
          onPressIn={handlePressIn}
          onPressOut={handlePressOut}
          onPress={handlePress}
          activeOpacity={0.9}
          style={styles.quickActionCardWrapper}
        >
          <BlurView
            intensity={Platform.OS === 'ios' ? 50 : 35}
            tint="dark"
            style={styles.quickActionBlur}
          >
            <View style={[styles.quickActionGlassOverlay, { backgroundColor: color + '30' }]} />
          </BlurView>
          <LinearGradient
            colors={[color + '40', color + '20']}
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
        style={[styles.gradient, { paddingTop: insets.top, paddingBottom: insets.bottom }]}
      >
        {/* Blur effects */}
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
          {/* Header */}
          <Animated.View entering={FadeInDown.delay(100)} style={styles.header}>
            <Text style={styles.greeting}>Hey there! 👋</Text>
            <Text style={styles.subtitle}>Here's what's happening around you</Text>
          </Animated.View>

          {/* Status Badges */}
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

          {/* Quick Actions */}
          <Animated.View entering={FadeInDown.delay(300)} style={styles.quickActionsContainer}>
            <Text style={styles.sectionTitle}>Quick Actions</Text>
            <View style={styles.quickActionsGrid}>
              {quickActions.map((action, index) => (
                <QuickActionCard
                  key={action.id}
                  icon={action.icon}
                  label={action.label}
                  color={action.color}
                  delay={300 + index * 50}
                  prompt={action.prompt}
                  onPress={(prompt) => {
                    // Use jumpTo for tab navigation to ensure params are passed correctly
                    const tabNavigator = navigation.getParent();
                    if (tabNavigator) {
                      tabNavigator.navigate('ChatTab', { autoPrompt: prompt });
                    } else {
                      navigation.navigate('ChatTab', { autoPrompt: prompt });
                    }
                  }}
                />
              ))}
            </View>
          </Animated.View>

          {/* Recent Recommendations */}
          <Animated.View entering={FadeInDown.delay(500)} style={styles.recommendationsSection}>
            <Text style={styles.sectionTitle}>Top Recommendations</Text>
            {recommendations.map((rec, index) => (
              <Animated.View
                key={rec.id}
                entering={FadeInDown.delay(600 + index * 100)}
              >
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
      
      {/* Notification Modal for Demo */}
      <Notification
        visible={showNotification}
        onDismiss={() => setShowNotification(false)}
        onViewEvent={() => {
          setShowNotification(false);
          navigation.navigate('ChatTab');
        }}
        notification={{
          message: "You're free till 8 PM — live jazz at Fulton St starts soon (7 min walk)."
        }}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  gradient: {
    flex: 1,
  },
  blurContainer1: {
    position: 'absolute',
    left: -width * 0.2,
    top: height * 0.1,
    width: width * 0.75,
    height: width * 0.75,
    borderRadius: 1000000,
    overflow: 'hidden',
  },
  blur1: {
    width: '100%',
    height: '100%',
    backgroundColor: colors.accentPurpleMedium,
    opacity: 0.881,
  },
  blurContainer2: {
    position: 'absolute',
    left: width * 0.22,
    top: height * 0.35,
    width: width,
    height: width,
    borderRadius: 1000000,
    overflow: 'hidden',
  },
  blur2: {
    width: '100%',
    height: '100%',
    backgroundColor: colors.accentBlue,
    opacity: 0.619,
  },
  scrollView: {
    flex: 1,
  },
  scrollContent: {
    paddingHorizontal: spacing['2xl'], // 16pt horizontal padding
    paddingTop: spacing['3xl'], // 20pt top padding
    paddingBottom: 180, // Extra padding to prevent nav bar overlap (nav bar ~80pt + safe area + spacing)
  },
  header: {
    marginBottom: spacing['3xl'],
  },
  greeting: {
    fontSize: typography.fontSize['3xl'],
    fontWeight: typography.fontWeight.bold,
    color: colors.textPrimary,
    marginBottom: spacing.xs,
    lineHeight: typography.lineHeight['3xl'],
    letterSpacing: -0.64,
  },
  subtitle: {
    fontSize: typography.fontSize.lg,
    fontWeight: typography.fontWeight.regular,
    color: colors.textSecondary,
    lineHeight: typography.lineHeight.xl,
  },
  badgesContainer: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    gap: spacing.md, // 8pt gap between badges
    flexWrap: 'nowrap',
    marginBottom: spacing['4xl'],
    width: '100%',
  },
  weatherBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.accentBlue,
    borderWidth: 1,
    borderColor: colors.accentBlueMedium,
    borderRadius: borderRadius.md,
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.xs,
    gap: spacing.sm,
    flexShrink: 0,
    height: 32, // Fixed height for alignment
  },
  weatherIcon: {
    fontSize: 16,
  },
  weatherText: {
    fontSize: typography.fontSize.sm,
    fontWeight: typography.fontWeight.semiBold,
    color: colors.textBlue,
  },
  scheduleBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.glassBackground,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: borderRadius.md,
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.xs,
    gap: spacing.sm,
    flexShrink: 0,
    height: 32, // Fixed height for alignment
  },
  scheduleIcon: {
    fontSize: 16,
  },
  scheduleText: {
    fontSize: typography.fontSize.sm,
    fontWeight: typography.fontWeight.semiBold,
    color: colors.textPrimary,
  },
  moodBadge: {
    backgroundColor: colors.whiteOverlay,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: borderRadius.md,
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.xs,
    flexShrink: 0,
    height: 32, // Fixed height for alignment
    justifyContent: 'center',
    alignItems: 'center',
  },
  moodText: {
    fontSize: typography.fontSize.sm,
    fontWeight: typography.fontWeight.semiBold,
    color: colors.textSecondary,
  },
  quickActionsContainer: {
    marginBottom: spacing['4xl'],
  },
  sectionTitle: {
    fontSize: typography.fontSize['2xl'],
    fontWeight: typography.fontWeight.bold,
    color: colors.textPrimary,
    marginBottom: spacing['2xl'],
    lineHeight: typography.lineHeight['2xl'],
  },
  quickActionsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing['2xl'], // 16pt gap between action cards
    marginBottom: spacing['2xl'], // 16pt bottom margin
  },
  quickActionCardWrapper: {
    width: (width - spacing['2xl'] * 2 - spacing['2xl']) / 2, // Account for padding and gap
    aspectRatio: 1.2,
    borderRadius: borderRadius.md,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.15)',
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.2,
        shadowRadius: 12,
      },
      android: {
        elevation: 4,
      },
    }),
  },
  quickActionBlur: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
  },
  quickActionGlassOverlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
  },
  quickActionCard: {
    width: '100%',
    height: '100%',
    justifyContent: 'center',
    alignItems: 'center',
    gap: spacing.md,
    padding: spacing['2xl'], // 16pt internal padding
    position: 'relative',
    zIndex: 1,
  },
  quickActionIcon: {
    fontSize: 32,
  },
  quickActionLabel: {
    fontSize: typography.fontSize.base,
    fontWeight: typography.fontWeight.semiBold,
    color: colors.textPrimary,
  },
  recommendationsSection: {
    marginBottom: spacing['4xl'],
  },
});

