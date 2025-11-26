// app/(onboarding)/survey.tsx
import React, { useState } from "react";
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  TouchableOpacity,
  TextInput,
  Dimensions,
  Platform,
} from "react-native";
import { LinearGradient } from "expo-linear-gradient";
import { BlurView } from "expo-blur";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import AsyncStorage from "@react-native-async-storage/async-storage";
import Animated, {
  FadeInDown,
  useSharedValue,
  useAnimatedStyle,
  withSpring,
} from "react-native-reanimated";
import * as Haptics from "expo-haptics";

import LiquidGlassButton from "../../components/LiquidGlassButton";
import {
  colors,
  typography,
  spacing,
  borderRadius,
} from "../../constants/theme";
import { router } from "expo-router";

const { width } = Dimensions.get("window");

// Preference Checkbox Component
interface PreferenceCheckboxProps {
  title: string;
  isSelected: boolean;
  onPress: () => void;
}

function PreferenceCheckbox({
  title,
  isSelected,
  onPress,
}: PreferenceCheckboxProps) {
  const scale = useSharedValue(1);

  const handlePressIn = () => {
    scale.value = withSpring(0.95);
  };

  const handlePressOut = () => {
    scale.value = withSpring(1);
  };

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }],
  }));

  return (
    <Animated.View style={animatedStyle}>
      <TouchableOpacity
        onPress={() => {
          Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
          onPress();
        }}
        onPressIn={handlePressIn}
        onPressOut={handlePressOut}
        activeOpacity={0.8}
      >
        <View style={[styles.checkboxContainer, isSelected && styles.checkboxSelected]}>
          <BlurView
            intensity={Platform.OS === "ios" ? 40 : 30}
            tint="dark"
            style={styles.checkboxBlur}
          >
            <View style={styles.checkboxGlassOverlay} />
            <View style={styles.checkboxContent}>
              <Text style={[styles.checkboxText, isSelected && styles.checkboxTextSelected]}>
                {title}
              </Text>
              {isSelected && (
                <View style={styles.checkboxIndicator}>
                  <Text style={styles.checkboxIndicatorText}>✓</Text>
                </View>
              )}
            </View>
          </BlurView>
        </View>
      </TouchableOpacity>
    </Animated.View>
  );
}

// Budget Selector Component
interface BudgetSelectorProps {
  selection: string;
  onSelect: (option: string) => void;
}

function BudgetSelector({ selection, onSelect }: BudgetSelectorProps) {
  const options = ["No preference", "$", "$$", "$$$"];

  return (
    <View style={styles.budgetContainer}>
      {options.map((option) => (
        <TouchableOpacity
          key={option}
          onPress={() => {
            Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
            onSelect(option);
          }}
          activeOpacity={0.8}
        >
          <View
            style={[
              styles.budgetOption,
              selection === option && styles.budgetOptionSelected,
            ]}
          >
            <Text
              style={[
                styles.budgetOptionText,
                selection === option && styles.budgetOptionTextSelected,
              ]}
            >
              {option}
            </Text>
          </View>
        </TouchableOpacity>
      ))}
    </View>
  );
}

// Walking Distance Selector Component
interface WalkingDistanceSelectorProps {
  selection: string;
  onSelect: (option: string) => void;
}

function WalkingDistanceSelector({
  selection,
  onSelect,
}: WalkingDistanceSelectorProps) {
  const options = [
    "5-10 min",
    "10-15 min",
    "15-20 min",
    "No preference",
  ];

  return (
    <View style={styles.walkingDistanceContainer}>
      {options.map((option) => (
        <TouchableOpacity
          key={option}
          onPress={() => {
            Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
            onSelect(option);
          }}
          activeOpacity={0.8}
        >
          <View
            style={[
              styles.walkingDistanceOption,
              selection === option && styles.walkingDistanceOptionSelected,
            ]}
          >
            <Text
              style={[
                styles.walkingDistanceOptionText,
                selection === option && styles.walkingDistanceOptionTextSelected,
              ]}
            >
              {option}
            </Text>
          </View>
        </TouchableOpacity>
      ))}
    </View>
  );
}

// Preference Section Component
interface PreferenceSectionProps {
  title: string;
  children: React.ReactNode;
}

function PreferenceSection({ title, children }: PreferenceSectionProps) {
  return (
    <View style={styles.section}>
      <Text style={styles.sectionTitle}>{title}</Text>
      {children}
    </View>
  );
}

export default function Survey() {
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
      await AsyncStorage.setItem("hasCompletedOnboardingSurvey", "true");

      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      router.replace("/permissions");
    } catch (error) {
      console.error("Error saving preferences:", error);
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

      {/* Blur Shapes */}
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
          {/* Title */}
          <Animated.View entering={FadeInDown.duration(400)} style={styles.titleContainer}>
            <Text style={styles.title}>Tell us about yourself</Text>
            <Text style={styles.subtitle}>
              Help us personalize your experience
            </Text>
          </Animated.View>

          {/* What are you looking for? */}
          <PreferenceSection title="What are you looking for?">
            {categoryOptions.map((category) => (
              <PreferenceCheckbox
                key={category}
                title={category}
                isSelected={selectedCategories.has(category)}
                onPress={() => toggleCategory(category)}
              />
            ))}
          </PreferenceSection>

          {/* Budget */}
          <PreferenceSection title="Budget (Optional)">
            <BudgetSelector
              selection={budgetSelection}
              onSelect={setBudgetSelection}
            />
          </PreferenceSection>

          {/* Dietary Restrictions */}
          <PreferenceSection title="Dietary Restrictions">
            {dietaryOptions.map((restriction) => (
              <PreferenceCheckbox
                key={restriction}
                title={restriction}
                isSelected={selectedDietaryRestrictions.has(restriction)}
                onPress={() => toggleDietaryRestriction(restriction)}
              />
            ))}
          </PreferenceSection>

          {/* Walking Distance */}
          <PreferenceSection title="Walking Distance from Campus">
            <WalkingDistanceSelector
              selection={walkingDistance}
              onSelect={setWalkingDistance}
            />
          </PreferenceSection>

          {/* Hobbies/Interests */}
          <PreferenceSection title="Hobbies / Interests (Optional)">
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
          </PreferenceSection>

          {/* Save Button */}
          <LiquidGlassButton
            title="Continue"
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
    borderRadius: borderRadius.md,
    overflow: "hidden",
    borderWidth: 1,
    borderColor: colors.border,
    marginBottom: spacing.md,
  },
  checkboxSelected: {
    borderColor: colors.gradientStart + "4D",
  },
  checkboxBlur: {
    ...StyleSheet.absoluteFillObject,
  },
  checkboxGlassOverlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: colors.glassBackground,
  },
  checkboxContent: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    paddingHorizontal: spacing["2xl"],
    paddingVertical: spacing.lg,
    minHeight: 56,
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
    alignItems: "center",
    justifyContent: "center",
    marginLeft: spacing.md,
  },
  checkboxIndicatorText: {
    color: colors.textPrimary,
    fontSize: 14,
    fontWeight: typography.fontWeight.bold,
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

