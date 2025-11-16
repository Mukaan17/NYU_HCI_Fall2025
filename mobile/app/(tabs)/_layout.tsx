// app/(tabs)/_layout.tsx
import { View } from "react-native";
import { Slot, usePathname, router } from "expo-router";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import NavBar from "../../components/NavBar";
import { spacing } from "../../constants/theme";

export default function TabsLayout() {
  const insets = useSafeAreaInsets();
  const pathname = usePathname();

  // Determine current active tab
  const activeTab: "dashboard" | "chat" | "map" | "safety" = 
    pathname.includes("dashboard") ? "dashboard" :
    pathname.includes("chat") ? "chat" :
    pathname.includes("map") ? "map" :
    "safety";

  // Type the tabId properly
  const handleTabPress = (tabId: string) => {
    router.replace(`/(tabs)/${tabId}`);
  };

  return (
    <View style={{ flex: 1 }}>
      <Slot />

      <View
        style={{
          position: "absolute",
          bottom: 0,
          left: 0,
          right: 0,
          paddingBottom:
            Math.max(insets.bottom, spacing["2xl"]) + spacing["2xl"],
          paddingHorizontal: spacing["2xl"],
        }}
      >
        <NavBar activeTab={activeTab} onTabPress={handleTabPress} />
      </View>
    </View>
  );
}
