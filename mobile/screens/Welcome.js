/**
 * @Author: Mukhil Sundararaj
 * @Date:   2025-11-14 11:49:51
 * @Last Modified by:   Mukhil Sundararaj
 * @Last Modified time: 2025-11-14 15:17:25
 */
import React from 'react';
import { View, Text, StyleSheet, Dimensions } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { BlurView } from 'expo-blur';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import AsyncStorage from '@react-native-async-storage/async-storage';
import PrimaryButton from '../components/PrimaryButton';
import SvgIcon from '../components/SvgIcon';
import { colors, typography, spacing, borderRadius } from '../constants/theme';

const { width, height } = Dimensions.get('window');

export default function Welcome({ navigation }) {
  const insets = useSafeAreaInsets();

  const handleLetsGo = async () => {
    try {
      await AsyncStorage.setItem('hasSeenWelcome', 'true');
      navigation.navigate('Permissions');
    } catch (error) {
      console.error('Error saving welcome status:', error);
      navigation.navigate('Permissions');
    }
  };

  return (
    <View style={styles.container}>
      <LinearGradient
        colors={[colors.background, colors.backgroundSecondary]}
        style={[styles.gradient, { paddingTop: insets.top, paddingBottom: insets.bottom }]}
      >
        {/* Blur effects */}
        <View style={styles.blurContainer1}>
          <BlurView intensity={80} style={styles.blur1} />
        </View>
        <View style={styles.blurContainer2}>
          <BlurView intensity={60} style={styles.blur2} />
        </View>

        {/* Content */}
        <View style={styles.content}>
          {/* Icon placeholder */}
          <View style={styles.iconContainer}>
            <View style={styles.iconBlur}>
              <BlurView intensity={40} style={styles.iconBlurView} />
            </View>
            <View style={styles.icon}>
              <SvgIcon name="icon" size={Math.min(width * 0.25, 100)} color="#FFFFFF" />
            </View>
          </View>

          {/* Heading */}
          <View style={styles.headingContainer}>
            <Text style={styles.heading}>Hey There 👋</Text>
          </View>

          {/* Description */}
          <View style={styles.descriptionContainer}>
            <Text style={styles.description}>
              I'm <Text style={styles.violetText}>Violet</Text>, your AI concierge for Downtown
            </Text>
            <Text style={styles.description}>Brooklyn. Let's find your next vibe.</Text>
          </View>

          {/* Button */}
          <View style={styles.buttonContainer}>
            <PrimaryButton title="Let's Go" onPress={handleLetsGo} />
          </View>
        </View>
      </LinearGradient>
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
    top: 0,
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
    top: height * 0.3,
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
  content: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: spacing['2xl'], // 16pt horizontal padding
    width: '100%',
    minHeight: '100%',
  },
  iconContainer: {
    width: width * 0.35,
    height: width * 0.35,
    maxWidth: 140,
    maxHeight: 140,
    marginBottom: spacing['5xl'],
    position: 'relative',
  },
  iconBlur: {
    position: 'absolute',
    width: '100%',
    height: '100%',
    borderRadius: borderRadius.full,
    overflow: 'hidden',
  },
  iconBlurView: {
    width: '100%',
    height: '100%',
    backgroundColor: colors.accentPurple,
    opacity: 0.348,
  },
  icon: {
    width: '100%',
    height: '100%',
    borderRadius: borderRadius.full,
    backgroundColor: colors.backgroundCard,
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: colors.border,
  },
  iconText: {
    fontSize: Math.min(width * 0.15, 60),
  },
  headingContainer: {
    marginBottom: spacing['2xl'],
  },
  heading: {
    fontSize: typography.fontSize['3xl'],
    fontWeight: typography.fontWeight.bold,
    color: colors.textPrimary,
    textAlign: 'center',
    lineHeight: typography.lineHeight['3xl'],
    letterSpacing: -0.64,
  },
  descriptionContainer: {
    marginBottom: spacing['6xl'],
    alignItems: 'center',
  },
  description: {
    fontSize: typography.fontSize.lg,
    fontWeight: typography.fontWeight.regular,
    color: colors.textSecondary,
    textAlign: 'center',
    lineHeight: typography.lineHeight['2xl'],
    marginBottom: spacing.xs,
    paddingHorizontal: spacing.xl,
  },
  violetText: {
    fontWeight: typography.fontWeight.semiBold,
    color: colors.textAccent,
  },
  buttonContainer: {
    width: '100%',
    maxWidth: width * 0.85,
    paddingHorizontal: spacing['2xl'],
    marginTop: spacing['5xl'],
  },
});

