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
      const hasSeenWelcome = await AsyncStorage.getItem("hasSeenWelcome");
      const hasCompletedPermissions = await AsyncStorage.getItem("hasCompletedPermissions");

      if (!hasSeenWelcome) {
        router.replace("/(onboarding)/welcome");
      } else if (!hasCompletedPermissions) {
        router.replace("/(onboarding)/permissions");
      } else {
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
