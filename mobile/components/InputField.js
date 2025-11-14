import React, { useState } from 'react';
import { View, Text, TextInput, TouchableOpacity, StyleSheet, Platform } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { BlurView } from 'expo-blur';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSpring,
} from 'react-native-reanimated';
import * as Haptics from 'expo-haptics';
import { colors, typography, borderRadius, spacing, shadows } from '../constants/theme';

const AnimatedTouchable = Animated.createAnimatedComponent(TouchableOpacity);

export default function InputField({ placeholder, onSend, style }) {
  const [text, setText] = useState('');
  const sendButtonScale = useSharedValue(1);

  const handleSend = () => {
    if (text.trim() && onSend) {
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
      onSend(text.trim());
      setText('');
    }
  };

  const handlePressIn = () => {
    sendButtonScale.value = withSpring(0.9);
  };

  const handlePressOut = () => {
    sendButtonScale.value = withSpring(1);
  };

  const animatedButtonStyle = useAnimatedStyle(() => {
    return {
      transform: [{ scale: sendButtonScale.value }],
    };
  });

  return (
    <View style={[styles.container, style]}>
      <View style={styles.inputWrapper}>
        <BlurView
          intensity={Platform.OS === 'ios' ? 60 : 40}
          tint="dark"
          style={styles.blurContainer}
        >
          <View style={styles.glassOverlay} />
        </BlurView>
        <View style={styles.inputContainer}>
        <TextInput
          style={styles.input}
          placeholder={placeholder}
          placeholderTextColor={colors.textSecondary}
          value={text}
          onChangeText={setText}
          multiline={false}
          returnKeyType="send"
          onSubmitEditing={handleSend}
          blurOnSubmit={false}
          enablesReturnKeyAutomatically={true}
        />
        <AnimatedTouchable
          onPress={handleSend}
          onPressIn={handlePressIn}
          onPressOut={handlePressOut}
          style={[styles.sendButton, animatedButtonStyle]}
          disabled={!text.trim()}
          activeOpacity={0.8}
        >
          <LinearGradient
            colors={text.trim() ? [colors.gradientStart, colors.gradientEnd] : [colors.border, colors.border]}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 1 }}
            style={styles.sendButtonGradient}
          >
            <Text style={styles.sendIcon}>→</Text>
          </LinearGradient>
        </AnimatedTouchable>
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: spacing['2xl'], // 16pt horizontal padding
    paddingTop: spacing['2xl'], // 16pt top padding
    paddingBottom: spacing.md, // 8pt bottom padding
  },
  inputWrapper: {
    borderRadius: borderRadius.md,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.15)',
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.2,
        shadowRadius: 12,
      },
      android: {
        elevation: 4,
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
    backgroundColor: 'rgba(28, 37, 65, 0.5)',
  },
  inputContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'transparent',
    paddingHorizontal: spacing['2xl'], // 16pt - Apple standard padding
    paddingVertical: spacing.md, // 8pt vertical padding
    minHeight: 60, // Adjusted for better proportions
    gap: spacing['2xl'], // 16pt gap between input and button
    position: 'relative',
    zIndex: 1,
  },
  input: {
    flex: 1,
    fontSize: typography.fontSize.lg,
    fontWeight: typography.fontWeight.regular,
    color: colors.textPrimary,
    minHeight: 24,
  },
  sendButton: {
    width: 44, // Apple HIG minimum touch target
    height: 44, // Apple HIG minimum touch target
    borderRadius: borderRadius.md,
    overflow: 'hidden',
    ...shadows.primary,
  },
  sendButtonGradient: {
    width: '100%',
    height: '100%',
    justifyContent: 'center',
    alignItems: 'center',
  },
  sendIcon: {
    fontSize: 20,
    color: colors.textPrimary,
    fontWeight: 'bold',
  },
});

