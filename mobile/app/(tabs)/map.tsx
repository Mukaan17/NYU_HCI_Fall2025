// mobile/app/(tabs)/map.tsx
import React, { useEffect, useState } from "react";
import {
  View,
  Text,
  StyleSheet,
  Dimensions,
  StyleProp,
  ViewStyle,
  Image,
} from "react-native";
import MapView, { Marker, Polyline, LatLng, Region } from "react-native-maps";
import { LinearGradient } from "expo-linear-gradient";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import useLocation from "../../hooks/useLocation";
import { usePlace } from "../../context/PlaceContext";
import { colors, typography, spacing, borderRadius } from "../../constants/theme";

const { width, height } = Dimensions.get("window");

const BACKEND_URL =
  process.env.EXPO_PUBLIC_API_URL || "http://localhost:5000";

// NYU Tandon default
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

  /* ---------------------- Update map region ---------------------- */
  useEffect(() => {
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

    setRegion({
      latitude: DEFAULT_LAT,
      longitude: DEFAULT_LNG,
      latitudeDelta: 0.01,
      longitudeDelta: 0.01,
    });
  }, [selectedPlace, location, loading]);

  /* ------------------------ Fetch walking route ------------------------ */
  const fetchRoute = async (destLat: number, destLng: number) => {
    try {
      const url = `${BACKEND_URL}/api/directions?lat=${destLat}&lng=${destLng}`;
      const res = await fetch(url);
      const data = await res.json();

      if (Array.isArray(data.polyline)) setPolylineCoords(data.polyline);
      else setPolylineCoords([]);
    } catch (err) {
      console.log("Route error:", err);
      setPolylineCoords([]);
    }
  };

  const markerLat = selectedPlace?.latitude ?? DEFAULT_LAT;
  const markerLng = selectedPlace?.longitude ?? DEFAULT_LNG;

  const markerTitle = selectedPlace?.name ?? "2 MetroTech Center";
  const markerMeta =
    selectedPlace && (selectedPlace.walkTime || selectedPlace.distance)
      ? `${selectedPlace.walkTime ?? ""} • ${selectedPlace.distance ?? ""}`
      : "Home base • NYU Tandon";

  return (
    <View style={styles.container}>
      {/* Map */}
      <MapView
        style={styles.map as StyleProp<ViewStyle>}
        region={region}
        showsUserLocation
        showsMyLocationButton={false}
      >
        <Marker coordinate={{ latitude: markerLat, longitude: markerLng }} />
        {polylineCoords.length > 0 && (
          <Polyline coordinates={polylineCoords} strokeColor="#5B4BFF" strokeWidth={5} />
        )}
      </MapView>

      {/* UI Overlay */}
      <View style={styles.overlayContainer}>
        {/* Center Pulse */}
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

        {/* Centered Address Badge */}
        <View
          style={[
            styles.addressBadge,
            { top: insets.top + spacing["2xl"] },
          ]}
        >
          <LinearGradient
            colors={[colors.glassBackgroundLight, colors.glassBackgroundDarkLight]}
            style={styles.addressBadgeGradient}
          >
            <Text style={styles.addressIcon}>📍</Text>
            <Text style={styles.addressText}>
              {selectedPlace?.address ?? "2 MetroTech Center"}
            </Text>
          </LinearGradient>
        </View>

        {/* Bottom Sheet */}
        <LinearGradient
          colors={["transparent", colors.backgroundOverlay, colors.background]}
          style={[
            styles.bottomSheet,
            { paddingBottom: Math.max(insets.bottom, spacing["2xl"]) + 90 },
          ]}
        >
          <View style={styles.bottomSheetContent}>
            <View style={styles.bottomSheetInfo}>
              {selectedPlace?.image && (
                <Image
                  source={{ uri: selectedPlace.image }}
                  style={styles.bottomImage}
                  resizeMode="cover"
                />
              )}

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

/* --------------------------- Styles --------------------------- */

const styles = StyleSheet.create({
  container: { flex: 1 },
  map: { ...StyleSheet.absoluteFillObject },

  overlayContainer: {
    ...StyleSheet.absoluteFillObject,
    pointerEvents: "box-none",
  },

  /* User Location Pulse */
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
  locationGradient: { width: "100%", height: "100%" },
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
    opacity: 0.35,
    top: -30,
    left: -30,
  },

  /* Centered Address Badge */
  addressBadge: {
    position: "absolute",
    alignSelf: "center",
    maxWidth: width * 0.8,
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
  addressIcon: { fontSize: 15 },
  addressText: {
    fontSize: typography.fontSize.base,
    fontWeight: typography.fontWeight.semiBold,
    color: colors.textPrimary,
  },

  /* Bottom Sheet */
  bottomSheet: {
    position: "absolute",
    bottom: 0,
    width: "100%",
    paddingTop: spacing["3xl"],
    paddingHorizontal: spacing["2xl"],
  },
  bottomSheetContent: {
    backgroundColor: colors.glassBackground,
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    borderColor: colors.border,
    padding: spacing.xs,
  },
  bottomSheetInfo: { padding: spacing["2xl"] },

  bottomImage: {
    width: "100%",
    height: 160,
    borderRadius: 12,
    marginBottom: 12,
  },

  placeTitle: {
    fontSize: typography.fontSize["2xl"],
    fontWeight: typography.fontWeight.semiBold,
    color: colors.textPrimary,
    marginBottom: spacing.xs,
  },
  placeMeta: {
    fontSize: typography.fontSize.base,
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
