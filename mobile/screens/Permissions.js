import React, { useState } from 'react';
import { View, Text, StyleSheet, ScrollView, Alert, Dimensions } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import * as Location from 'expo-location';
import * as Notifications from 'expo-notifications';
import * as Calendar from 'expo-calendar';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { BlurView } from 'expo-blur';
import PrimaryButton from '../components/PrimaryButton';
import { colors, typography, spacing, borderRadius } from '../constants/theme';

const { width, height } = Dimensions.get('window');

export default function Permissions({ navigation }) {
  const insets = useSafeAreaInsets();
  const [permissions, setPermissions] = useState({
    location: false,
    calendar: false,
    notifications: false,
  });

  const requestLocation = async () => {
    try {
      const { status } = await Location.requestForegroundPermissionsAsync();
      setPermissions((prev) => ({ ...prev, location: status === 'granted' }));
      return status === 'granted';
    } catch (error) {
      Alert.alert('Error', 'Failed to request location permission');
      return false;
    }
  };

  const requestCalendar = async () => {
    try {
      const { status } = await Calendar.requestCalendarPermissionsAsync();
      setPermissions((prev) => ({ ...prev, calendar: status === 'granted' }));
      return status === 'granted';
    } catch (error) {
      Alert.alert('Error', 'Failed to request calendar permission');
      return false;
    }
  };

  const requestNotifications = async () => {
    try {
      const { status } = await Notifications.requestPermissionsAsync();
      setPermissions((prev) => ({ ...prev, notifications: status === 'granted' }));
      return status === 'granted';
    } catch (error) {
      Alert.alert('Error', 'Failed to request notification permission');
      return false;
    }
  };

  const handleEnableAll = async () => {
    await Promise.all([
      requestLocation(),
      requestCalendar(),
      requestNotifications(),
    ]);
    try {
      await AsyncStorage.setItem('hasCompletedPermissions', 'true');
      navigation.navigate('Main');
    } catch (error) {
      console.error('Error saving permissions status:', error);
      navigation.navigate('Main');
    }
  };

  const PermissionCard = ({ icon, title, description, onPress }) => (
    <View style={styles.permissionCard}>
      <View style={styles.iconBlurContainer}>
        <BlurView intensity={40} style={styles.iconBlur} />
      </View>
      <View style={styles.iconContainer}>
        <Text style={styles.iconText}>{icon}</Text>
      </View>
      <Text style={styles.permissionTitle}>{title}</Text>
      <Text style={styles.permissionDescription}>{description}</Text>
    </View>
  );

  return (
    <View style={styles.container}>
      <View style={[styles.gradient, { paddingTop: insets.top, paddingBottom: insets.bottom }]}>
        {/* Blur effects */}
        <View style={styles.blurContainer1}>
          <BlurView intensity={80} style={styles.blur1} />
        </View>
        <View style={styles.blurContainer2}>
          <BlurView intensity={80} style={styles.blur2} />
        </View>

        <ScrollView
          contentContainerStyle={styles.scrollContent}
          showsVerticalScrollIndicator={false}
        >
          <View style={styles.content}>
            <PermissionCard
              icon="📍"
              title="Allow Location"
              description="To find awesome spots near you."
              onPress={requestLocation}
            />

            <PermissionCard
              icon="📅"
              title="Sync Calendar"
              description="To find suggestions for your downtime."
              onPress={requestCalendar}
            />

            <PermissionCard
              icon="🔔"
              title="Enable Notifications"
              description="For real-time alerts on events and deals."
              onPress={requestNotifications}
            />

            <View style={styles.buttonContainer}>
              <PrimaryButton title="Enable All" onPress={handleEnableAll} />
            </View>
          </View>
        </ScrollView>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  gradient: {
    flex: 1,
    backgroundColor: colors.background,
  },
  blurContainer1: {
    position: 'absolute',
    left: width * 0.35,
    top: 0,
    width: width * 0.65,
    height: width * 0.65,
    borderRadius: 1000000,
    overflow: 'hidden',
  },
  blur1: {
    width: '100%',
    height: '100%',
    backgroundColor: colors.accentPurple,
    opacity: 0.1,
  },
  blurContainer2: {
    position: 'absolute',
    left: 0,
    top: height * 0.6,
    width: width * 0.65,
    height: width * 0.65,
    borderRadius: 1000000,
    overflow: 'hidden',
  },
  blur2: {
    width: '100%',
    height: '100%',
    backgroundColor: colors.accentBlue,
    opacity: 0.1,
  },
  scrollContent: {
    flexGrow: 1,
    justifyContent: 'center',
    paddingVertical: spacing['4xl'], // 24pt vertical padding
    minHeight: '100%',
  },
  content: {
    paddingHorizontal: spacing['2xl'], // 16pt horizontal padding (Apple standard)
    gap: spacing['4xl'], // 24pt gap between cards
    width: '100%',
  },
  permissionCard: {
    alignItems: 'center',
    marginBottom: spacing['3xl'], // 20pt margin between cards
    width: '100%',
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
    backgroundColor: colors.accentPurple,
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
    fontSize: Math.min(width * 0.09, 36),
  },
  permissionTitle: {
    fontSize: typography.fontSize['2xl'],
    fontWeight: typography.fontWeight.semiBold,
    color: colors.textPrimary,
    textAlign: 'center',
    marginBottom: spacing.xs,
    lineHeight: typography.lineHeight['2xl'],
  },
  permissionDescription: {
    fontSize: typography.fontSize.lg,
    fontWeight: typography.fontWeight.regular,
    color: colors.textSecondary,
    textAlign: 'center',
    lineHeight: typography.lineHeight['2xl'],
  },
  buttonContainer: {
    marginTop: spacing['5xl'],
    alignItems: 'center',
    width: '100%',
    paddingHorizontal: spacing['2xl'],
  },
});

