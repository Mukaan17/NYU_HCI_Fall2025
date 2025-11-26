// app/settings/preferences.tsx
import React, { useState, useEffect } from "react";
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  TouchableOpacity,
  TextInput,
  Alert,
  Platform,
} from "react-native";
import { LinearGradient } from "expo-linear-gradient";
import { BlurView } from "expo-blur";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import AsyncStorage from "@react-native-async-storage/async-storage";
import Animated, { FadeInDown } from "react-native-reanimated";
import * as Haptics from "expo-haptics";

import LiquidGlassButton from "../../components/LiquidGlassButton";
import {
  colors,
  typography,
  spacing,
  borderRadius,
} from "../../constants/theme";
import { router } from "expo-router";

// Standalone preferences editor component

export default function Preferences() {
  const insets = useSafeAreaInsets();
  const [selectedCategories, setSelectedCategories] = useState<Set<string>>(
    new Set()
  );
  const [budgetSelection, setBudgetSelection] = useState("No preference");
  const [selectedDietaryRestrictions, setSelectedDietaryRestrictions] =
    useState<Set<string>>(new Set());
  const [walkingDistance, setWalkingDistance] = useState("No preference");
  const [hobbies, setHobbies] = useState("");
  const [isSaving, setIsSaving] = useState(false);

  const categoryOptions = [
    "Study Spots / Cozy Cafés",
    "Free Events & Pop-Ups",
    "Food Around Campus",
    "Nightlife",
    "Explore All / I'm open to anything",
  ];

  const dietaryOptions = [
    "Vegetarian",
    "Vegan",
    "Halal",
    "Kosher",
    "Gluten-Free",
    "Dairy-Free",
    "Pork-Free",
    "Seafood Allergy",
    "Other",
  ];

  useEffect(() => {
    loadPreferences();
  }, []);

  const loadPreferences = async () => {
    try {
      const preferencesStr = await AsyncStorage.getItem("userPreferences");
      if (preferencesStr) {
        const preferences = JSON.parse(preferencesStr);
        setSelectedCategories(new Set(preferences.categories || []));
        
        // Map budget back to selection
        if (preferences.budgetMin === 1 && preferences.budgetMax === 20) {
          setBudgetSelection("$");
        } else if (preferences.budgetMin === 21 && preferences.budgetMax === 50) {
          setBudgetSelection("$$");
        } else if (preferences.budgetMin === 51) {
          setBudgetSelection("$$$");
        } else {
          setBudgetSelection("No preference");
        }

        setSelectedDietaryRestrictions(
          new Set(preferences.dietaryRestrictions || [])
        );

        // Map walking distance back
        if (preferences.maxWalkMinutes === 10) {
          setWalkingDistance("5-10 min");
        } else if (preferences.maxWalkMinutes === 15) {
          setWalkingDistance("10-15 min");
        } else if (preferences.maxWalkMinutes === 20) {
          setWalkingDistance("15-20 min");
        } else {
          setWalkingDistance("No preference");
        }

        setHobbies(preferences.hobbies || "");
      }
    } catch (error) {
      console.error("Error loading preferences:", error);
    }
  };

  const toggleCategory = (category: string) => {
    const newSet = new Set(selectedCategories);
    if (newSet.has(category)) {
      newSet.delete(category);
    } else {
      newSet.add(category);
    }
    setSelectedCategories(newSet);
  };

  const toggleDietaryRestriction = (restriction: string) => {
    const newSet = new Set(selectedDietaryRestrictions);
    if (newSet.has(restriction)) {
      newSet.delete(restriction);
    } else {
      newSet.add(restriction);
    }
    setSelectedDietaryRestrictions(newSet);
  };

  const handleSave = async () => {
    setIsSaving(true);
    try {
      // Map budget selection to min/max
      let budgetMin: number | null = null;
      let budgetMax: number | null = null;
      if (budgetSelection === "$") {
        budgetMin = 1;
        budgetMax = 20;
      } else if (budgetSelection === "$$") {
        budgetMin = 21;
        budgetMax = 50;
      } else if (budgetSelection === "$$$") {
        budgetMin = 51;
        budgetMax = null;
      }

      // Map walking distance to minutes
      let maxWalkMinutes: number | null = null;
      if (walkingDistance === "5-10 min") {
        maxWalkMinutes = 10;
      } else if (walkingDistance === "10-15 min") {
        maxWalkMinutes = 15;
      } else if (walkingDistance === "15-20 min") {
        maxWalkMinutes = 20;
      }

      const preferences = {
        categories: Array.from(selectedCategories),
        budgetMin,
        budgetMax,
        dietaryRestrictions: Array.from(selectedDietaryRestrictions),
        maxWalkMinutes,
        hobbies: hobbies.trim() || null,
        googleCalendarEnabled: false,
        notificationsEnabled: false,
        usePreferencesForPersonalization: true,
      };

      await AsyncStorage.setItem(
        "userPreferences",
        JSON.stringify(preferences)
      );

      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      Alert.alert("Success", "Preferences updated successfully", [
        { text: "OK", onPress: () => router.back() },
      ]);
    } catch (error) {
      console.error("Error saving preferences:", error);
      Alert.alert("Error", "Failed to save preferences");
    } finally {
      setIsSaving(false);
    }
  };

  return (
    <View style={styles.container}>
      <LinearGradient
        colors={[colors.background, colors.backgroundSecondary, colors.background]}
        style={styles.gradient}
      />

      <View style={styles.blurShape1} />
      <View style={styles.blurShape2} />

      <ScrollView
        contentContainerStyle={[
          styles.scrollContent,
          { paddingTop: insets.top + 40, paddingBottom: insets.bottom + 20 },
        ]}
        showsVerticalScrollIndicator={false}
      >
        <View style={styles.content}>
          <Animated.View entering={FadeInDown.duration(400)} style={styles.titleContainer}>
            <Text style={styles.title}>Edit Preferences</Text>
            <Text style={styles.subtitle}>
              Update your preferences and interests
            </Text>
          </Animated.View>

          {/* Reuse the same structure as survey */}
          {/* What are you looking for? */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>What are you looking for?</Text>
            {categoryOptions.map((category) => (
              <TouchableOpacity
                key={category}
                style={[
                  styles.checkboxContainer,
                  selectedCategories.has(category) && styles.checkboxSelected,
                ]}
                onPress={() => toggleCategory(category)}
              >
                <Text
                  style={[
                    styles.checkboxText,
                    selectedCategories.has(category) && styles.checkboxTextSelected,
                  ]}
                >
                  {category}
                </Text>
                {selectedCategories.has(category) && (
                  <Text style={styles.checkboxIndicator}>✓</Text>
                )}
              </TouchableOpacity>
            ))}
          </View>

          {/* Budget */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Budget (Optional)</Text>
            <View style={styles.budgetContainer}>
              {["No preference", "$", "$$", "$$$"].map((option) => (
                <TouchableOpacity
                  key={option}
                  style={[
                    styles.budgetOption,
                    budgetSelection === option && styles.budgetOptionSelected,
                  ]}
                  onPress={() => setBudgetSelection(option)}
                >
                  <Text
                    style={[
                      styles.budgetOptionText,
                      budgetSelection === option && styles.budgetOptionTextSelected,
                    ]}
                  >
                    {option}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>
          </View>

          {/* Dietary Restrictions */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Dietary Restrictions</Text>
            {dietaryOptions.map((restriction) => (
              <TouchableOpacity
                key={restriction}
                style={[
                  styles.checkboxContainer,
                  selectedDietaryRestrictions.has(restriction) &&
                    styles.checkboxSelected,
                ]}
                onPress={() => toggleDietaryRestriction(restriction)}
              >
                <Text
                  style={[
                    styles.checkboxText,
                    selectedDietaryRestrictions.has(restriction) &&
                      styles.checkboxTextSelected,
                  ]}
                >
                  {restriction}
                </Text>
                {selectedDietaryRestrictions.has(restriction) && (
                  <Text style={styles.checkboxIndicator}>✓</Text>
                )}
              </TouchableOpacity>
            ))}
          </View>

          {/* Walking Distance */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Walking Distance from Campus</Text>
            <View style={styles.walkingDistanceContainer}>
              {["5-10 min", "10-15 min", "15-20 min", "No preference"].map(
                (option) => (
                  <TouchableOpacity
                    key={option}
                    style={[
                      styles.walkingDistanceOption,
                      walkingDistance === option &&
                        styles.walkingDistanceOptionSelected,
                    ]}
                    onPress={() => setWalkingDistance(option)}
                  >
                    <Text
                      style={[
                        styles.walkingDistanceOptionText,
                        walkingDistance === option &&
                          styles.walkingDistanceOptionTextSelected,
                      ]}
                    >
                      {option}
                    </Text>
                  </TouchableOpacity>
                )
              )}
            </View>
          </View>

          {/* Hobbies/Interests */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Hobbies / Interests (Optional)</Text>
            <View style={styles.hobbiesInputContainer}>
              <BlurView
                intensity={Platform.OS === "ios" ? 40 : 30}
                tint="dark"
                style={styles.hobbiesInputBlur}
              >
                <View style={styles.hobbiesInputGlassOverlay} />
                <TextInput
                  style={styles.hobbiesInput}
                  placeholder="Tell us about your interests"
                  placeholderTextColor={colors.textSecondary}
                  value={hobbies}
                  onChangeText={setHobbies}
                  multiline
                  numberOfLines={3}
                  textAlignVertical="top"
                />
              </BlurView>
            </View>
          </View>

          <LiquidGlassButton
            title="Save Preferences"
            onPress={handleSave}
            variant="gradient"
            disabled={isSaving}
            loading={isSaving}
            style={styles.saveButton}
          />
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
    paddingTop: spacing["4xl"],
  },
  titleContainer: {
    alignItems: "center",
    marginBottom: spacing["4xl"],
  },
  title: {
    fontSize: typography.fontSize["3xl"],
    fontWeight: typography.fontWeight.bold,
    color: colors.textPrimary,
    marginBottom: spacing.sm,
    textAlign: "center",
  },
  subtitle: {
    fontSize: typography.fontSize.lg,
    fontWeight: typography.fontWeight.regular,
    color: colors.textSecondary,
    textAlign: "center",
  },
  section: {
    marginBottom: spacing["4xl"],
  },
  sectionTitle: {
    fontSize: typography.fontSize.xl,
    fontWeight: typography.fontWeight.semiBold,
    color: colors.textPrimary,
    marginBottom: spacing["2xl"],
  },
  checkboxContainer: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    padding: spacing["2xl"],
    borderRadius: borderRadius.md,
    borderWidth: 1,
    borderColor: colors.border,
    backgroundColor: colors.glassBackground,
    marginBottom: spacing.md,
  },
  checkboxSelected: {
    borderColor: colors.gradientStart + "4D",
  },
  checkboxText: {
    fontSize: typography.fontSize.base,
    fontWeight: typography.fontWeight.regular,
    color: colors.textSecondary,
    flex: 1,
  },
  checkboxTextSelected: {
    fontWeight: typography.fontWeight.semiBold,
    color: colors.textPrimary,
  },
  checkboxIndicator: {
    width: 24,
    height: 24,
    borderRadius: 12,
    backgroundColor: colors.gradientStart,
    color: colors.textPrimary,
    fontSize: 14,
    fontWeight: typography.fontWeight.bold,
    textAlign: "center",
    lineHeight: 24,
    marginLeft: spacing.md,
  },
  budgetContainer: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: spacing.md,
  },
  budgetOption: {
    paddingHorizontal: spacing["2xl"],
    paddingVertical: spacing.lg,
    borderRadius: borderRadius.md,
    borderWidth: 1,
    borderColor: colors.border,
    backgroundColor: colors.glassBackground,
    minWidth: 80,
    alignItems: "center",
  },
  budgetOptionSelected: {
    borderColor: colors.gradientStart,
    backgroundColor: colors.gradientStart + "1A",
  },
  budgetOptionText: {
    fontSize: typography.fontSize.base,
    fontWeight: typography.fontWeight.regular,
    color: colors.textSecondary,
  },
  budgetOptionTextSelected: {
    fontWeight: typography.fontWeight.semiBold,
    color: colors.gradientStart,
  },
  walkingDistanceContainer: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: spacing.md,
  },
  walkingDistanceOption: {
    paddingHorizontal: spacing["2xl"],
    paddingVertical: spacing.lg,
    borderRadius: borderRadius.md,
    borderWidth: 1,
    borderColor: colors.border,
    backgroundColor: colors.glassBackground,
    minWidth: 100,
    alignItems: "center",
  },
  walkingDistanceOptionSelected: {
    borderColor: colors.gradientStart,
    backgroundColor: colors.gradientStart + "1A",
  },
  walkingDistanceOptionText: {
    fontSize: typography.fontSize.base,
    fontWeight: typography.fontWeight.regular,
    color: colors.textSecondary,
  },
  walkingDistanceOptionTextSelected: {
    fontWeight: typography.fontWeight.semiBold,
    color: colors.gradientStart,
  },
  hobbiesInputContainer: {
    borderRadius: borderRadius.md,
    overflow: "hidden",
    borderWidth: 1,
    borderColor: colors.border,
    minHeight: 100,
  },
  hobbiesInputBlur: {
    ...StyleSheet.absoluteFillObject,
  },
  hobbiesInputGlassOverlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: colors.glassBackground,
  },
  hobbiesInput: {
    paddingHorizontal: spacing["2xl"],
    paddingVertical: spacing["2xl"],
    fontSize: typography.fontSize.base,
    color: colors.textPrimary,
    minHeight: 100,
  },
  saveButton: {
    marginTop: spacing["2xl"],
    marginBottom: spacing["4xl"],
  },
});


