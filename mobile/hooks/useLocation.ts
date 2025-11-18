import { useState, useEffect } from "react";
import * as Location from "expo-location";

export type UseLocationResult = {
  location: {
    latitude: number;
    longitude: number;
  } | null;
  loading: boolean;
  error: string | null;
};

/**
 * Custom hook to track user's live location
 * @returns {Object} { location, loading, error }
 */
export default function useLocation(): UseLocationResult {
  const [location, setLocation] = useState<{
    latitude: number;
    longitude: number;
  } | null>(null);

  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let locationSubscription: Location.LocationSubscription | null = null;

    const startLocationTracking = async () => {
      try {
        const { status } =
          await Location.requestForegroundPermissionsAsync();

        if (status !== "granted") {
          setError("Location permission not granted");
          setLoading(false);
          return;
        }

        // Initial location
        const initial = await Location.getCurrentPositionAsync({
          accuracy: Location.Accuracy.Balanced,
        });

        setLocation({
          latitude: initial.coords.latitude,
          longitude: initial.coords.longitude,
        });

        setLoading(false);

        // Live tracking
        locationSubscription = await Location.watchPositionAsync(
          {
            accuracy: Location.Accuracy.Balanced,
            timeInterval: 5000,
            distanceInterval: 10,
          },
          (update) => {
            setLocation({
              latitude: update.coords.latitude,
              longitude: update.coords.longitude,
            });
          }
        );
      } catch (err: any) {
        console.error("Location error:", err);
        setError(err.message);
        setLoading(false);
      }
    };

    startLocationTracking();

    return () => {
      if (locationSubscription) {
        locationSubscription.remove();
      }
    };
  }, []);

  return { location, loading, error };
}
