/**
 * @Author: Mukhil Sundararaj
 * @Date:   2025-11-14 11:50:47
 * @Last Modified by:   Mukhil Sundararaj
 * @Last Modified time: 2025-11-17 12:36:37
 */
import React, { useState, useRef, useEffect, useCallback } from 'react';
import { useFocusEffect } from '@react-navigation/native';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  KeyboardAvoidingView,
  Platform,
  Dimensions,
  RefreshControl,
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import Animated, { FadeInDown, FadeInUp } from 'react-native-reanimated';
import RecommendationCard from '../components/RecommendationCard';
import InputField from '../components/InputField';
import useLocation from '../hooks/useLocation';
import { colors, typography, spacing, borderRadius, shadows } from '../constants/theme';

const { width } = Dimensions.get('window');
const NAV_BAR_OFFSET = 50; // Approximate height of custom nav bar overlay + spacing

// API Configuration - Update with your Flask server IP
// For iOS Simulator: use 'localhost' or '127.0.0.1'
// For physical device: use your computer's local IP (e.g., '192.168.1.100')
// Note: Using port 5001 because 5000 is often used by AirPlay Receiver on macOS
const API_BASE_URL = __DEV__ ? 'http://localhost:5001' : 'https://your-production-url.com';
const USE_API = true; // Set to true to enable real API calls

export default function Chat({ navigation, route }) {
  const insets = useSafeAreaInsets();
  const scrollViewRef = useRef(null);
  const { location } = useLocation();
  const [refreshing, setRefreshing] = useState(false);
  const [isTyping, setIsTyping] = useState(false);
  const [messages, setMessages] = useState([
    {
      id: 0,
      role: 'ai',
      content: "Hey! 👋 I'm Violet, your AI concierge. I can help you find great spots nearby—food, cafés, events, and more. What are you looking for?",
      timestamp: new Date(),
      recommendations: [],
    },
  ]);
  const autoSentRef = useRef(false);

  useEffect(() => {
    // Only scroll to bottom on initial load or when user sends a message
    // Don't auto-scroll when AI responds to keep user's scroll position
    if (scrollViewRef.current && messages.length > 0) {
      const lastMessage = messages[messages.length - 1];
      // Only auto-scroll if it's the welcome message or a user message
      if (lastMessage.id === 0 || lastMessage.role === 'user') {
        setTimeout(() => {
          scrollViewRef.current?.scrollToEnd({ animated: true });
        }, 100);
      }
    }
  }, [messages]);

  const handleSend = useCallback(async (text) => {
    if (!text || !text.trim()) return;
    
    const userMessage = { id: Date.now(), role: 'user', content: text.trim(), timestamp: new Date() };
    setMessages((prev) => [...prev, userMessage]);
    setIsTyping(true);

    // Call API or simulate response
    try {
      if (USE_API) {
        // Prepare request body with message and location
        const requestBody = {
          message: text.trim(),
        };
        
        // Add location if available
        if (location) {
          requestBody.latitude = location.latitude;
          requestBody.longitude = location.longitude;
        }
        
        // Real API call to Flask backend
        const res = await fetch(`${API_BASE_URL}/api/chat`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(requestBody),
        });
        const data = await res.json();
        setIsTyping(false);
        
        // Format recommendations from API response
        let formattedRecs = [];
        if (data.recommendations && Array.isArray(data.recommendations) && data.recommendations.length > 0) {
          formattedRecs = data.recommendations.map((place, index) => {
            // Determine popularity based on rating
            let popularity = 'Low';
            if (place.rating) {
              if (place.rating >= 4.5) popularity = 'High';
              else if (place.rating >= 4.0) popularity = 'Medium';
            }
            
            // Format walk time - handle different API response formats
            let walkTime = 'N/A';
            if (place.walk_time) {
              walkTime = place.walk_time;
            } else if (place.distance) {
              walkTime = place.distance;
            } else if (typeof place.walk_time === 'string') {
              walkTime = place.walk_time;
            }
            
            const formattedRec = {
              id: Date.now() + index + 1000,
              title: place.name || 'Unknown Place',
              description: place.address || place.vicinity || 'Nearby location',
              image: null, // Google Places photos require additional API call
              walkTime: walkTime,
              popularity: popularity,
              rating: place.rating,
              openNow: place.open_now,
              mapsLink: place.maps_link,
            };
            
            console.log('Formatted recommendation:', formattedRec);
            return formattedRec;
          });
        }
        
        // Add AI message with recommendations attached
        const aiMessage = {
          id: Date.now() + 1,
          role: 'ai',
          content: data.reply || "Sorry, I couldn't process that request.",
          timestamp: new Date(),
          recommendations: formattedRecs,
        };
        console.log('AI Message with recommendations:', aiMessage.recommendations.length);
        setMessages((prev) => [...prev, aiMessage]);
      } else {
        // Simulated response for demo (no API)
        setTimeout(() => {
          setIsTyping(false);
          const aiMessage = {
            id: Date.now() + 1,
            role: 'ai',
            content: 'Here are some great options for you!',
            timestamp: new Date(),
            recommendations: [],
          };
          setMessages((prev) => [...prev, aiMessage]);
        }, 1500);
      }
    } catch (error) {
      console.error('Error sending message:', error);
      setIsTyping(false);
      const errorMessage = {
        id: Date.now() + 1,
        role: 'ai',
        content: 'Sorry, I encountered an error. Please try again.',
        timestamp: new Date(),
        recommendations: [],
      };
      setMessages((prev) => [...prev, errorMessage]);
    }
  }, []);

  // Handle auto-prompt from navigation params
  // Use both useFocusEffect and useEffect to catch all cases
  useFocusEffect(
    useCallback(() => {
      // Reset ref when screen gains focus
      autoSentRef.current = false;
    }, [])
  );

  useEffect(() => {
    const autoPrompt = route.params?.autoPrompt;
    if (autoPrompt && !autoSentRef.current) {
      autoSentRef.current = true;
      // Small delay to ensure screen is fully mounted and ready
      const timer = setTimeout(() => {
        console.log('Auto-sending prompt:', autoPrompt);
        handleSend(autoPrompt);
        // Clear the param after using it
        navigation.setParams({ autoPrompt: undefined });
      }, 600);
      return () => clearTimeout(timer);
    }
  }, [route.params?.autoPrompt, navigation, handleSend]);

  const formatTime = (date) => {
    if (!date) return '';
    const now = new Date();
    const diff = now - date;
    const minutes = Math.floor(diff / 60000);
    if (minutes < 1) return 'Just now';
    if (minutes < 60) return `${minutes}m ago`;
    const hours = Math.floor(minutes / 60);
    if (hours < 24) return `${hours}h ago`;
    return date.toLocaleDateString();
  };

  const renderMessageText = (text) => {
    // Parse markdown-style bold text (**text**)
    const parts = [];
    const regex = /\*\*(.*?)\*\*/g;
    let lastIndex = 0;
    let match;

    while ((match = regex.exec(text)) !== null) {
      // Add text before the bold part
      if (match.index > lastIndex) {
        parts.push({ text: text.substring(lastIndex, match.index), bold: false });
      }
      // Add the bold part
      parts.push({ text: match[1], bold: true });
      lastIndex = regex.lastIndex;
    }

    // Add remaining text after last match
    if (lastIndex < text.length) {
      parts.push({ text: text.substring(lastIndex), bold: false });
    }

    // If no bold text found, return original text
    if (parts.length === 0) {
      return <Text style={styles.messageText}>{text}</Text>;
    }

    // Render with bold parts
    return (
      <Text style={styles.messageText}>
        {parts.map((part, index) => (
          <Text
            key={index}
            style={part.bold ? styles.messageTextBold : styles.messageText}
          >
            {part.text}
          </Text>
        ))}
      </Text>
    );
  };

  const onRefresh = React.useCallback(() => {
    setRefreshing(true);
    // Simulate refresh
    setTimeout(() => {
      setRefreshing(false);
    }, 1000);
  }, []);


  return (
    <View style={styles.container}>
      <LinearGradient
        colors={[colors.background, colors.backgroundSecondary, colors.background]}
        locations={[0, 0.5, 1]}
        style={[styles.gradient, { paddingTop: insets.top, paddingBottom: insets.bottom }]}
      >
        <KeyboardAvoidingView
          behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
          style={styles.keyboardView}
          keyboardVerticalOffset={Platform.OS === 'ios' ? 0 : 20}
        >
          {/* Header */}
          <View style={styles.header}>
            <LinearGradient
              colors={[colors.accentPurple, colors.accentBlue, 'transparent']}
              locations={[0, 0.5, 1]}
              start={{ x: 0, y: 0 }}
              end={{ x: 1, y: 0 }}
              style={styles.headerGradient}
            />
            <View style={styles.headerContent}>
              <View style={styles.weatherBadge}>
                <Text style={styles.weatherIcon}>🌡️</Text>
                <Text style={styles.weatherText}>72°F</Text>
              </View>
              <View style={styles.scheduleBadge}>
                <Text style={styles.scheduleIcon}>⏰</Text>
                <Text style={styles.scheduleText}>Free until 6:30 PM</Text>
              </View>
              <View style={styles.moodBadge}>
                <Text style={styles.moodText}>Chill ✨</Text>
              </View>
            </View>
          </View>

          {/* Messages and Recommendations */}
          <ScrollView
            ref={scrollViewRef}
            style={styles.scrollView}
            contentContainerStyle={styles.scrollContent}
            showsVerticalScrollIndicator={false}
            refreshControl={
              <RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor={colors.textPrimary} />
            }
          >
            {messages.map((message, index) => (
              <React.Fragment key={message.id}>
                <Animated.View
                  entering={message.role === 'user' ? FadeInDown.delay(index * 50) : FadeInUp.delay(index * 50)}
                  style={[
                    styles.messageContainer,
                    message.role === 'ai' && styles.aiMessageContainer,
                  ]}
                >
                  <LinearGradient
                    colors={message.role === 'user' 
                      ? [colors.gradientStart, colors.gradientEnd] 
                      : ['#31374D', '#31374D']}
                    start={{ x: 0, y: 0 }}
                    end={{ x: 1, y: 1 }}
                    style={[
                      styles.messageBubble,
                      message.role === 'ai' && styles.aiBubble,
                    ]}
                  >
                    {renderMessageText(message.content)}
                    {message.timestamp && (
                      <Text style={styles.timestamp}>{formatTime(message.timestamp)}</Text>
                    )}
                  </LinearGradient>
                </Animated.View>
                
                {/* Show recommendations right after AI message that generated them */}
                {message.role === 'ai' && message.recommendations && message.recommendations.length > 0 && (
                  <Animated.View
                    entering={FadeInUp.delay((index + 1) * 50)}
                    style={styles.recommendationsContainer}
                  >
                    {message.recommendations.map((rec, recIndex) => {
                      console.log('Rendering recommendation card:', rec);
                      return (
                        <RecommendationCard
                          key={rec.id || `rec-${index}-${recIndex}`}
                          title={rec.title || 'Unknown Place'}
                          description={rec.description || 'Nearby location'}
                          image={rec.image}
                          walkTime={rec.walkTime || 'N/A'}
                          popularity={rec.popularity || 'Low'}
                        />
                      );
                    })}
                  </Animated.View>
                )}
              </React.Fragment>
            ))}

            {/* Typing Indicator */}
            {isTyping && (
              <Animated.View
                entering={FadeInUp}
                style={[styles.messageContainer, styles.aiMessageContainer]}
              >
                <View style={[styles.messageBubble, styles.aiBubble, styles.typingBubble]}>
                  <View style={styles.typingIndicator}>
                    <View style={[styles.typingDot, { animationDelay: '0ms' }]} />
                    <View style={[styles.typingDot, { animationDelay: '150ms' }]} />
                    <View style={[styles.typingDot, { animationDelay: '300ms' }]} />
                  </View>
                </View>
              </Animated.View>
            )}
          </ScrollView>

          {/* Input Field - add extra bottom padding so nav bar doesn't overlap */}
          <View
            style={[
              styles.inputContainer,
              { paddingBottom: Math.max(insets.bottom, spacing['2xl']) + NAV_BAR_OFFSET },
            ]}
          >
            <InputField
              placeholder="Ask VioletVibes..."
              onSend={handleSend}
            />
          </View>

        </KeyboardAvoidingView>
      </LinearGradient>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  gradient: {
    flex: 1,
  },
  keyboardView: {
    flex: 1,
  },
  header: {
    paddingTop: spacing['2xl'], // 16pt top padding
    paddingBottom: spacing['2xl'], // 16pt bottom padding
    paddingHorizontal: spacing['2xl'], // 16pt horizontal padding
    borderBottomWidth: 1,
    borderBottomColor: colors.borderLight,
    position: 'relative',
    width: '100%',
  },
  headerGradient: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    height: 70.5,
    opacity: 0.4,
  },
  headerContent: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    gap: spacing.md, // 8pt gap between badges
    flexWrap: 'nowrap',
    width: '100%',
  },
  weatherBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.accentBlue,
    borderWidth: 1,
    borderColor: colors.accentBlueMedium,
    borderRadius: borderRadius.md,
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.xs,
    gap: spacing.sm,
    flexShrink: 0,
    height: 32, // Fixed height for alignment
  },
  weatherIcon: {
    fontSize: 16,
  },
  weatherText: {
    fontSize: typography.fontSize.sm,
    fontWeight: typography.fontWeight.semiBold,
    color: colors.textBlue,
  },
  scheduleBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.glassBackground,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: borderRadius.md,
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.xs,
    gap: spacing.sm,
    flexShrink: 0,
    height: 32, // Fixed height for alignment
  },
  scheduleIcon: {
    fontSize: 16,
  },
  scheduleText: {
    fontSize: typography.fontSize.sm,
    fontWeight: typography.fontWeight.semiBold,
    color: colors.textPrimary,
  },
  moodBadge: {
    backgroundColor: colors.whiteOverlay,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: borderRadius.md,
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.xs,
    flexShrink: 0,
    height: 32, // Fixed height for alignment
    justifyContent: 'center',
    alignItems: 'center',
  },
  moodText: {
    fontSize: typography.fontSize.sm,
    fontWeight: typography.fontWeight.semiBold,
    color: colors.textSecondary,
  },
  scrollView: {
    flex: 1,
  },
  scrollContent: {
    paddingHorizontal: spacing['2xl'], // 16pt horizontal padding
    paddingTop: spacing['3xl'], // 20pt top padding
    paddingBottom: 180, // Extra padding to prevent nav bar overlap
  },
  messageContainer: {
    marginBottom: spacing.xl,
    alignItems: 'flex-end',
  },
  aiMessageContainer: {
    alignItems: 'flex-start',
  },
  messageBubble: {
    maxWidth: width * 0.75,
    paddingHorizontal: spacing['3xl'],
    paddingVertical: spacing['2xl'],
    borderRadius: borderRadius.lg,
    borderTopRightRadius: 6.8,
    ...shadows.message,
  },
  aiBubble: {
    borderTopRightRadius: borderRadius.lg,
    borderTopLeftRadius: 6.8,
  },
  messageText: {
    fontSize: typography.fontSize.lg,
    fontWeight: typography.fontWeight.regular,
    color: colors.textPrimary,
    lineHeight: typography.lineHeight.xl,
    marginBottom: spacing.xs,
  },
  messageTextBold: {
    fontSize: typography.fontSize.lg,
    fontWeight: typography.fontWeight.bold,
    color: colors.textPrimary,
    lineHeight: typography.lineHeight.xl,
  },
  timestamp: {
    fontSize: typography.fontSize.xs,
    fontWeight: typography.fontWeight.regular,
    color: colors.textSecondary,
    opacity: 0.7,
    marginTop: spacing.xs,
  },
  typingBubble: {
    paddingVertical: spacing['2xl'],
  },
  typingIndicator: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
  },
  typingDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: colors.textSecondary,
    opacity: 0.6,
  },
  recommendationsContainer: {
    marginTop: spacing['2xl'],
    marginBottom: spacing.xl,
    alignItems: 'flex-start',
    width: '100%',
    alignSelf: 'stretch',
  },
  inputContainer: {
    paddingBottom: spacing['2xl'], // 16pt bottom padding before nav bar
  },
});

