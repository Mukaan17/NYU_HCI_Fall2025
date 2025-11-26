// app/_layout.tsx
import { Slot, router, useSegments } from "expo-router";
import { useEffect } from "react";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { SafeAreaProvider } from "react-native-safe-area-context";
import { StatusBar } from "expo-status-bar";
import { PlaceProvider } from "../context/PlaceContext";
import { ChatProvider } from "../context/ChatContext";

export default function RootLayout() {
  const segments = useSegments();

  useEffect(() => {
    const checkOnboarding = async () => {
      const hasSeenWelcome = await AsyncStorage.getItem("hasSeenWelcome");
      const hasLoggedIn = await AsyncStorage.getItem("hasLoggedIn");
      const hasCompletedOnboardingSurvey = await AsyncStorage.getItem("hasCompletedOnboardingSurvey");
      const hasCompletedPermissions = await AsyncStorage.getItem("hasCompletedPermissions");

      if (!hasSeenWelcome) {
        router.replace("/welcome");
      } else if (!hasLoggedIn) {
        router.replace("/(onboarding)/login");
      } else if (!hasCompletedOnboardingSurvey) {
        router.replace("/(onboarding)/survey");
      } else if (!hasCompletedPermissions) {
        router.replace("/permissions");
      }
    };

    checkOnboarding();
  }, [segments]);

  return (
    <SafeAreaProvider>
      <PlaceProvider>
        <ChatProvider>
          <StatusBar style="light" translucent backgroundColor="transparent" />
          <Slot />
        </ChatProvider>
      </PlaceProvider>
    </SafeAreaProvider>
  );
}
