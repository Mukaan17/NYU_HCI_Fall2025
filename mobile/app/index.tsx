// app/index.tsx
import { useEffect, useState } from "react";
import { View, ActivityIndicator } from "react-native";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { router } from "expo-router";
import { colors } from "../constants/theme";

export default function Index() {
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const check = async () => {
      // TEMPORARY: Clear AsyncStorage to reset onboarding (remove this after testing)
      await AsyncStorage.removeItem("hasSeenWelcome");
      await AsyncStorage.removeItem("hasCompletedPermissions");
      
      const hasSeenWelcome = await AsyncStorage.getItem("hasSeenWelcome");
      const hasCompletedPermissions = await AsyncStorage.getItem("hasCompletedPermissions");

      console.log("🔍 AsyncStorage Check:", { hasSeenWelcome, hasCompletedPermissions });

      if (!hasSeenWelcome) {
        console.log("📍 Navigating to /welcome");
        router.replace("/welcome");
      } else if (!hasCompletedPermissions) {
        console.log("📍 Navigating to /permissions");
        router.replace("/permissions");
      } else {
        console.log("📍 Navigating to /(tabs)/dashboard");
        router.replace("/(tabs)/dashboard");
      }

      setLoading(false);
    };

    check();
  }, []);

  if (loading) {
    return (
      <View style={{
        flex: 1,
        backgroundColor: colors.background,
        justifyContent: "center",
        alignItems: "center"
      }}>
        <ActivityIndicator size="large" color={"#6c63ff"} />
      </View>
    );
  }

  return null;
}
