// app/(tabs)/_layout.tsx
import { View } from "react-native";
import { Slot, usePathname, router } from "expo-router";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import NavBar from "../../components/NavBar";
import { spacing } from "../../constants/theme";
import { ChatProvider } from "../../context/ChatContext";

export default function TabsLayout() {
  const insets = useSafeAreaInsets();
  const pathname = usePathname();

  // Figure out which tab is active based on the current route
  let activeTab: "dashboard" | "chat" | "map" | "safety" | "settings";

  if (pathname === "/dashboard") activeTab = "dashboard";
  else if (pathname === "/chat") activeTab = "chat";
  else if (pathname === "/map") activeTab = "map";
  else if (pathname === "/safety") activeTab = "safety";
  else if (pathname === "/settings") activeTab = "settings";
  else activeTab = "dashboard";

  const handleTabPress = (id: string) => {
    router.replace(`/(tabs)/${id}`);
  };

  return (
    <ChatProvider>
      <View style={{ flex: 1 }}>
        {/* This is where (tabs)/chat, (tabs)/map, etc render */}
        <Slot />

        {/* Custom NavBar, anchored to bottom */}
        <View
          style={{
            position: "absolute",
            bottom: 0,
            left: 0,
            right: 0,
            paddingBottom: spacing["2xl"],
            paddingHorizontal: spacing["2xl"],
          }}
        >
          <NavBar activeTab={activeTab} onTabPress={handleTabPress} />
        </View>
      </View>
    </ChatProvider>
  );
}
