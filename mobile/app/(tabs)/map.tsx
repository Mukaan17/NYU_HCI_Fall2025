import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, Dimensions } from 'react-native';
import MapView, { Marker } from 'react-native-maps';
import { LinearGradient } from 'expo-linear-gradient';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import * as Location from 'expo-location';

import RecommendationCard from '../../components/RecommendationCard.js';
import { colors, spacing, typography, borderRadius } from '../../constants/theme';

const { width, height } = Dimensions.get('window');

export default function Map() {
  const insets = useSafeAreaInsets();

  const [location, setLocation] = useState<Location.LocationObjectCoords | null>(null);
  const [region, setRegion] = useState({
    latitude: 40.6934,
    longitude: -73.9857,
    latitudeDelta: 0.01,
    longitudeDelta: 0.01,
  });

  useEffect(() => {
    (async () => {
      const { status } = await Location.requestForegroundPermissionsAsync();
      if (status === 'granted') {
        const loc = await Location.getCurrentPositionAsync({});
        if (loc) {
          setLocation(loc.coords);
          setRegion({
            latitude: loc.coords.latitude,
            longitude: loc.coords.longitude,
            latitudeDelta: 0.01,
            longitudeDelta: 0.01,
          });
        }
      }
    })();
  }, []);

  const markers = [
    {
      id: 1,
      coordinate: { latitude: 40.6934, longitude: -73.9857 },
      title: 'Fulton Jazz Lounge',
    },
    {
      id: 2,
      coordinate: { latitude: 40.6920, longitude: -73.9840 },
      title: 'Brooklyn Rooftop',
    },
    {
      id: 3,
      coordinate: { latitude: 40.6940, longitude: -73.9860 },
      title: 'Butler Café',
    },
  ];

  return (
    <View style={styles.container}>
      <MapView
        style={styles.map}
        region={region}
        onRegionChangeComplete={setRegion}
        showsUserLocation
      >
        {markers.map((m) => (
          <Marker key={m.id} coordinate={m.coordinate} title={m.title} />
        ))}
      </MapView>

      <View style={styles.overlayContainer}>
        <View style={[styles.addressBadge, { top: insets.top + spacing['2xl'] }]}>
          <LinearGradient
            colors={['rgba(255,255,255,0.2)', 'rgba(255,255,255,0.1)']}
            style={styles.addressBadgeGradient}
          >
            <Text style={styles.addressIcon}>📍</Text>
            <Text style={styles.addressText}>2 MetroTech Center</Text>
          </LinearGradient>
        </View>

        <LinearGradient
          colors={['transparent', colors.backgroundOverlay, colors.background]}
          style={[styles.bottomSheet]}
        >
          <View style={styles.bottomSheetContent}>
            <RecommendationCard
              title="Fulton Jazz Lounge"
              description="Live jazz tonight at 8 PM"
              image="https://via.placeholder.com/96"
              walkTime="7 min walk"
              popularity="Medium"
            />
          </View>
        </LinearGradient>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  map: { ...StyleSheet.absoluteFillObject },
  overlayContainer: { ...StyleSheet.absoluteFillObject, pointerEvents: 'box-none' },

  addressBadge: {
    position: 'absolute',
    left: width * 0.2,
    borderRadius: borderRadius.md,
    overflow: 'hidden',
  },
  addressBadgeGradient: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: spacing['3xl'],
    paddingVertical: spacing['2xl'],
    gap: spacing.md,
  },
  addressIcon: { fontSize: 16 },
  addressText: {
    fontSize: typography.fontSize.base,
    color: colors.textPrimary,
  },

  bottomSheet: {
    position: 'absolute',
    bottom: 0,
    paddingTop: spacing['3xl'],
    paddingHorizontal: spacing['2xl'],
    width: '100%',
  },
  bottomSheetContent: {
    backgroundColor: colors.glassBackground,
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    borderColor: colors.border,
    padding: spacing['2xl'],
  },
});
