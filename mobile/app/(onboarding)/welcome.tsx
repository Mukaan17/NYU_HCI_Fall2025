import React from 'react';
import { View, Text, StyleSheet, Dimensions } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { BlurView } from 'expo-blur';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import AsyncStorage from '@react-native-async-storage/async-storage';
import PrimaryButton from '../../components/PrimaryButton';
import { colors, typography, spacing, borderRadius } from '../../constants/theme';
import { router } from "expo-router";

const { width, height } = Dimensions.get('window');

export default function Welcome() {
  const insets = useSafeAreaInsets();

  const handleLetsGo = async () => {
    await AsyncStorage.setItem('hasSeenWelcome', 'true');
    router.replace("/permissions");
  };

  return (
    <View style={styles.container}>
      <LinearGradient
        colors={[colors.gradientStart || "#000", colors.gradientEnd || "#333"]}
        style={StyleSheet.absoluteFill}
      />

      <BlurView intensity={40} tint="dark" style={styles.blurOverlay} />

      <View style={styles.content}>
        <Text style={styles.title}>Welcome!</Text>
        <Text style={styles.subtitle}>Let’s get your app set up.</Text>

        <PrimaryButton title="Let's Go" onPress={handleLetsGo} />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  blurOverlay: {
    ...StyleSheet.absoluteFillObject,
  },
  content: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    paddingHorizontal: spacing.lg || 24,
  },
  title: {
    fontSize: typography.heading || 28,
    fontWeight: "bold",
    color: colors.textPrimary || "#fff",
    marginBottom: spacing.md || 16,
  },
  subtitle: {
    fontSize: typography.body || 18,
    color: colors.textSecondary || "#ccc",
    marginBottom: spacing.xl || 24,
    textAlign: "center",
  },
});
