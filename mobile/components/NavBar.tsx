import React, { useEffect, useRef } from "react";
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  Dimensions,
  Platform,
} from "react-native";
import { BlurView } from "expo-blur";
import * as Haptics from "expo-haptics";
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSpring,
  withTiming,
  withDelay,
  withSequence,
  FadeInUp,
} from "react-native-reanimated";
import SvgIcon from "./SvgIcon";
import {
  colors,
  typography,
  spacing,
  borderRadius,
  shadows,
} from "../constants/theme";

const { width } = Dimensions.get("window");

const AnimatedTouchable = Animated.createAnimatedComponent(TouchableOpacity);
const AnimatedView = Animated.createAnimatedComponent(View);
const AnimatedText = Animated.createAnimatedComponent(Text);

interface NavBarProps {
  activeTab: string;
  onTabPress: (id: string) => void;
  style?: any;
}

export default function NavBar({ activeTab, onTabPress, style }: NavBarProps) {
  const tabs = [
    { id: "dashboard", label: "Home", icon: "home" },
    { id: "chat", label: "Chat", icon: "chat" },
    { id: "map", label: "Map", icon: "map" },
    { id: "safety", label: "Safety", icon: "safety" },
  ];

  const containerScale = useSharedValue(1);
  const containerOpacity = useSharedValue(1);

  const highlightPosition = useSharedValue(0);
  const highlightWidth = useSharedValue(0);
  const highlightScale = useSharedValue(1);
  const highlightBorderRadius = useSharedValue(borderRadius.full);
  const highlightRotation = useSharedValue(0);
  const blobOffsetX = useSharedValue(0);
  const blobOffsetY = useSharedValue(0);

  const tabLayouts = useRef<Record<string, { x: number; width: number }>>({});
  const hasAnimated = useRef(false);

  // Entrance animation (unchanged)
  useEffect(() => {
    if (!hasAnimated.current) {
      containerScale.value = 0.95;
      containerOpacity.value = 0;

      containerScale.value = withDelay(
        200,
        withSpring(1, { damping: 15, stiffness: 150 })
      );

      containerOpacity.value = withDelay(
        200,
        withTiming(1, { duration: 300 })
      );

      hasAnimated.current = true;
    }

    const activeIndex = tabs.findIndex((tab) => tab.id === activeTab);
    if (activeIndex !== -1) {
      const containerPadding = spacing.md * 2;
      const totalGap = spacing.md * (tabs.length - 1);
      const availableWidth = width - containerPadding;
      const tabWidthValue = (availableWidth - totalGap) / tabs.length;
      const initialPosition =
        activeIndex * (tabWidthValue + spacing.md) + spacing.md;

      if (highlightPosition.value === 0 && highlightWidth.value === 0) {
        highlightPosition.value = initialPosition;
        highlightWidth.value = tabWidthValue;
      }
    }
  }, []);

  // Animate highlight (unchanged)
  useEffect(() => {
    const animateHighlight = () => {
      const activeLayout = tabLayouts.current[activeTab];

      if (activeLayout) {
        highlightPosition.value = withSpring(activeLayout.x, {
          damping: 15,
          stiffness: 200,
        });
        highlightWidth.value = withSpring(activeLayout.width, {
          damping: 15,
          stiffness: 200,
        });

        highlightScale.value = withSequence(withSpring(1.08), withSpring(1));

        highlightBorderRadius.value = withSequence(
          withSpring(borderRadius.full * 0.6),
          withSpring(borderRadius.full)
        );

        const rot = (Math.random() - 0.5) * 3;
        highlightRotation.value = withSequence(withSpring(rot), withSpring(0));

        const offX = (Math.random() - 0.5) * 6;
        const offY = (Math.random() - 0.5) * 3;
        blobOffsetX.value = withSequence(withSpring(offX), withSpring(0));
        blobOffsetY.value = withSequence(withSpring(offY), withSpring(0));
      }
    };

    requestAnimationFrame(() => animateHighlight());
  }, [activeTab]);

  const containerAnimatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: containerScale.value }],
    opacity: containerOpacity.value,
  }));

  const highlightAnimatedStyle = useAnimatedStyle(() => ({
    transform: [
      { translateX: highlightPosition.value + blobOffsetX.value },
      { translateY: blobOffsetY.value },
      { scale: highlightScale.value },
      { rotate: `${highlightRotation.value}deg` },
    ],
    width: highlightWidth.value,
    borderRadius: highlightBorderRadius.value,
  }));

  const handleTabPressInternal = (tabId: string) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    onTabPress(tabId);
  };

  return (
    <AnimatedView
      entering={FadeInUp.delay(300).springify()}
      style={[styles.wrapper, style, containerAnimatedStyle]}
    >
      <BlurView
        intensity={Platform.OS === "ios" ? 80 : 60}
        tint="dark"
        style={styles.blurContainer}
      >
        <View style={styles.glassOverlay} />
      </BlurView>

      <View style={styles.container}>
        {/* Highlight blob */}
        <Animated.View
          style={[styles.slidingHighlight, highlightAnimatedStyle]}
        >
          <View style={styles.highlightGlass}>
            <View style={styles.glassBubble} />
            <View style={styles.innerGlow} />
          </View>
        </Animated.View>

        {/* Tabs */}
        {tabs.map((tab) => {
          const isActive = activeTab === tab.id;
          const scale = useSharedValue(1);
          const opacity = useSharedValue(isActive ? 1 : 0.7);

          const buttonAnimatedStyle = useAnimatedStyle(() => ({
            transform: [{ scale: scale.value }],
          }));
          const textAnimatedStyle = useAnimatedStyle(() => ({
            opacity: opacity.value,
          }));

          return (
            <AnimatedTouchable
              key={tab.id}
              onPress={() => handleTabPressInternal(tab.id)}
              onPressIn={() =>
                (scale.value = withSpring(0.95, {
                  damping: 12,
                  stiffness: 400,
                }))
              }
              onPressOut={() =>
                (scale.value = withSpring(1, {
                  damping: 12,
                  stiffness: 400,
                }))
              }
              style={[styles.tabButton, buttonAnimatedStyle]}
              activeOpacity={0.8}
              onLayout={(e) => {
                const { x, width } = e.nativeEvent.layout;
                tabLayouts.current[tab.id] = { x, width };
              }}
            >
              <View style={styles.button}>
                <SvgIcon
                  name={tab.icon}
                  size={20}
                  color={isActive ? colors.textPrimary : colors.textSecondary}
                />

                <AnimatedText
                  style={[
                    styles.buttonText,
                    isActive
                      ? styles.activeButtonText
                      : styles.inactiveButtonText,
                    textAnimatedStyle,
                  ]}
                >
                  {tab.label}
                </AnimatedText>
              </View>
            </AnimatedTouchable>
          );
        })}
      </View>
    </AnimatedView>
  );
}

const styles = StyleSheet.create({
  wrapper: {
    borderRadius: borderRadius.full,
    overflow: "hidden",
    borderWidth: 1,
    borderColor: "rgba(255, 255, 255, 0.18)",
    ...Platform.select({
      ios: {
        shadowColor: "#000",
        shadowOffset: { width: 0, height: 8 },
        shadowOpacity: 0.3,
        shadowRadius: 20,
      },
      android: { elevation: 8 },
    }),
  },
  blurContainer: {
    ...StyleSheet.absoluteFillObject,
    borderRadius: borderRadius.full,
  },
  glassOverlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: "rgba(28, 37, 65, 0.4)",
  },
  container: {
    flexDirection: "row",
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.sm,
    gap: spacing.md,
    alignItems: "center",
    justifyContent: "space-between",
    width: "100%",
    position: "relative",
  },
  slidingHighlight: {
    position: "absolute",
    height: "100%",
    borderRadius: borderRadius.full,
    overflow: "hidden",
    zIndex: 0,
  },
  highlightGlass: {
    width: "100%",
    height: "100%",
    borderRadius: borderRadius.full,
    backgroundColor: "rgba(108, 99, 255, 0.35)",
  },
  glassBubble: {
    ...StyleSheet.absoluteFillObject,
    borderRadius: borderRadius.full,
    backgroundColor: "rgba(255, 255, 255, 0.08)",
    opacity: 0.25,
  },
  innerGlow: {
    ...StyleSheet.absoluteFillObject,
    borderRadius: borderRadius.full,
    backgroundColor: "rgba(255, 255, 255, 0.04)",
    opacity: 0.5,
  },
  tabButton: {
    flex: 1,
    minHeight: 44,
    zIndex: 1,
  },
  button: {
    paddingVertical: spacing.md,
    paddingHorizontal: spacing.md,
    borderRadius: borderRadius.full,
    alignItems: "center",
    justifyContent: "center",
    flexDirection: "column",
    gap: spacing.xs,
    minHeight: 44,
  },
  buttonText: {
    fontSize: typography.fontSize.sm,
    fontWeight: typography.fontWeight.semiBold,
  },
  activeButtonText: {
    color: colors.textPrimary,
  },
  inactiveButtonText: {
    color: colors.textSecondary,
  },
});
