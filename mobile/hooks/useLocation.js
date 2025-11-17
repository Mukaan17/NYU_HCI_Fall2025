import { useState, useEffect } from 'react';
import * as Location from 'expo-location';

/**
 * Custom hook to track user's live location
 * @returns {Object} { location, loading, error }
 */
export default function useLocation() {
  const [location, setLocation] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let locationSubscription = null;

    const startLocationTracking = async () => {
      try {
        // Request permissions
        const { status } = await Location.requestForegroundPermissionsAsync();
        if (status !== 'granted') {
          setError('Location permission not granted');
          setLoading(false);
          return;
        }

        // Get initial location
        const initialLocation = await Location.getCurrentPositionAsync({
          accuracy: Location.Accuracy.Balanced,
        });
        setLocation(initialLocation.coords);
        setLoading(false);

        // Watch for location updates
        locationSubscription = await Location.watchPositionAsync(
          {
            accuracy: Location.Accuracy.Balanced,
            timeInterval: 5000, // Update every 5 seconds
            distanceInterval: 10, // Update every 10 meters
          },
          (newLocation) => {
            setLocation(newLocation.coords);
          }
        );
      } catch (err) {
        console.error('Error getting location:', err);
        setError(err.message);
        setLoading(false);
      }
    };

    startLocationTracking();

    // Cleanup subscription on unmount
    return () => {
      if (locationSubscription) {
        locationSubscription.remove();
      }
    };
  }, []);

  return { location, loading, error };
}

