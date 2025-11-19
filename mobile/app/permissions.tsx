import React, { useState } from 'react';
import { View, Text, StyleSheet, Dimensions, Platform } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import * as Location from 'expo-location';
import * as Notifications from 'expo-notifications';
import * as Calendar from 'expo-calendar';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { BlurView } from 'expo-blur';
import { LiquidGlassView, isLiquidGlassSupported } from '@callstack/liquid-glass';
import Animated, {
  FadeIn,
  FadeInDown,
  FadeInUp,
  SlideInDown,
  Easing,
} from 'react-native-reanimated';

import LiquidGlassButton from '../components/LiquidGlassButton';

import { colors, typography, spacing, borderRadius } from '../constants/theme';

import { router } from "expo-router";

const { width, height } = Dimensions.get('window');

interface PermissionCardProps {
  icon: string;
  title: string;
  description: string;
}

function PermissionCard({ icon, title, description }: PermissionCardProps) {
  const hasLiquidGlass = isLiquidGlassSupported;

  return (
    <Animated.View
      entering={FadeInDown.duration(400).easing(Easing.out(Easing.ease))}
      style={styles.card}
    >
      {hasLiquidGlass && Platform.OS === 'ios' ? (
        <LiquidGlassView
          effect="regular"
          style={styles.iconContainer}
          tintColor="rgba(108, 99, 255, 0.35)"
        >
          <View style={styles.iconContent}>
            <Text style={styles.icon}>{icon}</Text>
          </View>
        </LiquidGlassView>
      ) : (
        <View style={styles.iconContainer}>
          <BlurView intensity={40} tint="systemChromeMaterialDark" style={styles.iconBlur}>
            <LinearGradient
              colors={['rgba(108, 99, 255, 0.3)', 'rgba(108, 99, 255, 0.1)']}
              style={styles.iconGradient}
            >
              <Text style={styles.icon}>{icon}</Text>
            </LinearGradient>
          </BlurView>
        </View>
      )}
      <Text style={styles.cardTitle}>{title}</Text>
      <Text style={styles.cardDescription}>{description}</Text>
    </Animated.View>
  );
}

export default function Permissions() {
  const insets = useSafeAreaInsets();
  const [loading, setLoading] = useState(false);

  const handleEnableAll = async () => {
    setLoading(true);
    
    try {
    await Promise.all([
        Location.requestForegroundPermissionsAsync(),
        Calendar.requestCalendarPermissionsAsync(),
        Notifications.requestPermissionsAsync(),
    ]);

    await AsyncStorage.setItem('hasCompletedPermissions', 'true');

      router.replace("/(tabs)/dashboard");
    } catch (error) {
      console.error('Permission error:', error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <View style={styles.container}>
      {/* Background Gradient */}
      <LinearGradient
        colors={['#0F1729', '#1A2342', '#0F1729']}
        style={styles.gradient}
      />

      {/* Blur Shapes */}
      <View style={styles.blurShape1} />
      <View style={styles.blurShape2} />

      {/* Content */}
      <View style={[styles.content, { paddingTop: insets.top + 40, paddingBottom: insets.bottom + 20 }]}>
        <View style={styles.scrollContent}>
          <Animated.View entering={FadeInDown.delay(200).duration(400).easing(Easing.out(Easing.ease))}>
            <PermissionCard
              icon="📍"
              title="Allow Location"
              description="To find awesome spots near you."
            />
          </Animated.View>
          
          <Animated.View entering={FadeInDown.delay(400).duration(400).easing(Easing.out(Easing.ease))}>
            <PermissionCard
              icon="📅"
              title="Sync Calendar"
              description="To find suggestions for your downtime."
            />
          </Animated.View>
          
          <Animated.View entering={FadeInDown.delay(600).duration(400).easing(Easing.out(Easing.ease))}>
            <PermissionCard
              icon="🔔"
              title="Enable Notifications"
              description="For real-time alerts on events and deals."
            />
          </Animated.View>
        </View>

        <Animated.View
          entering={SlideInDown.delay(800).duration(400).easing(Easing.out(Easing.ease))}
          style={styles.buttonContainer}
        >
          <LiquidGlassButton
            title="Enable All"
            onPress={handleEnableAll}
            variant="glass"
            loading={loading}
          />
        </Animated.View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0F1729',
  },
  gradient: {
    ...StyleSheet.absoluteFillObject,
  },
  blurShape1: {
    position: 'absolute',
    top: -100,
    left: -50,
    width: 300,
    height: 300,
    borderRadius: 150,
    backgroundColor: 'rgba(108, 99, 255, 0.15)',
    opacity: 0.6,
  },
  blurShape2: {
    position: 'absolute',
    bottom: -80,
    right: -80,
    width: 250,
    height: 250,
    borderRadius: 125,
    backgroundColor: 'rgba(91, 75, 255, 0.12)',
    opacity: 0.5,
  },
  content: {
    flex: 1,
    justifyContent: 'space-between',
    paddingHorizontal: spacing['2xl'],
  },
  scrollContent: {
    flex: 1,
    justifyContent: 'space-evenly',
    paddingVertical: spacing['2xl'],
  },
  card: {
    alignItems: 'center',
    paddingVertical: spacing.md,
  },
  iconContainer: {
    width: 96,
    height: 96,
    marginBottom: spacing['2xl'],
    borderRadius: 28,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: 'rgba(108, 99, 255, 0.3)',
    ...Platform.select({
      ios: {
        shadowColor: '#6c63ff',
        shadowOffset: { width: 0, height: 8 },
        shadowOpacity: 0.4,
        shadowRadius: 20,
      },
      android: {
        elevation: 12,
      },
    }),
  },
  iconContent: {
    width: '100%',
    height: '100%',
    alignItems: 'center',
    justifyContent: 'center',
  },
  iconBlur: {
    width: '100%',
    height: '100%',
    borderRadius: 28,
    overflow: 'hidden',
  },
  iconGradient: {
    width: '100%',
    height: '100%',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: 'rgba(30, 39, 65, 0.8)',
    borderWidth: 1,
    borderColor: 'rgba(108, 99, 255, 0.3)',
    borderRadius: 28,
  },
  icon: {
    fontSize: 48,
  },
  cardTitle: {
    fontSize: typography.fontSize['2xl'],
    fontWeight: typography.fontWeight.bold,
    color: colors.textPrimary,
    marginBottom: spacing.sm,
    textAlign: 'center',
    fontFamily: typography.fontFamily,
  },
  cardDescription: {
    fontSize: typography.fontSize.base,
    color: colors.textSecondary,
    textAlign: 'center',
    lineHeight: 22,
    maxWidth: width * 0.75,
    fontFamily: typography.fontFamily,
  },
  buttonContainer: {
    width: '100%',
    paddingTop: spacing.xl,
    paddingBottom: spacing['2xl'],
  },
});
