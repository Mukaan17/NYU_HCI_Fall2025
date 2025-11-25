// app/(tabs)/settings.tsx
import React, { useState, useEffect } from "react";
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  TouchableOpacity,
  Switch,
  TextInput,
  Alert,
  Platform,
} from "react-native";
import { LinearGradient } from "expo-linear-gradient";
import { BlurView } from "expo-blur";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import AsyncStorage from "@react-native-async-storage/async-storage";
import * as Location from "expo-location";
import * as Calendar from "expo-calendar";
import * as Notifications from "expo-notifications";
import { router } from "expo-router";

import {
  colors,
  typography,
  spacing,
  borderRadius,
} from "../../constants/theme";
import LocationPicker from "../../components/LocationPicker";

interface SettingRowProps {
  icon: string;
  title: string;
  description?: string;
  onPress?: () => void;
  rightElement?: React.ReactNode;
  showArrow?: boolean;
}

function SettingRow({
  icon,
  title,
  description,
  onPress,
  rightElement,
  showArrow = false,
}: SettingRowProps) {
  const content = (
    <View style={styles.settingRow}>
      <View style={styles.settingRowContent}>
        <Text style={styles.settingRowIcon}>{icon}</Text>
        <View style={styles.settingRowText}>
          <Text style={styles.settingRowTitle}>{title}</Text>
          {description && (
            <Text style={styles.settingRowDescription}>{description}</Text>
          )}
        </View>
      </View>
      {rightElement && <View style={styles.settingRowRight}>{rightElement}</View>}
      {showArrow && !rightElement && (
        <Text style={styles.settingRowArrow}>›</Text>
      )}
    </View>
  );

  if (onPress) {
    return (
      <TouchableOpacity onPress={onPress} activeOpacity={0.7}>
        {content}
      </TouchableOpacity>
    );
  }

  return content;
}

export default function Settings() {
  const insets = useSafeAreaInsets();
  const [firstName, setFirstName] = useState("");
  const [homeAddress, setHomeAddress] = useState("");
  const [locationPermission, setLocationPermission] = useState(false);
  const [calendarPermission, setCalendarPermission] = useState(false);
  const [notificationPermission, setNotificationPermission] = useState(false);
  const [usePreferencesForPersonalization, setUsePreferencesForPersonalization] =
    useState(true);
  const [trustedContactsCount, setTrustedContactsCount] = useState(0);

  useEffect(() => {
    loadSettings();
  }, []);

  const loadSettings = async () => {
    try {
      const userAccountStr = await AsyncStorage.getItem("userAccount");
      if (userAccountStr) {
        const userAccount = JSON.parse(userAccountStr);
        setFirstName(userAccount.firstName || "");
      }

      const homeAddressStr = await AsyncStorage.getItem("homeAddress");
      if (homeAddressStr) {
        setHomeAddress(homeAddressStr);
      }

      const preferencesStr = await AsyncStorage.getItem("userPreferences");
      if (preferencesStr) {
        const preferences = JSON.parse(preferencesStr);
        setUsePreferencesForPersonalization(
          preferences.usePreferencesForPersonalization !== false
        );
      }

      // Check permissions
      const locationStatus = await Location.getForegroundPermissionsAsync();
      setLocationPermission(locationStatus.granted);

      const calendarStatus = await Calendar.getCalendarPermissionsAsync();
      setCalendarPermission(calendarStatus.granted);

      const notificationStatus = await Notifications.getPermissionsAsync();
      setNotificationPermission(notificationStatus.granted);

      // Load trusted contacts count
      const contactsStr = await AsyncStorage.getItem("trustedContacts");
      if (contactsStr) {
        const contacts = JSON.parse(contactsStr);
        setTrustedContactsCount(Array.isArray(contacts) ? contacts.length : 0);
      }
    } catch (error) {
      console.error("Error loading settings:", error);
    }
  };

  const handleSaveFirstName = async () => {
    try {
      const userAccountStr = await AsyncStorage.getItem("userAccount");
      if (userAccountStr) {
        const userAccount = JSON.parse(userAccountStr);
        userAccount.firstName = firstName.trim();
        await AsyncStorage.setItem("userAccount", JSON.stringify(userAccount));
        Alert.alert("Success", "First name updated");
      }
    } catch (error) {
      console.error("Error saving first name:", error);
      Alert.alert("Error", "Failed to save first name");
    }
  };

  const handleSaveHomeAddress = async () => {
    try {
      await AsyncStorage.setItem("homeAddress", homeAddress.trim());
      Alert.alert("Success", "Home address updated");
    } catch (error) {
      console.error("Error saving home address:", error);
      Alert.alert("Error", "Failed to save home address");
    }
  };

  const handleLogout = () => {
    Alert.alert(
      "Log Out",
      "Are you sure you want to log out? You'll need to go through onboarding again.",
      [
        { text: "Cancel", style: "cancel" },
        {
          text: "Log Out",
          style: "destructive",
          onPress: async () => {
            try {
              await AsyncStorage.removeItem("hasLoggedIn");
              await AsyncStorage.removeItem("userAccount");
              router.replace("/(onboarding)/login");
            } catch (error) {
              console.error("Error logging out:", error);
            }
          },
        },
      ]
    );
  };

  const requestLocationPermission = async () => {
    const { status } = await Location.requestForegroundPermissionsAsync();
    setLocationPermission(status === "granted");
  };

  const requestCalendarPermission = async () => {
    const { status } = await Calendar.requestCalendarPermissionsAsync();
    setCalendarPermission(status === "granted");
  };

  const requestNotificationPermission = async () => {
    const { status } = await Notifications.requestPermissionsAsync();
    setNotificationPermission(status === "granted");
  };

  const handleToggleLocation = async (enabled: boolean) => {
    if (enabled) {
      await requestLocationPermission();
    } else {
      Alert.alert(
        "Location Permission",
        "To disable location permission, please go to your device Settings."
      );
    }
  };

  const handleToggleCalendar = async (enabled: boolean) => {
    if (enabled) {
      await requestCalendarPermission();
    } else {
      Alert.alert(
        "Calendar Permission",
        "To disable calendar permission, please go to your device Settings."
      );
    }
  };

  const handleToggleNotifications = async (enabled: boolean) => {
    if (enabled) {
      await requestNotificationPermission();
    } else {
      Alert.alert(
        "Notifications Permission",
        "To disable notifications, please go to your device Settings."
      );
    }
  };

  const handleSavePreferencesToggle = async (enabled: boolean) => {
    try {
      const preferencesStr = await AsyncStorage.getItem("userPreferences");
      const preferences = preferencesStr
        ? JSON.parse(preferencesStr)
        : {};
      preferences.usePreferencesForPersonalization = enabled;
      await AsyncStorage.setItem(
        "userPreferences",
        JSON.stringify(preferences)
      );
      setUsePreferencesForPersonalization(enabled);
    } catch (error) {
      console.error("Error saving preferences toggle:", error);
    }
  };

  return (
    <View style={styles.container}>
      <LinearGradient
        colors={[colors.background, colors.backgroundSecondary, colors.background]}
        style={styles.gradient}
      />

      {/* Blur Shapes */}
      <View style={styles.blurShape1} />
      <View style={styles.blurShape2} />

      <ScrollView
        contentContainerStyle={[
          styles.scrollContent,
          { paddingTop: insets.top + 20, paddingBottom: insets.bottom + 100 },
        ]}
        showsVerticalScrollIndicator={false}
      >
        <View style={styles.content}>
          <Text style={styles.title}>Settings</Text>

          {/* Account Settings Section */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Account Settings</Text>

            <View style={styles.card}>
              <View style={styles.inputContainer}>
                <Text style={styles.inputLabel}>First Name</Text>
                <View style={styles.inputWrapper}>
                  <BlurView
                    intensity={Platform.OS === "ios" ? 40 : 30}
                    tint="dark"
                    style={styles.inputBlur}
                  >
                    <View style={styles.inputGlassOverlay} />
                    <TextInput
                      style={styles.input}
                      placeholder="Enter your first name"
                      placeholderTextColor={colors.textSecondary}
                      value={firstName}
                      onChangeText={setFirstName}
                      autoCapitalize="words"
                    />
                  </BlurView>
                </View>
                <TouchableOpacity
                  style={styles.saveButton}
                  onPress={handleSaveFirstName}
                >
                  <Text style={styles.saveButtonText}>Save</Text>
                </TouchableOpacity>
              </View>
            </View>

            <SettingRow
              icon="🔒"
              title="Change Password"
              onPress={() => router.push("/settings/change-password")}
              showArrow
            />

            <SettingRow
              icon="🚪"
              title="Log Out"
              onPress={handleLogout}
              showArrow
            />
          </View>

          {/* Preferences Section */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Preferences</Text>
            <SettingRow
              icon="⚙️"
              title="Edit Preferences"
              description="Update your preferences and interests"
              onPress={() => router.push("/settings/preferences")}
              showArrow
            />
          </View>

          {/* Permissions Section */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Permissions</Text>

            <SettingRow
              icon="📍"
              title="Location"
              description="Find awesome spots near you"
              rightElement={
                <Switch
                  value={locationPermission}
                  onValueChange={handleToggleLocation}
                  trackColor={{
                    false: colors.border,
                    true: colors.gradientStart,
                  }}
                />
              }
            />

            <SettingRow
              icon="📅"
              title="Google Calendar"
              description="Recommend events when you're available"
              rightElement={
                <Switch
                  value={calendarPermission}
                  onValueChange={handleToggleCalendar}
                  trackColor={{
                    false: colors.border,
                    true: colors.gradientStart,
                  }}
                />
              }
            />

            <SettingRow
              icon="🔔"
              title="Notifications"
              description="Personalized recommendations"
              rightElement={
                <Switch
                  value={notificationPermission}
                  onValueChange={handleToggleNotifications}
                  trackColor={{
                    false: colors.border,
                    true: colors.gradientStart,
                  }}
                />
              }
            />

            <SettingRow
              icon="🎯"
              title="Use preferences to personalize results"
              rightElement={
                <Switch
                  value={usePreferencesForPersonalization}
                  onValueChange={handleSavePreferencesToggle}
                  trackColor={{
                    false: colors.border,
                    true: colors.gradientStart,
                  }}
                />
              }
            />
          </View>

          {/* Trusted Contacts Section */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Trusted Contacts</Text>
            <SettingRow
              icon="👥"
              title="Manage Trusted Contacts"
              description={`${trustedContactsCount} contact${
                trustedContactsCount !== 1 ? "s" : ""
              }`}
              onPress={() => router.push("/settings/trusted-contacts")}
              showArrow
            />
          </View>

          {/* Home Address Section */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Home Address</Text>
            <View style={styles.card}>
              <View style={styles.inputContainer}>
                <Text style={styles.inputLabel}>Address</Text>
                <LocationPicker
                  value={homeAddress}
                  onChangeText={setHomeAddress}
                  placeholder="Enter your home address"
                />
                <TouchableOpacity
                  style={styles.saveButton}
                  onPress={handleSaveHomeAddress}
                >
                  <Text style={styles.saveButtonText}>Save</Text>
                </TouchableOpacity>
              </View>
            </View>
          </View>
        </View>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  gradient: {
    ...StyleSheet.absoluteFillObject,
  },
  blurShape1: {
    position: "absolute",
    top: -100,
    left: -50,
    width: 300,
    height: 300,
    borderRadius: 150,
    backgroundColor: colors.accentPurpleMedium,
    opacity: 0.6,
  },
  blurShape2: {
    position: "absolute",
    bottom: -80,
    right: -80,
    width: 250,
    height: 250,
    borderRadius: 125,
    backgroundColor: colors.accentBlue,
    opacity: 0.5,
  },
  scrollContent: {
    flexGrow: 1,
    paddingHorizontal: spacing["2xl"],
  },
  content: {
    flex: 1,
  },
  title: {
    fontSize: typography.fontSize["3xl"],
    fontWeight: typography.fontWeight.bold,
    color: colors.textPrimary,
    marginBottom: spacing["4xl"],
  },
  section: {
    marginBottom: spacing["4xl"],
  },
  sectionTitle: {
    fontSize: typography.fontSize["2xl"],
    fontWeight: typography.fontWeight.bold,
    color: colors.textPrimary,
    marginBottom: spacing["2xl"],
  },
  card: {
    borderRadius: borderRadius.md,
    overflow: "hidden",
    borderWidth: 1,
    borderColor: colors.border,
    marginBottom: spacing.md,
  },
  settingRow: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    paddingVertical: spacing.lg,
    paddingHorizontal: spacing["2xl"],
    borderRadius: borderRadius.md,
    borderWidth: 1,
    borderColor: colors.border,
    backgroundColor: colors.glassBackground,
    marginBottom: spacing.md,
  },
  settingRowContent: {
    flexDirection: "row",
    alignItems: "center",
    flex: 1,
  },
  settingRowIcon: {
    fontSize: 24,
    marginRight: spacing["2xl"],
  },
  settingRowText: {
    flex: 1,
  },
  settingRowTitle: {
    fontSize: typography.fontSize.base,
    fontWeight: typography.fontWeight.semiBold,
    color: colors.textPrimary,
    marginBottom: spacing.xs,
  },
  settingRowDescription: {
    fontSize: typography.fontSize.sm,
    fontWeight: typography.fontWeight.regular,
    color: colors.textSecondary,
  },
  settingRowRight: {
    marginLeft: spacing.md,
  },
  settingRowArrow: {
    fontSize: 24,
    color: colors.textSecondary,
    marginLeft: spacing.md,
  },
  inputContainer: {
    padding: spacing["2xl"],
  },
  inputLabel: {
    fontSize: typography.fontSize.sm,
    fontWeight: typography.fontWeight.semiBold,
    color: colors.textSecondary,
    marginBottom: spacing.sm,
  },
  inputWrapper: {
    borderRadius: borderRadius.md,
    overflow: "hidden",
    borderWidth: 1,
    borderColor: colors.border,
    marginBottom: spacing.md,
  },
  inputBlur: {
    ...StyleSheet.absoluteFillObject,
  },
  inputGlassOverlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: colors.glassBackground,
  },
  input: {
    paddingHorizontal: spacing["2xl"],
    paddingVertical: spacing["2xl"],
    fontSize: typography.fontSize.base,
    color: colors.textPrimary,
    minHeight: 56,
  },
  saveButton: {
    backgroundColor: colors.gradientStart,
    paddingVertical: spacing.md,
    paddingHorizontal: spacing["2xl"],
    borderRadius: borderRadius.md,
    alignItems: "center",
  },
  saveButtonText: {
    fontSize: typography.fontSize.base,
    fontWeight: typography.fontWeight.semiBold,
    color: colors.textPrimary,
  },
});

