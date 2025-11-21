import React from "react";
import {
  View,
  Text,
  Pressable,
  StyleSheet,
  Platform,
} from "react-native";
import * as Haptics from "expo-haptics";
import { SymbolView } from "expo-symbols";
import { BlurView } from "expo-blur";

interface NavBarProps {
  activeTab: string;
  onTabPress: (id: string) => void;
  style?: any;
}

const tabs = [
  { id: "dashboard", label: "Home", sfSymbol: "house.fill" },
  { id: "chat", label: "Chat", sfSymbol: "message.fill" },
  { id: "map", label: "Map", sfSymbol: "map.fill" },
  { id: "safety", label: "Safety", sfSymbol: "shield.fill" },
];

export default function NavBar({ activeTab, onTabPress, style }: NavBarProps) {
  const handleTabPress = (tabId: string) => {
    if (Platform.OS === "ios") {
      Haptics.selectionAsync();
    }
    onTabPress(tabId);
  };

  return (
    <View style={[styles.wrapper, style]}>
      {/* Top separator line - native iOS tab bar style */}
      <View style={styles.topSeparator} />
      
      {/* Native iOS tab bar blur background */}
      <BlurView
        intensity={100}
        tint="systemChromeMaterialDark"
        style={styles.background}
      >
        <View style={styles.container}>
          {tabs.map((tab) => {
            const isActive = activeTab === tab.id;
            return (
              <Pressable
                key={tab.id}
                onPress={() => handleTabPress(tab.id)}
                style={styles.tabButton}
              >
                <View style={styles.buttonContent}>
                  {Platform.OS === "ios" ? (
                    <SymbolView
                      name={tab.sfSymbol}
                      size={25}
                      type="hierarchical"
                      tintColor={isActive ? "#007AFF" : "rgba(255, 255, 255, 0.4)"}
                      style={styles.icon}
                    />
                  ) : (
                    <Text style={[styles.iconFallback, !isActive && styles.iconInactive]}>
                      {tab.label.charAt(0)}
                    </Text>
                  )}
                  
                  <Text style={[
                    styles.buttonText,
                    isActive ? styles.textActive : styles.textInactive
                  ]}>
                    {tab.label}
                  </Text>
                </View>
              </Pressable>
            );
          })}
        </View>
      </BlurView>
    </View>
  );
}

const styles = StyleSheet.create({
  wrapper: {
    position: "relative",
    overflow: "hidden",
  },
  topSeparator: {
    position: "absolute",
    top: 0,
    left: 0,
    right: 0,
    height: 0.5,
    backgroundColor: "rgba(255, 255, 255, 0.1)",
    zIndex: 10,
  },
  background: {
    width: "100%",
    paddingTop: 8,
    paddingBottom: 8,
    height: 49,
  },
  container: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-around",
    height: "100%",
    paddingHorizontal: 8,
  },
  tabButton: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    paddingVertical: 6,
    paddingHorizontal: 4,
    minHeight: 49,
  },
  buttonContent: {
    alignItems: "center",
    justifyContent: "center",
    gap: 4,
  },
  icon: {
    width: 25,
    height: 25,
  },
  iconInactive: {
    opacity: 0.4,
  },
  iconFallback: {
    fontSize: 22,
    fontWeight: "500",
    color: "#FFFFFF",
    opacity: 0.4,
  },
  buttonText: {
    fontSize: 10,
    fontWeight: "600",
    letterSpacing: -0.24,
    fontFamily: Platform.select({
      ios: "System",
      android: "Roboto",
    }),
  },
  textActive: {
    color: "#007AFF",
  },
  textInactive: {
    color: "rgba(255, 255, 255, 0.4)",
  },
});
