// app/_layout.tsx
import { Slot } from "expo-router";
import { SafeAreaProvider } from "react-native-safe-area-context";
import { StatusBar } from "expo-status-bar";
import { PlaceProvider } from "../context/PlaceContext";
import { ChatProvider } from "../context/ChatContext";

export default function RootLayout() {
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
