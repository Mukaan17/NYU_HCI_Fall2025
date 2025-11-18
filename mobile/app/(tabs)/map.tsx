// app/(tabs)/map.tsx
import React, { useEffect, useState } from "react";
import {
  View,
  Text,
  StyleSheet,
  Dimensions,
  StyleProp,
  ViewStyle,
} from "react-native";
import MapView, { Marker, Polyline, LatLng, Region } from "react-native-maps";
import { LinearGradient } from "expo-linear-gradient";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import useLocation from "../../hooks/useLocation";
import { usePlace } from "../../context/PlaceContext";
import { colors, typography, spacing, borderRadius } from "../../constants/theme";

const { width, height } = Dimensions.get("window");

const BACKEND_URL =
  process.env.EXPO_PUBLIC_API_URL || "http://192.168.1.155:5000";

// 2 MetroTech Center (Tandon) as default
const DEFAULT_LAT = 40.693393;
const DEFAULT_LNG = -73.98555;

export default function Map() {
  const insets = useSafeAreaInsets();
  const { selectedPlace } = usePlace();
  const { location, loading } = useLocation();

  const [polylineCoords, setPolylineCoords] = useState<LatLng[]>([]);
  const [region, setRegion] = useState<Region>({
    latitude: DEFAULT_LAT,
    longitude: DEFAULT_LNG,
    latitudeDelta: 0.01,
    longitudeDelta: 0.01,
  });

  // Update region + route whenever selection or user location changes
  useEffect(() => {
    // If we have a selected place: center on it and fetch route
    if (selectedPlace) {
      const destLat = selectedPlace.latitude ?? DEFAULT_LAT;
      const destLng = selectedPlace.longitude ?? DEFAULT_LNG;

      setRegion({
        latitude: destLat,
        longitude: destLng,
        latitudeDelta: 0.01,
        longitudeDelta: 0.01,
      });

      fetchRoute(destLat, destLng);
      return;
    }

    // No selected place → center on user if we have it
    if (location && !loading) {
      setRegion({
        latitude: location.latitude,
        longitude: location.longitude,
        latitudeDelta: 0.01,
        longitudeDelta: 0.01,
      });
      setPolylineCoords([]);
      return;
    }

    // Fallback: default Tandon
    setRegion({
      latitude: DEFAULT_LAT,
      longitude: DEFAULT_LNG,
      latitudeDelta: 0.01,
      longitudeDelta: 0.01,
    });
    setPolylineCoords([]);
  }, [selectedPlace, location, loading]);

  const fetchRoute = async (destLat: number, destLng: number) => {
    try {
      // Backend is responsible for choosing the origin (e.g. 2 MetroTech)
      const url = `${BACKEND_URL}/api/directions?lat=${destLat}&lng=${destLng}`;
      const response = await fetch(url);
      const data = await response.json();

      if (data.polyline && Array.isArray(data.polyline)) {
        setPolylineCoords(data.polyline as LatLng[]);
      } else {
        setPolylineCoords([]);
      }
    } catch (err) {
      console.log("Directions error:", err);
      setPolylineCoords([]);
    }
  };

  const markerLat = selectedPlace?.latitude ?? DEFAULT_LAT;
  const markerLng = selectedPlace?.longitude ?? DEFAULT_LNG;
  const markerTitle = selectedPlace?.name ?? "2 MetroTech Center";
  const markerMeta =
    selectedPlace && (selectedPlace.walkTime || selectedPlace.distance)
      ? `${selectedPlace.walkTime ?? "Walk time N/A"} • ${
          selectedPlace.distance ?? "Distance N/A"
        }`
      : "Home base • NYU Tandon";

  return (
    <View style={styles.container}>
      {/* Base map */}
      <MapView
        style={styles.map as StyleProp<ViewStyle>}
        region={region}
        onRegionChangeComplete={setRegion}
        showsUserLocation
        showsMyLocationButton={false}
        followsUserLocation={false}
      >
        <Marker
          coordinate={{ latitude: markerLat, longitude: markerLng }}
          title={markerTitle}
        />

        {polylineCoords.length > 0 && (
          <Polyline
            coordinates={polylineCoords}
            strokeColor="#5B4BFF"
            strokeWidth={5}
          />
        )}
      </MapView>

      {/* Overlay UI (JS visual layout) */}
      <View style={styles.overlayContainer}>
        {/* Center location indicator (only if we have user location) */}
        {location && (
          <View style={styles.locationIndicator}>
            <View style={styles.locationDot}>
              <LinearGradient
                colors={[colors.gradientStart, colors.gradientEnd]}
                style={styles.locationGradient}
              />
            </View>
            <View style={styles.locationRing} />
            <View style={styles.locationRingOuter} />
          </View>
        )}

        {/* Address badge at top */}
        <View
          style={[
            styles.addressBadge,
            { top: insets.top + spacing["2xl"] },
          ]}
        >
          <LinearGradient
            colors={[
              colors.glassBackgroundLight,
              colors.glassBackgroundDarkLight,
            ]}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 0 }}
            style={styles.addressBadgeGradient}
          >
            <Text style={styles.addressIcon}>📍</Text>
            <Text style={styles.addressText}>
              {selectedPlace?.address ?? "2 MetroTech Center"}
            </Text>
          </LinearGradient>
        </View>

        {/* Bottom sheet – NO RecommendationCard, just info + directions placeholder */}
        <LinearGradient
          colors={[
            "transparent",
            colors.backgroundOverlay,
            colors.background,
          ]}
          locations={[0, 0.5, 1]}
          style={[
            styles.bottomSheet,
            {
              paddingBottom:
                Math.max(insets.bottom, spacing["2xl"]) + 90, // keep room for NavBar
            },
          ]}
        >
          <View style={styles.bottomSheetContent}>
            <View style={styles.bottomSheetInfo}>
              <Text style={styles.placeTitle}>{markerTitle}</Text>
              <Text style={styles.placeMeta}>{markerMeta}</Text>
              <Text style={styles.placeholderText}>
                Walking directions coming soon…
              </Text>
            </View>
          </View>
        </LinearGradient>
      </View>
    </View>
  );
}

/* ---------- STYLES (from JS layout, adjusted for TSX/Context) ---------- */

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  map: {
    ...StyleSheet.absoluteFillObject,
    width: "100%",
    height: "100%",
  },
  overlayContainer: {
    ...StyleSheet.absoluteFillObject,
    pointerEvents: "box-none",
  },
  /* Center pulse around user location */
  locationIndicator: {
    position: "absolute",
    left: width / 2 - 10,
    top: height / 2 - 10,
    width: 20,
    height: 20,
    alignItems: "center",
    justifyContent: "center",
  },
  locationDot: {
    width: 20,
    height: 20,
    borderRadius: 10,
    borderWidth: 4,
    borderColor: colors.textPrimary,
    overflow: "hidden",
  },
  locationGradient: {
    width: "100%",
    height: "100%",
  },
  locationRing: {
    position: "absolute",
    width: 64,
    height: 64,
    borderRadius: 32,
    borderWidth: 2,
    borderColor: colors.gradientStart,
    opacity: 0.3,
    top: -22,
    left: -22,
  },
  locationRingOuter: {
    position: "absolute",
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: colors.gradientStart,
    opacity: 0.371,
    top: -30,
    left: -30,
  },

  /* Address badge */
  addressBadge: {
    position: "absolute",
    left: width * 0.25,
    maxWidth: width * 0.7,
    borderRadius: borderRadius.md,
    overflow: "hidden",
  },
  addressBadgeGradient: {
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: spacing["3xl"],
    paddingVertical: spacing["2xl"],
    gap: spacing.md,
    borderWidth: 1,
    borderColor: colors.border,
  },
  addressIcon: {
    fontSize: 15,
  },
  addressText: {
    fontSize: typography.fontSize.base,
    fontWeight: typography.fontWeight.semiBold,
    color: colors.textPrimary,
  },

  /* Bottom sheet */
  bottomSheet: {
    position: "absolute",
    bottom: 0,
    left: 0,
    right: 0,
    paddingTop: spacing["3xl"], // 20pt top padding
    paddingHorizontal: spacing["2xl"], // 16pt horizontal padding
    paddingBottom: 100, // will be overridden with safe area + nav height
  },
  bottomSheetContent: {
    backgroundColor: colors.glassBackground,
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    borderColor: colors.border,
    padding: spacing.xs,
  },
  bottomSheetInfo: {
    padding: spacing["2xl"],
  },
  placeTitle: {
    fontSize: typography.fontSize["2xl"],
    fontWeight: typography.fontWeight.semiBold,
    color: colors.textPrimary,
    marginBottom: spacing.xs,
  },
  placeMeta: {
    fontSize: typography.fontSize.base,
    fontWeight: typography.fontWeight.regular,
    color: colors.textSecondary,
    marginBottom: spacing.lg,
  },
  placeholderText: {
    fontSize: typography.fontSize.sm,
    color: colors.textSecondary,
    opacity: 0.8,
  },
});

export {};
