// app/(tabs)/_layout.tsx
import { NativeTabs, Icon, Label } from "expo-router/unstable-native-tabs";
import { LiquidGlassView, isLiquidGlassSupported } from "@callstack/liquid-glass";

export default function TabsLayout() {
  return (
    <NativeTabs
      tabBarBackground={() => {
        if (isLiquidGlassSupported) {
          return (
            <LiquidGlassView
              effect="regular"
              style={{ flex: 1 }}
              tintColor="rgba(28, 32, 48, 0.6)"
            />
          );
        }
        return null; // Falls back to system blur
      }}
    >
      <NativeTabs.Trigger name="dashboard">
        <Label>Home</Label>
        <Icon sf="house.fill" />
      </NativeTabs.Trigger>
      
      <NativeTabs.Trigger name="chat">
        <Label>Chat</Label>
        <Icon sf="message.fill" />
      </NativeTabs.Trigger>
      
      <NativeTabs.Trigger name="map">
        <Label>Map</Label>
        <Icon sf="map.fill" />
      </NativeTabs.Trigger>
      
      <NativeTabs.Trigger name="safety">
        <Label>Safety</Label>
        <Icon sf="shield.fill" />
      </NativeTabs.Trigger>
    </NativeTabs>
  );
}
