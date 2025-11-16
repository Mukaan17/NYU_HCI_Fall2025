import React from 'react';
import { View, Text, Image, StyleSheet, Dimensions, Platform } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { BlurView } from 'expo-blur';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSpring,
} from 'react-native-reanimated';
import * as Haptics from 'expo-haptics';
import { colors, typography, borderRadius, spacing } from '../constants/theme';

const { width } = Dimensions.get('window');
const AnimatedTouchable = Animated.createAnimatedComponent(View);

export default function RecommendationCard({
  title,
  description,
  image,
  walkTime,
  popularity,
  onPress = () => {},
  style = {},
}) {
  const scale = useSharedValue(1);
  const opacity = useSharedValue(1);

  const handlePressIn = () => {
    scale.value = withSpring(0.98);
    opacity.value = withSpring(0.9);
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
  };

  const handlePressOut = () => {
    scale.value = withSpring(1);
    opacity.value = withSpring(1);
  };

  const handlePress = () => {
    if (onPress) {
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
      onPress();
    }
  };

  const animatedStyle = useAnimatedStyle(() => {
    return {
      transform: [{ scale: scale.value }],
      opacity: opacity.value,
    };
  });

  const CardWrapper = onPress ? AnimatedTouchable : View;
  const wrapperProps = onPress
    ? {
        onTouchStart: handlePressIn,
        onTouchEnd: handlePressOut,
        onPress: handlePress,
        activeOpacity: 0.9,
      }
    : {};

  return (
    <Animated.View style={[styles.wrapper, animatedStyle]}>
      <CardWrapper {...wrapperProps}>
        <View style={[styles.container, style]}>
          <BlurView
            intensity={Platform.OS === 'ios' ? 40 : 30}
            tint="dark"
            style={styles.blurContainer}
          >
            <View style={styles.glassOverlay} />
          </BlurView>
          <LinearGradient
            colors={['rgba(28, 37, 65, 0.6)', 'rgba(21, 30, 56, 0.7)']}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 1 }}
            style={styles.gradientOverlay}
          />
          <View style={styles.border} />
          <View style={styles.content}>
            {image && (
              <View style={styles.imageContainer}>
                <Image 
                  source={{ uri: image }} 
                  style={styles.image}
                  resizeMode="cover"
                />
                {walkTime && (
                  <View style={styles.walkTimeBadge}>
                    <Text style={styles.walkTimeText}>{walkTime}</Text>
                  </View>
                )}
              </View>
            )}
            <View style={styles.textContainer}>
              <Text style={styles.title}>{title}</Text>
              {description && <Text style={styles.description}>{description}</Text>}
              <View style={styles.badges}>
                {walkTime && !image && (
                  <View style={styles.walkTimeBadgeInline}>
                    <Text style={styles.walkTimeText}>{walkTime}</Text>
                  </View>
                )}
                {popularity && (
                  <View style={styles.popularityBadge}>
                    <Text style={styles.popularityText}>{popularity}</Text>
                  </View>
                )}
              </View>
            </View>
          </View>
        </View>
      </CardWrapper>
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  wrapper: {
    marginBottom: spacing['2xl'], // 16pt margin between cards (Apple standard)
  },
  container: {
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.12)',
    overflow: 'hidden',
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.25,
        shadowRadius: 12,
      },
      android: {
        elevation: 6,
      },
    }),
  },
  blurContainer: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
  },
  glassOverlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: 'rgba(28, 37, 65, 0.3)',
  },
  gradientOverlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
  },
  border: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    borderRadius: borderRadius.lg,
    backgroundColor: 'transparent',
  },
  content: {
    flexDirection: 'row',
    padding: spacing['2xl'],
    borderRadius: borderRadius.lg,
    position: 'relative',
    zIndex: 1,
  },
  imageContainer: {
    width: width * 0.24,
    height: width * 0.24,
    maxWidth: 96,
    maxHeight: 96,
    minWidth: 80,
    minHeight: 80,
    borderRadius: borderRadius.md,
    marginRight: spacing['2xl'],
    position: 'relative',
  },
  image: {
    width: '100%',
    height: '100%',
    borderRadius: borderRadius.md,
    backgroundColor: colors.backgroundCardDark,
  },
  textContainer: {
    flex: 1,
    justifyContent: 'space-between',
  },
  title: {
    fontSize: typography.fontSize['2xl'],
    fontWeight: typography.fontWeight.semiBold,
    color: colors.textPrimary,
    lineHeight: typography.lineHeight['2xl'],
    marginBottom: spacing.sm,
  },
  description: {
    fontSize: typography.fontSize.lg,
    fontWeight: typography.fontWeight.regular,
    color: colors.textSecondary,
    lineHeight: typography.lineHeight.loose,
    marginBottom: spacing.sm,
  },
  badges: {
    flexDirection: 'row',
    gap: spacing['2xl'],
    alignItems: 'center',
  },
  walkTimeBadge: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    backgroundColor: colors.accentPurpleText,
    borderRadius: borderRadius.full,
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.sm,
  },
  walkTimeBadgeInline: {
    backgroundColor: colors.accentPurpleText,
    borderRadius: borderRadius.full,
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.sm,
    alignSelf: 'flex-start',
  },
  walkTimeText: {
    fontSize: typography.fontSize.xs,
    fontWeight: typography.fontWeight.medium,
    color: colors.textAccent,
  },
  popularityBadge: {
    backgroundColor: colors.accentBlue,
    borderRadius: borderRadius.full,
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.sm,
    alignSelf: 'flex-start',
  },
  popularityText: {
    fontSize: typography.fontSize.xs,
    fontWeight: typography.fontWeight.medium,
    color: colors.textBlue,
  },
});

