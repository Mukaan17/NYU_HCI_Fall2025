import React, { useState } from 'react';
import { View, Text, StyleSheet, ScrollView, Alert, Dimensions } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import * as Location from 'expo-location';
import * as Notifications from 'expo-notifications';
import * as Calendar from 'expo-calendar';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { BlurView } from 'expo-blur';

// IMPORTANT: your components are .js files
import PrimaryButton from '../components/PrimaryButton';

// IMPORTANT: your theme is theme.js
import { colors, typography, spacing, borderRadius } from '../constants/theme';

import { router } from "expo-router";

const { width, height } = Dimensions.get('window');

export default function Permissions() {
  const insets = useSafeAreaInsets();
  const [permissions, setPermissions] = useState({
    location: false,
    calendar: false,
    notifications: false,
  });

  const requestLocation = async () => {
    try {
      const { status } = await Location.requestForegroundPermissionsAsync();
      setPermissions((p) => ({ ...p, location: status === 'granted' }));
      return status === 'granted';
    } catch {
      Alert.alert('Error', 'Failed to request location permission');
      return false;
    }
  };

  const requestCalendar = async () => {
    try {
      const { status } = await Calendar.requestCalendarPermissionsAsync();
      setPermissions((p) => ({ ...p, calendar: status === 'granted' }));
      return status === 'granted';
    } catch {
      Alert.alert('Error', 'Failed to request calendar permission');
      return false;
    }
  };

  const requestNotifications = async () => {
    try {
      const { status } = await Notifications.requestPermissionsAsync();
      setPermissions((p) => ({ ...p, notifications: status === 'granted' }));
      return status === 'granted';
    } catch {
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

    await AsyncStorage.setItem('hasCompletedPermissions', 'true');

    router.replace("/(tabs)");
  };

  return (
    <View style={styles.container}>
      <ScrollView contentContainerStyle={{ padding: spacing.lg }}>
        <Text style={styles.title}>Permissions</Text>

        <Text style={styles.label}>Location: {permissions.location ? "Enabled" : "Disabled"}</Text>
        <Text style={styles.label}>Calendar: {permissions.calendar ? "Enabled" : "Disabled"}</Text>
        <Text style={styles.label}>Notifications: {permissions.notifications ? "Enabled" : "Disabled"}</Text>

        <PrimaryButton title="Enable All" onPress={handleEnableAll} />
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.backgroundPrimary || "#000",
  },
  title: {
    fontSize: typography.heading || 26,
    fontWeight: "bold",
    marginBottom: spacing.md || 16,
    color: colors.textPrimary || "#fff",
  },
  label: {
    fontSize: typography.body || 16,
    marginBottom: spacing.sm || 12,
    color: colors.textSecondary || "#ccc",
  },
});
