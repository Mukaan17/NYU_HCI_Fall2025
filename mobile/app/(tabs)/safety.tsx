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

import { colors, typography, spacing, borderRadius } from '../../constants/theme';

const { width, height } = Dimensions.get('window');

export default function Safety() {
  const insets = useSafeAreaInsets();

  const handleCallNYU = () => {
    Linking.openURL('tel:2129982222').catch(() =>
      Alert.alert('Error', 'Unable to make phone call')
    );
  };

  const handleCall911 = () => {
    Linking.openURL('tel:911').catch(() =>
      Alert.alert('Error', 'Unable to make phone call')
    );
  };

  const handleShareLocation = () => {
    Alert.alert('Share Location', 'Location sharing feature coming soon');
  };

  const handleFindSafeRoute = () => {
    Alert.alert('Feature Coming Soon', 'Safe route feature coming soon');
  };

  return (
    <View style={styles.container}>
      <LinearGradient
        colors={[colors.background, colors.backgroundSecondary, colors.background]}
        style={[styles.gradient, { paddingTop: insets.top, paddingBottom: insets.bottom }]}
      >
        <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
          <View style={styles.header}>
            <Text style={styles.iconText}>🛡️</Text>
            <Text style={styles.title}>Safety Center</Text>
            <Text style={styles.subtitle}>We're here to keep you safe</Text>
          </View>

          {/* Emergency Buttons */}
          <View style={styles.actionsContainer}>
            <TouchableOpacity style={styles.emergencyButton} onPress={handleCallNYU}>
              <Text style={styles.emergencyButtonText}>Call NYU Public Safety</Text>
            </TouchableOpacity>

            <TouchableOpacity style={styles.actionButton} onPress={handleShareLocation}>
              <Text style={styles.actionButtonText}>Share Live Location</Text>
            </TouchableOpacity>

            <TouchableOpacity style={styles.actionButton} onPress={handleFindSafeRoute}>
              <Text style={styles.actionButtonText}>Find Safe Route Home</Text>
            </TouchableOpacity>
          </View>

          {/* Contacts */}
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
  container: { flex: 1 },
  gradient: { flex: 1 },
  scrollContent: {
    paddingHorizontal: spacing['2xl'],
    paddingTop: spacing['6xl'],
    paddingBottom: 180,
  },

  header: {
    alignItems: 'center',
    marginBottom: spacing['6xl'],
  },
  iconText: {
    fontSize: 40,
    marginBottom: spacing['2xl'],
  },
  title: {
    fontSize: typography.fontSize['3xl'],
    fontWeight: typography.fontWeight.bold,
    color: colors.textPrimary,
  },
  subtitle: {
    fontSize: typography.fontSize.lg,
    color: colors.textSecondary,
  },

  actionsContainer: { gap: spacing['2xl'], marginBottom: spacing['4xl'] },

  emergencyButton: {
    borderWidth: 2,
    borderColor: colors.accentErrorBorder,
    borderRadius: borderRadius.md,
    padding: spacing['2xl'],
  },
  emergencyButtonText: {
    color: colors.textError,
    fontSize: typography.fontSize.lg,
    fontWeight: typography.fontWeight.semiBold,
  },

  actionButton: {
    backgroundColor: colors.accentPurpleMedium,
    padding: spacing['3xl'],
    borderRadius: borderRadius.md,
  },
  actionButtonText: {
    color: colors.textPrimary,
    fontSize: typography.fontSize.lg,
    fontWeight: typography.fontWeight.semiBold,
  },

  contactsContainer: {
    borderWidth: 1,
    borderColor: colors.border,
    padding: spacing['3xl'],
    borderRadius: borderRadius.lg,
  },
  contactRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: spacing['2xl'],
  },
  contactLabel: {
    color: colors.textSecondary,
    fontSize: typography.fontSize.base,
  },
  contactValue: {
    color: colors.textPrimary,
    fontSize: typography.fontSize.md,
    fontWeight: typography.fontWeight.semiBold,
  },
  contactDivider: {
    height: 1,
    backgroundColor: colors.whiteOverlay,
    marginVertical: spacing.xs,
  },
});
