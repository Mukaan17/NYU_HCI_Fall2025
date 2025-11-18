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

type QuickPlace = {
  name: string;
  address: string | null;
  walk_time: string | null;
  distance: string | null;
  rating: number | null;
  maps_link: string | null;
  photo_url?: string | null;
  location: { lat: number; lng: number };
  score: number;
};

export default function QuickResults() {
  const params = useLocalSearchParams();
  const { setSelectedPlace } = usePlace();

  const category = Array.isArray(params.category)
    ? params.category[0]
    : params.category || "explore";

  const [loading, setLoading] = useState(true);
  const [places, setPlaces] = useState<QuickPlace[]>([]);

  useEffect(() => {
    fetchQuickRecs();
  }, [category]);

  async function fetchQuickRecs() {
    try {
      setLoading(true);
      const res = await fetch(
        `${process.env.EXPO_PUBLIC_API_URL}/api/quick_recs?category=${category}`
      );
      const data = await res.json();
      setPlaces(data.places || []);
    } catch (err) {
      console.error("Quick recs error:", err);
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

  const handlePress = (p: QuickPlace) => {
    setSelectedPlace({
      name: p.name,
      latitude: p.location.lat,
      longitude: p.location.lng,
      walkTime: p.walk_time || undefined,
      distance: p.distance|| undefined,
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
        ) : places.length === 0 ? (
          <Text style={styles.empty}>No places found</Text>
        ) : (
          places.map((p, idx) => (
            <RecommendationCard
              key={idx}
              title={p.name}
              description={p.address || ""}
              walkTime={p.walk_time || undefined}
              popularity={p.rating ? `${p.rating}★` : ""}
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
});
