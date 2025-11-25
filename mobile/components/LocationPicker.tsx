// components/LocationPicker.tsx
import React, { useState, useEffect } from "react";
import {
  View,
  Text,
  TextInput,
  FlatList,
  TouchableOpacity,
  StyleSheet,
  Platform,
  ActivityIndicator,
} from "react-native";
import { BlurView } from "expo-blur";
import { colors, typography, spacing, borderRadius } from "../constants/theme";

interface LocationSuggestion {
  id: string;
  title: string;
  subtitle?: string;
}

interface LocationPickerProps {
  value: string;
  onChangeText: (text: string) => void;
  onSelect?: (location: LocationSuggestion) => void;
  placeholder?: string;
}

export default function LocationPicker({
  value,
  onChangeText,
  onSelect,
  placeholder = "Enter address",
}: LocationPickerProps) {
  const [suggestions, setSuggestions] = useState<LocationSuggestion[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [showSuggestions, setShowSuggestions] = useState(false);

  // Debounce search
  useEffect(() => {
    if (value.length < 3) {
      setSuggestions([]);
      setShowSuggestions(false);
      return;
    }

    const timeoutId = setTimeout(() => {
      searchLocations(value);
    }, 300);

    return () => clearTimeout(timeoutId);
  }, [value]);

  const searchLocations = async (query: string) => {
    setIsLoading(true);
    setShowSuggestions(true);

    try {
      // In production, use Google Places API or similar
      // For now, return mock suggestions
      const mockSuggestions: LocationSuggestion[] = [
        {
          id: "1",
          title: `${query} Street`,
          subtitle: "New York, NY",
        },
        {
          id: "2",
          title: `${query} Avenue`,
          subtitle: "Brooklyn, NY",
        },
        {
          id: "3",
          title: `${query} Boulevard`,
          subtitle: "Manhattan, NY",
        },
      ];

      setSuggestions(mockSuggestions);
    } catch (error) {
      console.error("Error searching locations:", error);
      setSuggestions([]);
    } finally {
      setIsLoading(false);
    }
  };

  const handleSelectSuggestion = (suggestion: LocationSuggestion) => {
    onChangeText(suggestion.title);
    setShowSuggestions(false);
    if (onSelect) {
      onSelect(suggestion);
    }
  };

  return (
    <View style={styles.container}>
      <View style={styles.inputWrapper}>
        <BlurView
          intensity={Platform.OS === "ios" ? 40 : 30}
          tint="dark"
          style={styles.inputBlur}
        >
          <View style={styles.inputGlassOverlay} />
          <TextInput
            style={styles.input}
            placeholder={placeholder}
            placeholderTextColor={colors.textSecondary}
            value={value}
            onChangeText={onChangeText}
            autoCapitalize="words"
            onFocus={() => {
              if (suggestions.length > 0) {
                setShowSuggestions(true);
              }
            }}
          />
          {isLoading && (
            <View style={styles.loadingIndicator}>
              <ActivityIndicator size="small" color={colors.textSecondary} />
            </View>
          )}
        </BlurView>
      </View>

      {showSuggestions && suggestions.length > 0 && (
        <View style={styles.suggestionsContainer}>
          <BlurView
            intensity={Platform.OS === "ios" ? 60 : 40}
            tint="dark"
            style={styles.suggestionsBlur}
          >
            <View style={styles.suggestionsGlassOverlay} />
            <FlatList
              data={suggestions}
              keyExtractor={(item) => item.id}
              renderItem={({ item }) => (
                <TouchableOpacity
                  style={styles.suggestionItem}
                  onPress={() => handleSelectSuggestion(item)}
                  activeOpacity={0.7}
                >
                  <Text style={styles.suggestionTitle}>{item.title}</Text>
                  {item.subtitle && (
                    <Text style={styles.suggestionSubtitle}>{item.subtitle}</Text>
                  )}
                </TouchableOpacity>
              )}
              style={styles.suggestionsList}
              keyboardShouldPersistTaps="handled"
            />
          </BlurView>
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    position: "relative",
    zIndex: 1,
  },
  inputWrapper: {
    borderRadius: borderRadius.md,
    overflow: "hidden",
    borderWidth: 1,
    borderColor: colors.border,
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
  loadingIndicator: {
    position: "absolute",
    right: spacing["2xl"],
    top: spacing["2xl"],
  },
  suggestionsContainer: {
    marginTop: spacing.xs,
    borderRadius: borderRadius.md,
    overflow: "hidden",
    borderWidth: 1,
    borderColor: colors.border,
    maxHeight: 200,
  },
  suggestionsBlur: {
    ...StyleSheet.absoluteFillObject,
  },
  suggestionsGlassOverlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: colors.glassBackground,
  },
  suggestionsList: {
    maxHeight: 200,
  },
  suggestionItem: {
    paddingHorizontal: spacing["2xl"],
    paddingVertical: spacing.lg,
    borderBottomWidth: 1,
    borderBottomColor: colors.border,
  },
  suggestionTitle: {
    fontSize: typography.fontSize.base,
    fontWeight: typography.fontWeight.semiBold,
    color: colors.textPrimary,
    marginBottom: spacing.xs,
  },
  suggestionSubtitle: {
    fontSize: typography.fontSize.sm,
    fontWeight: typography.fontWeight.regular,
    color: colors.textSecondary,
  },
});

