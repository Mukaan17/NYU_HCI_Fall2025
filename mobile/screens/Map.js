import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Dimensions,
} from 'react-native';
import MapView, { Marker } from 'react-native-maps';
import { LinearGradient } from 'expo-linear-gradient';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import * as Location from 'expo-location';
import RecommendationCard from '../components/RecommendationCard';
import { colors, typography, spacing, borderRadius } from '../constants/theme';

const { width, height } = Dimensions.get('window');

export default function Map({ navigation }) {
  const insets = useSafeAreaInsets();
  const [location, setLocation] = useState(null);
  const [region, setRegion] = useState({
    latitude: 40.6934,
    longitude: -73.9857,
    latitudeDelta: 0.01,
    longitudeDelta: 0.01,
  });

  useEffect(() => {
    (async () => {
      try {
        const { status } = await Location.requestForegroundPermissionsAsync();
        if (status === 'granted') {
          const loc = await Location.getCurrentPositionAsync({});
          if (loc && loc.coords) {
            setLocation(loc.coords);
            setRegion({
              latitude: loc.coords.latitude,
              longitude: loc.coords.longitude,
              latitudeDelta: 0.01,
              longitudeDelta: 0.01,
            });
          }
        }
      } catch (error) {
        console.error('Error getting location:', error);
        // Use default location (Downtown Brooklyn)
      }
    })();
  }, []);

  const markers = [
    {
      id: 1,
      coordinate: {
        latitude: 40.6934,
        longitude: -73.9857,
      },
      title: 'Fulton Jazz Lounge',
    },
    {
      id: 2,
      coordinate: {
        latitude: 40.6920,
        longitude: -73.9840,
      },
      title: 'Brooklyn Rooftop',
    },
    {
      id: 3,
      coordinate: {
        latitude: 40.6940,
        longitude: -73.9860,
      },
      title: 'Butler Café',
    },
  ];


  return (
    <View style={styles.container}>
      <MapView
        style={styles.map}
        region={region}
        onRegionChangeComplete={setRegion}
        showsUserLocation={true}
        showsMyLocationButton={false}
      >
          {markers.map((marker) => (
            <Marker
              key={marker.id}
              coordinate={marker.coordinate}
              title={marker.title}
            />
          ))}
      </MapView>

      <View style={styles.overlayContainer}>
        {/* Current Location Indicator */}
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

        {/* Address Badge */}
        <View style={[styles.addressBadge, { top: insets.top + spacing['2xl'] }]}>
          <LinearGradient
            colors={[colors.glassBackgroundLight, colors.glassBackgroundDarkLight]}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 0 }}
            style={styles.addressBadgeGradient}
          >
            <Text style={styles.addressIcon}>📍</Text>
            <Text style={styles.addressText}>2 MetroTech Center</Text>
          </LinearGradient>
        </View>

        {/* Bottom Sheet with Recommendation */}
        <LinearGradient
          colors={['transparent', colors.backgroundOverlay, colors.background]}
          locations={[0, 0.5, 1]}
          style={[styles.bottomSheet, { paddingBottom: Math.max(insets.bottom, spacing['2xl']) + 90 }]}
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
  container: {
    flex: 1,
  },
  map: {
    ...StyleSheet.absoluteFillObject,
    width: '100%',
    height: '100%',
  },
  overlayContainer: {
    ...StyleSheet.absoluteFillObject,
    pointerEvents: 'box-none',
  },
  locationIndicator: {
    position: 'absolute',
    left: width / 2 - 10,
    top: height / 2 - 10,
    width: 20,
    height: 20,
    alignItems: 'center',
    justifyContent: 'center',
  },
  locationDot: {
    width: 20,
    height: 20,
    borderRadius: 10,
    borderWidth: 4,
    borderColor: colors.textPrimary,
    overflow: 'hidden',
  },
  locationGradient: {
    width: '100%',
    height: '100%',
  },
  locationRing: {
    position: 'absolute',
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
    position: 'absolute',
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: colors.gradientStart,
    opacity: 0.371,
    top: -30,
    left: -30,
  },
  addressBadge: {
    position: 'absolute',
    left: width * 0.25,
    maxWidth: width * 0.7,
    borderRadius: borderRadius.md,
    overflow: 'hidden',
  },
  addressBadgeGradient: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: spacing['3xl'],
    paddingVertical: spacing['2xl'],
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
  bottomSheet: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    paddingTop: spacing['3xl'], // 20pt top padding
    paddingHorizontal: spacing['2xl'], // 16pt horizontal padding
    paddingBottom: 100, // Space for nav bar (will be adjusted dynamically)
  },
  bottomSheetContent: {
    backgroundColor: colors.glassBackground,
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    borderColor: colors.border,
    padding: spacing.xs,
  },
});

