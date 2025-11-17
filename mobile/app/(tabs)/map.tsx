// app/(tabs)/map.tsx
import React, { useEffect, useState } from "react";
import { View, Text, StyleSheet } from "react-native";
import MapView, { Marker, Polyline, LatLng, Region } from "react-native-maps";
import { usePlace } from "../../context/PlaceContext";
import { colors, spacing, typography } from "../../constants/theme";

const BACKEND_URL =
  process.env.EXPO_PUBLIC_API_URL || "http://192.168.1.155:5000";

// 2 MetroTech Center (Tandon)
const DEFAULT_LAT = 40.693393;
const DEFAULT_LNG = -73.98555;

export default function Map() {
  const { selectedPlace } = usePlace();
  const [polylineCoords, setPolylineCoords] = useState<LatLng[]>([]);

  const [region, setRegion] = useState<Region>({
    latitude: DEFAULT_LAT,
    longitude: DEFAULT_LNG,
    latitudeDelta: 0.01,
    longitudeDelta: 0.01,
  });

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
    } else {
      // No selection → center on 2 MetroTech
      setRegion({
        latitude: DEFAULT_LAT,
        longitude: DEFAULT_LNG,
        latitudeDelta: 0.01,
        longitudeDelta: 0.01,
      });
      setPolylineCoords([]);
    }
  }, [selectedPlace]);

  const fetchRoute = async (destLat: number, destLng: number) => {
    try {
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

  return (
    <View style={{ flex: 1 }}>
      <MapView style={StyleSheet.absoluteFillObject} region={region}>
        <Marker
          coordinate={{
            latitude: markerLat,
            longitude: markerLng,
          }}
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

      <View style={styles.infoPanel}>
        <Text style={styles.title}>{markerTitle}</Text>
        {selectedPlace && (
          <Text style={styles.meta}>
            {selectedPlace.walkTime} • {selectedPlace.distance}
          </Text>
        )}
        {!selectedPlace && (
          <Text style={styles.meta}>Home base • NYU Tandon</Text>
        )}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  infoPanel: {
    position: "absolute",
    bottom: 30,
    left: 20,
    right: 20,
    backgroundColor: colors.background,
    borderRadius: 16,
    padding: spacing["2xl"],
    borderWidth: 1,
    borderColor: colors.border,
  },
  title: {
    fontSize: typography.fontSize["2xl"],
    fontWeight: "600",
    color: colors.textPrimary,
  },
  meta: {
    marginTop: 6,
    fontSize: typography.fontSize.lg,
    color: colors.textSecondary,
  },
});
