import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Linking,
  Alert,
  Dimensions,
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { BlurView } from 'expo-blur';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { colors, typography, spacing, borderRadius } from '../constants/theme';

const { width, height } = Dimensions.get('window');

export default function Safety({ navigation }) {
  const insets = useSafeAreaInsets();

  const handleCallNYU = () => {
    Linking.openURL('tel:2129982222').catch(() => {
      Alert.alert('Error', 'Unable to make phone call');
    });
  };

  const handleCall911 = () => {
    Linking.openURL('tel:911').catch(() => {
      Alert.alert('Error', 'Unable to make phone call');
    });
  };

  const handleShareLocation = () => {
    Alert.alert('Share Location', 'Location sharing feature coming soon');
  };

  const handleFindSafeRoute = () => {
    Alert.alert('Find Safe Route', 'Safe route feature coming soon');
  };


  return (
    <View style={styles.container}>
      <LinearGradient
        colors={[colors.background, colors.backgroundSecondary, colors.background]}
        locations={[0, 0.5, 1]}
        style={[styles.gradient, { paddingTop: insets.top }]}
      >
        {/* Blur effect */}
        <View style={styles.blurContainer}>
          <BlurView intensity={100} style={styles.blur} />
        </View>

        <ScrollView
          contentContainerStyle={styles.scrollContent}
          showsVerticalScrollIndicator={false}
        >
          {/* Header */}
          <View style={styles.header}>
            <View style={styles.iconBlurContainer}>
              <BlurView intensity={40} style={styles.iconBlur} />
            </View>
            <View style={styles.iconContainer}>
              <Text style={styles.iconText}>🛡️</Text>
            </View>
            <Text style={styles.title}>Safety Center</Text>
            <Text style={styles.subtitle}>We're here to keep you safe</Text>
          </View>

          {/* Action Buttons */}
          <View style={styles.actionsContainer}>
            {/* Call NYU Public Safety */}
            <TouchableOpacity
              style={styles.emergencyButton}
              onPress={handleCallNYU}
              activeOpacity={0.8}
            >
              <View style={styles.emergencyButtonContent}>
                <View style={styles.emergencyIconContainer}>
                  <Text style={styles.emergencyIcon}>📞</Text>
                </View>
                <Text style={styles.emergencyButtonText}>Call NYU Public Safety</Text>
                <Text style={styles.emergencyArrow}>→</Text>
              </View>
            </TouchableOpacity>

            {/* Share Live Location */}
            <TouchableOpacity
              style={styles.actionButton}
              onPress={handleShareLocation}
              activeOpacity={0.8}
            >
              <LinearGradient
                colors={[colors.gradientStart, colors.gradientEnd]}
                start={{ x: 0, y: 0 }}
                end={{ x: 1, y: 1 }}
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
            </TouchableOpacity>

            {/* Find Safe Route */}
            <TouchableOpacity
              style={styles.actionButton}
              onPress={handleFindSafeRoute}
              activeOpacity={0.8}
            >
              <LinearGradient
                colors={[colors.gradientBlueStart, colors.gradientBlueEnd]}
                start={{ x: 0, y: 0 }}
                end={{ x: 1, y: 1 }}
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
            </TouchableOpacity>
          </View>

          {/* Emergency Contacts */}
          <View style={styles.contactsContainer}>
            <View style={styles.contactRow}>
              <Text style={styles.contactLabel}>Emergency Services</Text>
              <TouchableOpacity onPress={handleCall911}>
                <Text style={styles.contactValue}>911</Text>
              </TouchableOpacity>
            </View>
            <View style={styles.contactDivider} />
            <View style={styles.contactRow}>
              <Text style={styles.contactLabel}>NYU Public Safety</Text>
              <TouchableOpacity onPress={handleCallNYU}>
                <Text style={styles.contactValue}>(212) 998-2222</Text>
              </TouchableOpacity>
            </View>
          </View>
        </ScrollView>

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
  blurContainer: {
    position: 'absolute',
    left: 0,
    top: 0,
    width: width,
    height: width,
    borderRadius: 1000000,
    overflow: 'hidden',
  },
  blur: {
    width: '100%',
    height: '100%',
    backgroundColor: colors.accentError,
    opacity: 0.05,
  },
  scrollContent: {
    paddingHorizontal: spacing['2xl'], // 16pt horizontal padding (Apple standard)
    paddingTop: spacing['6xl'], // 48pt top padding
    paddingBottom: 180, // Extra padding to prevent nav bar overlap
    width: '100%',
  },
  header: {
    alignItems: 'center',
    marginBottom: spacing['6xl'],
  },
  iconBlurContainer: {
    position: 'absolute',
    width: width * 0.2,
    height: width * 0.2,
    maxWidth: 80,
    maxHeight: 80,
    borderRadius: borderRadius.lg,
    overflow: 'hidden',
  },
  iconBlur: {
    width: '100%',
    height: '100%',
    backgroundColor: colors.accentError,
    opacity: 0.1,
  },
  iconContainer: {
    width: width * 0.2,
    height: width * 0.2,
    maxWidth: 80,
    maxHeight: 80,
    borderRadius: borderRadius.lg,
    backgroundColor: colors.backgroundCard,
    borderWidth: 1,
    borderColor: colors.border,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: spacing['2xl'],
  },
  iconText: {
    fontSize: Math.min(width * 0.1, 40),
  },
  title: {
    fontSize: typography.fontSize['3xl'],
    fontWeight: typography.fontWeight.bold,
    color: colors.textPrimary,
    textAlign: 'center',
    marginBottom: spacing.xs,
    lineHeight: typography.lineHeight['3xl'],
    letterSpacing: -0.64,
  },
  subtitle: {
    fontSize: typography.fontSize.lg,
    fontWeight: typography.fontWeight.regular,
    color: colors.textSecondary,
    textAlign: 'center',
    lineHeight: typography.lineHeight.xl,
  },
  actionsContainer: {
    gap: spacing['2xl'],
    marginBottom: spacing['4xl'],
    width: '100%',
  },
  emergencyButton: {
    borderWidth: 2,
    borderColor: colors.accentErrorBorder,
    borderRadius: borderRadius.md,
    padding: spacing['2xl'],
  },
  emergencyButtonContent: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  emergencyIconContainer: {
    width: 48,
    height: 48,
    borderRadius: borderRadius.md,
    backgroundColor: colors.accentError,
    justifyContent: 'center',
    alignItems: 'center',
  },
  emergencyIcon: {
    fontSize: 24,
  },
  emergencyButtonText: {
    flex: 1,
    marginLeft: spacing['2xl'],
    fontSize: typography.fontSize.lg,
    fontWeight: typography.fontWeight.semiBold,
    color: colors.textError,
  },
  emergencyArrow: {
    fontSize: 20,
    color: colors.textPrimary,
  },
  actionButton: {
    borderRadius: borderRadius.md,
    overflow: 'hidden',
  },
  actionButtonGradient: {
    padding: spacing['3xl'],
  },
  actionButtonContent: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing['2xl'],
  },
  actionIconContainer: {
    width: 48,
    height: 48,
    borderRadius: borderRadius.md,
    backgroundColor: colors.whiteOverlayMedium,
    justifyContent: 'center',
    alignItems: 'center',
  },
  actionIcon: {
    fontSize: 24,
  },
  actionTextContainer: {
    flex: 1,
  },
  actionButtonText: {
    fontSize: typography.fontSize.lg,
    fontWeight: typography.fontWeight.semiBold,
    color: colors.textPrimary,
    marginBottom: spacing.xs,
  },
  actionButtonSubtext: {
    fontSize: typography.fontSize.sm,
    fontWeight: typography.fontWeight.medium,
    color: 'rgba(255,255,255,0.7)',
  },
  contactsContainer: {
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: borderRadius.lg,
    padding: spacing['3xl'],
    backgroundColor: colors.glassBackground,
  },
  contactRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: spacing['2xl'],
  },
  contactLabel: {
    fontSize: typography.fontSize.base,
    fontWeight: typography.fontWeight.regular,
    color: colors.textSecondary,
  },
  contactValue: {
    fontSize: typography.fontSize.md,
    fontWeight: typography.fontWeight.semiBold,
    color: colors.textPrimary,
  },
  contactDivider: {
    height: 1,
    backgroundColor: colors.whiteOverlay,
    marginVertical: spacing.xs,
  },
});

