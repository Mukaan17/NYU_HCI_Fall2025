import React, { useEffect, useState } from "react";
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  ActivityIndicator,
  Pressable,
  Platform,
  Image,
} from "react-native";
import { useLocalSearchParams, router } from "expo-router";
import { LinearGradient } from "expo-linear-gradient";
import { BlurView } from "expo-blur";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { SymbolView } from "expo-symbols";
import * as Haptics from "expo-haptics";
import { LiquidGlassView, isLiquidGlassSupported } from "@callstack/liquid-glass";
import Animated, {
  FadeIn,
  FadeInDown,
  FadeInUp,
  SlideInDown,
  Easing,
} from "react-native-reanimated";

import { colors, spacing, typography, borderRadius } from "../../constants/theme";
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
  const insets = useSafeAreaInsets();

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
    if (Platform.OS === "ios") {
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    }
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

  const hasLiquidGlass = isLiquidGlassSupported;

  return (
    <View style={styles.container}>
      <LinearGradient
        colors={[colors.background, colors.backgroundSecondary, colors.background]}
        style={styles.gradient}
      />

      {/* Back Button */}
      <Pressable
        style={[styles.backButton, { top: insets.top + 10 }]}
        onPress={() => {
          if (Platform.OS === "ios") {
            Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
          }
          router.back();
        }}
      >
        {Platform.OS === "ios" ? (
          <SymbolView
            name="chevron.left"
            size={28}
            type="hierarchical"
            tintColor="#fff"
          />
        ) : (
          <Text style={styles.backArrow}>←</Text>
        )}
      </Pressable>

      <ScrollView
        contentContainerStyle={[styles.scroll, { paddingTop: insets.top + 80 }]}
        showsVerticalScrollIndicator={false}
      >
        <Animated.View entering={FadeInDown.delay(200).duration(400).easing(Easing.out(Easing.ease))}>
          <Text style={styles.title}>{readableTitle}</Text>
        </Animated.View>

        {loading ? (
          <ActivityIndicator size="large" color="#fff" style={{ marginTop: 40 }} />
        ) : places.length === 0 ? (
          <Animated.View entering={FadeIn.delay(400)}>
            <Text style={styles.empty}>No places found</Text>
          </Animated.View>
        ) : (
          <View style={styles.listContainer}>
            {places.map((p, idx) => (
              <Animated.View
                key={idx}
                entering={FadeInDown.delay(300 + idx * 100).duration(400).easing(Easing.out(Easing.ease))}
              >
                <Pressable
                key={idx}
                onPress={() => handlePress(p)}
                style={({ pressed }) => [
                  styles.listItem,
                  pressed && styles.listItemPressed,
                ]}
              >
                {hasLiquidGlass && Platform.OS === "ios" ? (
                  <LiquidGlassView
                    effect="regular"
                    style={styles.listItemContent}
                    tintColor="rgba(28, 37, 65, 0.6)"
                  >
                    <View style={styles.listItemRow}>
                      {p.photo_url && (
                        <Image
                          source={{ uri: p.photo_url }}
                          style={styles.listItemImage}
                          resizeMode="cover"
                        />
                      )}
                      <View style={styles.listItemTextContainer}>
                        <Text style={styles.listItemTitle} numberOfLines={1}>
                          {p.name}
                        </Text>
                        {p.address && (
                          <Text style={styles.listItemSubtitle} numberOfLines={1}>
                            {p.address}
                          </Text>
                        )}
                        <View style={styles.listItemBadges}>
                          {p.walk_time && (
                            <Text style={styles.listItemBadge}>{p.walk_time}</Text>
                          )}
                          {p.rating && (
                            <Text style={styles.listItemBadge}>{p.rating}★</Text>
                          )}
                        </View>
                      </View>
                      {Platform.OS === "ios" ? (
                        <SymbolView
                          name="chevron.right"
                          size={16}
                          type="hierarchical"
                          tintColor="rgba(255, 255, 255, 0.3)"
                        />
                      ) : (
                        <Text style={styles.chevron}>›</Text>
                      )}
                    </View>
                  </LiquidGlassView>
                ) : (
                  <View style={styles.listItemContent}>
                    <BlurView
                      intensity={Platform.OS === "ios" ? 50 : 35}
                      tint="systemChromeMaterialDark"
                      style={StyleSheet.absoluteFill}
                    />
                    <View style={styles.listItemRow}>
                      {p.photo_url && (
                        <Image
                          source={{ uri: p.photo_url }}
                          style={styles.listItemImage}
                          resizeMode="cover"
                        />
                      )}
                      <View style={styles.listItemTextContainer}>
                        <Text style={styles.listItemTitle} numberOfLines={1}>
                          {p.name}
                        </Text>
                        {p.address && (
                          <Text style={styles.listItemSubtitle} numberOfLines={1}>
                            {p.address}
                          </Text>
                        )}
                        <View style={styles.listItemBadges}>
                          {p.walk_time && (
                            <Text style={styles.listItemBadge}>{p.walk_time}</Text>
                          )}
                          {p.rating && (
                            <Text style={styles.listItemBadge}>{p.rating}★</Text>
                          )}
                        </View>
                      </View>
                      {Platform.OS === "ios" ? (
                        <SymbolView
                          name="chevron.right"
                          size={16}
                          type="hierarchical"
                          tintColor="rgba(255, 255, 255, 0.3)"
                        />
                      ) : (
                        <Text style={styles.chevron}>›</Text>
                      )}
                    </View>
                  </View>
                )}
              </Pressable>
              </Animated.View>
            ))}
          </View>
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
    left: spacing["2xl"],
    zIndex: 20,
    backgroundColor: "rgba(0,0,0,0.4)",
    padding: 8,
    borderRadius: 12,
  },
  backArrow: {
    fontSize: 28,
    color: "#fff",
  },

  scroll: {
    paddingHorizontal: spacing["2xl"],
    paddingBottom: 140,
  },

  title: {
    fontSize: typography.fontSize["3xl"],
    color: colors.textPrimary,
    fontWeight: typography.fontWeight.bold,
    marginBottom: spacing["3xl"],
    fontFamily: typography.fontFamily,
  },

  empty: {
    textAlign: "center",
    color: colors.textSecondary,
    fontSize: typography.fontSize.lg,
    marginTop: 40,
    fontFamily: typography.fontFamily,
  },

  listContainer: {
    gap: spacing.xs,
  },

  listItem: {
    borderRadius: borderRadius.md,
    overflow: "hidden",
    borderWidth: 0.5,
    borderColor: Platform.OS === "ios" ? colors.separator : "rgba(255, 255, 255, 0.1)",
    marginBottom: spacing.xs,
  },

  listItemPressed: {
    opacity: 0.7,
  },

  listItemContent: {
    paddingVertical: spacing["2xl"],
    paddingHorizontal: spacing["3xl"],
    minHeight: 72,
  },

  listItemRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: spacing["2xl"],
  },

  listItemImage: {
    width: 56,
    height: 56,
    borderRadius: borderRadius.sm,
    backgroundColor: colors.backgroundCardDark,
  },

  listItemTextContainer: {
    flex: 1,
    justifyContent: "center",
    gap: spacing.xs,
  },

  listItemTitle: {
    fontSize: typography.fontSize.lg,
    fontWeight: typography.fontWeight.semiBold,
    color: colors.textPrimary,
    fontFamily: typography.fontFamily,
  },

  listItemSubtitle: {
    fontSize: typography.fontSize.base,
    color: colors.textSecondary,
    fontFamily: typography.fontFamily,
  },

  listItemBadges: {
    flexDirection: "row",
    gap: spacing.md,
    marginTop: spacing.xs,
  },

  listItemBadge: {
    fontSize: typography.fontSize.xs,
    color: colors.textAccent,
    fontFamily: typography.fontFamily,
  },

  chevron: {
    fontSize: 20,
    color: "rgba(255, 255, 255, 0.3)",
    fontWeight: "300",
  },
});
