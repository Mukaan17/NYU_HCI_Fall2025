import React, { useEffect, useState } from "react";
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  ActivityIndicator,
  TouchableOpacity,
} from "react-native";
import { useLocalSearchParams, router } from "expo-router";
import { LinearGradient } from "expo-linear-gradient";
import { Ionicons } from "@expo/vector-icons";

import RecommendationCard from "../../components/RecommendationCard";
import { colors, spacing, typography } from "../../constants/theme";
import { usePlace } from "../../context/PlaceContext";
import { useAuth } from "../../context/AuthContext";
import { apiService } from "../../services/apiService";
import { TopRecommendationsResponse, Recommendation } from "../../types/dashboard";
import { handleApiError, retryWithBackoff } from "../../utils/errorHandler";
import { Alert } from "react-native";

export default function QuickResults() {
  const params = useLocalSearchParams();
  const { setSelectedPlace } = usePlace();
  const { token, isAuthenticated } = useAuth();

  const category = Array.isArray(params.category)
    ? params.category[0]
    : params.category || "explore";

  const [loading, setLoading] = useState(true);
  const [places, setPlaces] = useState<Recommendation[]>([]);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let isMounted = true;
    
    async function loadData() {
      if (!isMounted) return;
      await fetchQuickRecs();
    }
    
    loadData();

    return () => {
      isMounted = false;
    };
  }, [category, token]);

  async function fetchQuickRecs() {
    try {
      setLoading(true);
      setError(null);
      
      // Use retry mechanism for API calls
      const fetchData = async () => {
        // Use top_recommendations endpoint if category is "explore" and authenticated
        if (category === "explore" && isAuthenticated && token) {
          try {
            const data = await apiService.get<TopRecommendationsResponse>("/api/top_recommendations", {
              limit: "10",
            });
            return data.places || [];
          } catch (error) {
            console.log("Top recommendations failed, falling back to quick_recs:", error);
            throw error; // Re-throw to trigger fallback
          }
        }
        
        // Fallback to quick_recs endpoint
        const data = await apiService.get<{ category: string; places: Recommendation[] }>("/api/quick_recs", {
          category,
          limit: "10",
        });
        return data.places || [];
      };
      
      const placesData = await retryWithBackoff(fetchData, 3, 1000);
      setPlaces(placesData);
    } catch (err) {
      console.error("Quick recs error:", err);
      const friendlyError = handleApiError(err);
      setError(friendlyError.message);
      if (!friendlyError.retryable) {
        Alert.alert(friendlyError.title, friendlyError.message);
      }
      setPlaces([]);
    } finally {
      setLoading(false);
    }
  }

  const readableTitle =
    {
      quick_bites: "Quick Bites",
      chill_cafes: "Chill Cafes",
      events: "Events Nearby",
      explore: "Explore",
    }[category] || "Discover";

  const handlePress = (p: Recommendation) => {
    setSelectedPlace({
      name: p.name,
      latitude: p.location?.lat || 40.693393,
      longitude: p.location?.lng || -73.98555,
      walkTime: p.walk_time || undefined,
      distance: p.distance || undefined,
      address: p.address || undefined,
    });

    router.push("/(tabs)/map");
  };

  return (
    <View style={styles.container}>
      <LinearGradient
        colors={[colors.background, colors.backgroundSecondary, colors.background]}
        style={styles.gradient}
      />

      {/* Back Button */}
      <TouchableOpacity style={styles.backButton} onPress={() => router.back()}>
        <Ionicons name="chevron-back" size={28} color="#fff" />
      </TouchableOpacity>

      <ScrollView contentContainerStyle={styles.scroll}>
        <Text style={styles.title}>{readableTitle}</Text>

        {loading ? (
          <ActivityIndicator size="large" color="#fff" style={{ marginTop: 40 }} />
        ) : error ? (
          <View style={styles.errorContainer}>
            <Text style={styles.errorText}>{error}</Text>
            <TouchableOpacity style={styles.retryButton} onPress={fetchQuickRecs}>
              <Text style={styles.retryButtonText}>Retry</Text>
            </TouchableOpacity>
          </View>
        ) : places.length === 0 ? (
          <Text style={styles.empty}>No places found</Text>
        ) : (
          places.map((p, idx) => (
            <RecommendationCard
              key={p.id || idx}
              title={p.name}
              description={p.address || p.description || ""}
              walkTime={p.walk_time || undefined}
              popularity={p.rating ? `⭐ ${p.rating}` : undefined}
              image={
                p.photo_url ||
                "https://upload.wikimedia.org/wikipedia/commons/6/65/No-Image-Placeholder.svg"
              }
              onPress={() => handlePress(p)}
            />
          ))
        )}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  gradient: { ...StyleSheet.absoluteFillObject },

  backButton: {
    position: "absolute",
    top: 50,
    left: 20,
    zIndex: 20,
    backgroundColor: "rgba(0,0,0,0.4)",
    padding: 8,
    borderRadius: 12,
  },

  scroll: {
    padding: spacing["2xl"],
    paddingTop: 110, // PUSH TITLE DOWN BELOW BACK BUTTON
    paddingBottom: 140,
  },

  title: {
    fontSize: typography.fontSize["3xl"],
    color: colors.textPrimary,
    fontWeight: typography.fontWeight.bold,
    marginBottom: spacing["3xl"],
  },

  empty: {
    textAlign: "center",
    color: colors.textSecondary,
    fontSize: typography.fontSize.lg,
    marginTop: 40,
  },
  errorContainer: {
    marginTop: 40,
    alignItems: "center",
    gap: spacing.lg,
  },
  errorText: {
    textAlign: "center",
    color: colors.textSecondary,
    fontSize: typography.fontSize.base,
  },
  retryButton: {
    paddingHorizontal: spacing.xl,
    paddingVertical: spacing.md,
    backgroundColor: colors.accentBlue,
    borderRadius: borderRadius.md,
  },
  retryButtonText: {
    color: colors.textPrimary,
    fontSize: typography.fontSize.base,
    fontWeight: typography.fontWeight.semiBold,
  },
});
