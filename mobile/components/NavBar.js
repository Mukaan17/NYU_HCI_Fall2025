import React, { useEffect, useRef } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, Dimensions, Platform } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { BlurView } from 'expo-blur';
import * as Haptics from 'expo-haptics';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSpring,
  withTiming,
  withDelay,
  withSequence,
  FadeInUp,
} from 'react-native-reanimated';
import { colors, typography, spacing, borderRadius, shadows } from '../constants/theme';

const { width } = Dimensions.get('window');

const AnimatedTouchable = Animated.createAnimatedComponent(TouchableOpacity);
const AnimatedView = Animated.createAnimatedComponent(View);
const AnimatedText = Animated.createAnimatedComponent(Text);

export default function NavBar({ activeTab, onTabPress, style }) {
  const tabs = [
    { id: 'dashboard', label: 'Home' },
    { id: 'chat', label: 'Chat' },
    { id: 'map', label: 'Map' },
    { id: 'safety', label: 'Safety' },
  ];

  const containerScale = useSharedValue(1);
  const containerOpacity = useSharedValue(1);
  
  // Sliding highlight animation with liquid glass morphing
  const highlightPosition = useSharedValue(0);
  const highlightWidth = useSharedValue(0);
  const highlightScale = useSharedValue(1);
  const highlightBorderRadius = useSharedValue(borderRadius.full);
  const highlightRotation = useSharedValue(0);
  const blobOffsetX = useSharedValue(0);
  const blobOffsetY = useSharedValue(0);
  const tabLayouts = useRef({});
  const hasAnimated = useRef(false);

  useEffect(() => {
    // Entrance animation only on first mount
    if (!hasAnimated.current) {
      containerScale.value = 0.95;
      containerOpacity.value = 0;
      containerScale.value = withDelay(200, withSpring(1, { damping: 15, stiffness: 150 }));
      containerOpacity.value = withDelay(200, withTiming(1, { duration: 300 }));
      hasAnimated.current = true;
    }
    
    // Initialize highlight position on mount
    const activeIndex = tabs.findIndex(tab => tab.id === activeTab);
    if (activeIndex !== -1) {
      const containerPadding = spacing.md * 2;
      const totalGap = spacing.md * (tabs.length - 1);
      const availableWidth = width - containerPadding;
      const tabWidth = (availableWidth - totalGap) / tabs.length;
      const initialPosition = activeIndex * (tabWidth + spacing.md) + spacing.md;
      
      // Set initial position without animation on mount
      if (highlightPosition.value === 0 && highlightWidth.value === 0) {
        highlightPosition.value = initialPosition;
        highlightWidth.value = tabWidth;
      }
    }
  }, []);

  // Calculate and animate highlight position when activeTab changes with liquid morphing
  useEffect(() => {
    const animateHighlight = () => {
      const activeTabLayout = tabLayouts.current[activeTab];
      if (activeTabLayout && activeTabLayout.x !== undefined && activeTabLayout.width !== undefined) {
        // Liquid glass morphing animations
        highlightPosition.value = withSpring(activeTabLayout.x, {
          damping: 15,
          stiffness: 200,
          mass: 0.8,
        });
        highlightWidth.value = withSpring(activeTabLayout.width, {
          damping: 15,
          stiffness: 200,
          mass: 0.8,
        });
        
        // Morphing effects - scale with sequence for bounce effect
        highlightScale.value = withSequence(
          withSpring(1.08, {
            damping: 12,
            stiffness: 150,
            mass: 0.6,
          }),
          withSpring(1, {
            damping: 15,
            stiffness: 200,
            mass: 0.8,
          })
        );
        
        // Dynamic border radius morphing for blob effect
        highlightBorderRadius.value = withSequence(
          withSpring(borderRadius.full * 0.6, {
            damping: 10,
            stiffness: 100,
            mass: 0.5,
          }),
          withSpring(borderRadius.full, {
            damping: 15,
            stiffness: 200,
            mass: 0.8,
          })
        );
        
        // Subtle rotation for fluid effect
        const rotationAmount = (Math.random() - 0.5) * 3;
        highlightRotation.value = withSequence(
          withSpring(rotationAmount, {
            damping: 20,
            stiffness: 100,
            mass: 0.5,
          }),
          withSpring(0, {
            damping: 20,
            stiffness: 200,
            mass: 0.8,
          })
        );
        
        // Blob offset for organic movement
        const offsetX = (Math.random() - 0.5) * 6;
        const offsetY = (Math.random() - 0.5) * 3;
        blobOffsetX.value = withSequence(
          withSpring(offsetX, {
            damping: 15,
            stiffness: 120,
            mass: 0.6,
          }),
          withSpring(0, {
            damping: 15,
            stiffness: 200,
            mass: 0.8,
          })
        );
        
        blobOffsetY.value = withSequence(
          withSpring(offsetY, {
            damping: 15,
            stiffness: 120,
            mass: 0.6,
          }),
          withSpring(0, {
            damping: 15,
            stiffness: 200,
            mass: 0.8,
          })
        );
      } else {
        // Fallback calculation if layout not measured yet
        const activeIndex = tabs.findIndex(tab => tab.id === activeTab);
        if (activeIndex !== -1) {
          const containerPadding = spacing.md * 2;
          const totalGap = spacing.md * (tabs.length - 1);
          const availableWidth = width - containerPadding;
          const tabWidth = (availableWidth - totalGap) / tabs.length;
          const newPosition = activeIndex * (tabWidth + spacing.md) + spacing.md;
          
          highlightPosition.value = withSpring(newPosition, {
            damping: 15,
            stiffness: 200,
            mass: 0.8,
          });
          highlightWidth.value = withSpring(tabWidth, {
            damping: 15,
            stiffness: 200,
            mass: 0.8,
          });
        }
      }
    };

    // Use requestAnimationFrame to ensure layout is ready
    requestAnimationFrame(() => {
      animateHighlight();
    });
  }, [activeTab]);

  const containerAnimatedStyle = useAnimatedStyle(() => {
    return {
      transform: [{ scale: containerScale.value }],
      opacity: containerOpacity.value,
    };
  });

  const highlightAnimatedStyle = useAnimatedStyle(() => {
    return {
      transform: [
        { translateX: highlightPosition.value + blobOffsetX.value },
        { translateY: blobOffsetY.value },
        { scale: highlightScale.value },
        { rotate: `${highlightRotation.value}deg` },
      ],
      width: highlightWidth.value,
      borderRadius: highlightBorderRadius.value,
    };
  });
  

  const handleTabPress = (tabId) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    onTabPress(tabId);
  };

  return (
    <AnimatedView
      entering={FadeInUp.delay(300).springify()}
      style={[styles.wrapper, style, containerAnimatedStyle]}
    >
      <BlurView
        intensity={Platform.OS === 'ios' ? 80 : 60}
        tint="dark"
        style={styles.blurContainer}
      >
        <View style={styles.glassOverlay} />
      </BlurView>
      <View style={[styles.container, style]}>
        {/* Main sliding highlight background with liquid glass morphing */}
        <Animated.View style={[styles.slidingHighlight, highlightAnimatedStyle]}>
          {/* Glass effect without gradient to avoid visible edges */}
          <View style={styles.highlightGlass}>
            {/* Full-size glass bubble effect */}
            <View style={styles.glassBubble} />
            {/* Inner glow layer covering entire highlight */}
            <View style={styles.innerGlow} />
          </View>
        </Animated.View>

        {tabs.map((tab, index) => {
          const isActive = activeTab === tab.id;
          const scale = useSharedValue(1);
          const opacity = useSharedValue(isActive ? 1 : 0.7);
          const prevActiveRef = useRef(isActive);

          useEffect(() => {
            // Only animate if the active state actually changed
            if (prevActiveRef.current !== isActive) {
              opacity.value = withTiming(isActive ? 1 : 0.7, { duration: 200 });
              prevActiveRef.current = isActive;
            } else {
              // Set initial value without animation on first render
              opacity.value = isActive ? 1 : 0.7;
            }
          }, [isActive]);

          // Only apply scale animation to button, not text
          const buttonAnimatedStyle = useAnimatedStyle(() => {
            return {
              transform: [{ scale: scale.value }],
            };
          });
          
          // Text style - static, only opacity changes
          const textAnimatedStyle = useAnimatedStyle(() => {
            return {
              opacity: opacity.value,
            };
          });

          const handlePressIn = () => {
            scale.value = withSpring(0.95, { damping: 12, stiffness: 400 });
            Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
          };

          const handlePressOut = () => {
            scale.value = withSpring(1, { damping: 12, stiffness: 400 });
          };

          return (
            <AnimatedTouchable
              key={tab.id}
              onPress={() => handleTabPress(tab.id)}
              onPressIn={handlePressIn}
              onPressOut={handlePressOut}
              style={[styles.tabButton, buttonAnimatedStyle]}
              activeOpacity={0.8}
              onLayout={(event) => {
                const { x, width } = event.nativeEvent.layout;
                // Only update if layout actually changed
                const previousLayout = tabLayouts.current[tab.id];
                if (!previousLayout || previousLayout.x !== x || previousLayout.width !== width) {
                  tabLayouts.current[tab.id] = { x, width };
                  // If this tab is active, update highlight position immediately
                  // This ensures the highlight moves even if useEffect hasn't fired yet
                  if (tab.id === activeTab) {
                    highlightPosition.value = withSpring(x, {
                      damping: 20,
                      stiffness: 300,
                      mass: 0.5,
                    });
                    highlightWidth.value = withSpring(width, {
                      damping: 20,
                      stiffness: 300,
                      mass: 0.5,
                    });
                  }
                }
              }}
            >
              <View style={styles.button}>
                <AnimatedText
                  style={[
                    styles.buttonText,
                    isActive && styles.activeButtonText,
                    !isActive && styles.inactiveButtonText,
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
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.18)',
    // Ensure wrapper clips all child content
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 8 },
        shadowOpacity: 0.3,
        shadowRadius: 20,
      },
      android: {
        elevation: 8,
      },
    }),
  },
  blurContainer: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    borderRadius: borderRadius.full,
  },
  glassOverlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: 'rgba(28, 37, 65, 0.4)',
    borderRadius: borderRadius.full,
  },
  container: {
    flexDirection: 'row',
    backgroundColor: 'transparent',
    paddingHorizontal: spacing.md, // 8pt horizontal padding inside container
    paddingVertical: spacing.sm, // 6pt vertical padding
    gap: spacing.md, // 8pt gap between tabs
    alignItems: 'center',
    justifyContent: 'space-between',
    width: '100%',
    position: 'relative',
    zIndex: 1,
    overflow: 'hidden', // Prevent overflow of glass effects
  },
  slidingHighlight: {
    position: 'absolute',
    height: '100%',
    borderRadius: borderRadius.full,
    overflow: 'hidden',
    zIndex: 0,
    borderWidth: 0, // Ensure no border on highlight
    // Remove any shadow that might create outline
    ...Platform.select({
      ios: {
        shadowColor: 'transparent',
        shadowOffset: { width: 0, height: 0 },
        shadowOpacity: 0,
        shadowRadius: 0,
      },
      android: {
        elevation: 0,
      },
    }),
  },
  blobLayer: {
    zIndex: 0,
  },
  highlightGlass: {
    width: '100%',
    height: '100%',
    borderRadius: borderRadius.full,
    overflow: 'hidden', // Ensure glass doesn't overflow
    borderWidth: 0, // Ensure no border
    backgroundColor: 'rgba(108, 99, 255, 0.35)', // More visible purple tint
    // Soft edge to prevent visible outline
    ...Platform.select({
      ios: {
        shadowColor: 'transparent',
        shadowOffset: { width: 0, height: 0 },
        shadowOpacity: 0,
        shadowRadius: 0,
      },
    }),
  },
  highlightBlur: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    borderRadius: borderRadius.full,
    overflow: 'hidden', // Prevent blur edge artifacts
  },
  glassBubble: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    borderRadius: borderRadius.full,
    backgroundColor: 'rgba(255, 255, 255, 0.08)',
    opacity: 0.25,
    overflow: 'hidden', // Prevent overflow
    borderWidth: 0, // Ensure no border
  },
  innerGlow: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    borderRadius: borderRadius.full,
    backgroundColor: 'rgba(255, 255, 255, 0.04)',
    opacity: 0.5,
    overflow: 'hidden', // Prevent overflow
    borderWidth: 0, // Ensure no border
  },
  tabButton: {
    flex: 1,
    minHeight: 44, // Apple HIG minimum touch target height
    zIndex: 1,
  },
  button: {
    paddingVertical: spacing.lg, // 10pt vertical padding (total ~44pt with text)
    paddingHorizontal: spacing.md, // 8pt horizontal padding
    borderRadius: borderRadius.full,
    alignItems: 'center',
    justifyContent: 'center',
    minHeight: 44, // Apple HIG minimum touch target size
    backgroundColor: 'transparent',
  },
  buttonText: {
    fontSize: typography.fontSize.sm,
    fontWeight: typography.fontWeight.semiBold,
    lineHeight: typography.lineHeight.normal,
  },
  activeButtonText: {
    color: colors.textPrimary,
  },
  inactiveButtonText: {
    color: colors.textSecondary,
  },
});

