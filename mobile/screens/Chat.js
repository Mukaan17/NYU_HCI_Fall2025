import React, { useState, useRef, useEffect } from 'react';
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
import { colors, typography, spacing, borderRadius, shadows } from '../constants/theme';

const { width } = Dimensions.get('window');

export default function Chat({ navigation }) {
  const insets = useSafeAreaInsets();
  const scrollViewRef = useRef(null);
  const [refreshing, setRefreshing] = useState(false);
  const [isTyping, setIsTyping] = useState(false);
  const [messages, setMessages] = useState([
    {
      id: 1,
      role: 'ai',
      content: "Find something fun with friends tonight.",
      timestamp: new Date(Date.now() - 3600000),
    },
    {
      id: 2,
      role: 'ai',
      content: "Need a quick study break spot",
      timestamp: new Date(Date.now() - 1800000),
    },
    {
      id: 3,
      role: 'ai',
      content: "Where can I grab dinner?",
      timestamp: new Date(Date.now() - 600000),
    },
  ]);

  const recommendations = [
    {
      id: 1,
      title: 'Fulton Jazz Lounge',
      description: 'Live jazz tonight at 8 PM',
      image: 'https://via.placeholder.com/96',
      walkTime: '7 min walk',
      popularity: 'Medium',
    },
    {
      id: 2,
      title: 'Brooklyn Rooftop',
      description: 'Great vibes & skyline views',
      image: 'https://via.placeholder.com/96',
      walkTime: '12 min walk',
      popularity: 'High',
    },
    {
      id: 3,
      title: 'Butler Café',
      description: 'Great for study breaks',
      image: 'https://via.placeholder.com/96',
      walkTime: '3 min walk',
      popularity: 'Low',
    },
    {
      id: 4,
      title: 'DeKalb Market Hall',
      description: '40+ food vendors, all styles',
      image: 'https://via.placeholder.com/96',
      walkTime: '5 min walk',
      popularity: 'Medium',
    },
  ];

  useEffect(() => {
    // Scroll to bottom when new messages are added
    if (scrollViewRef.current) {
      setTimeout(() => {
        scrollViewRef.current?.scrollToEnd({ animated: true });
      }, 100);
    }
  }, [messages]);

  const handleSend = async (text) => {
    if (!text || !text.trim()) return;
    
    const userMessage = { id: Date.now(), role: 'user', content: text.trim(), timestamp: new Date() };
    setMessages((prev) => [...prev, userMessage]);
    setIsTyping(true);

    // Simulate AI response - in production, this would call your API
    try {
      // Uncomment when API is ready:
      // const res = await fetch("http://YOUR_IP:5000/api/chat", {
      //   method: "POST",
      //   headers: { "Content-Type": "application/json" },
      //   body: JSON.stringify({ mood: "chill", message: text.trim() }),
      // });
      // const data = await res.json();
      // const aiMessage = { id: Date.now() + 1, role: 'ai', content: data.reply || "...", timestamp: new Date() };
      // setMessages((prev) => [...prev, aiMessage]);

      // Temporary: Simulate AI response
      setTimeout(() => {
        setIsTyping(false);
        const aiMessage = {
          id: Date.now() + 1,
          role: 'ai',
          content: 'Here are some great options for you!',
          timestamp: new Date(),
        };
        setMessages((prev) => [...prev, aiMessage]);
      }, 1500);
    } catch (error) {
      console.error('Error sending message:', error);
      setIsTyping(false);
      const errorMessage = {
        id: Date.now() + 1,
        role: 'ai',
        content: 'Sorry, I encountered an error. Please try again.',
        timestamp: new Date(),
      };
      setMessages((prev) => [...prev, errorMessage]);
    }
  };

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
              <Animated.View
                key={message.id}
                entering={message.role === 'user' ? FadeInDown.delay(index * 50) : FadeInUp.delay(index * 50)}
                style={[
                  styles.messageContainer,
                  message.role === 'ai' && styles.aiMessageContainer,
                ]}
              >
                <LinearGradient
                  colors={[colors.gradientStart, colors.gradientEnd]}
                  start={{ x: 0, y: 0 }}
                  end={{ x: 1, y: 1 }}
                  style={[
                    styles.messageBubble,
                    message.role === 'ai' && styles.aiBubble,
                  ]}
                >
                  <Text style={styles.messageText}>{message.content}</Text>
                  {message.timestamp && (
                    <Text style={styles.timestamp}>{formatTime(message.timestamp)}</Text>
                  )}
                </LinearGradient>
              </Animated.View>
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

            {/* Recommendations */}
            <View style={styles.recommendationsContainer}>
              {recommendations.map((rec) => (
                <RecommendationCard
                  key={rec.id}
                  title={rec.title}
                  description={rec.description}
                  image={rec.image}
                  walkTime={rec.walkTime}
                  popularity={rec.popularity}
                />
              ))}
            </View>
          </ScrollView>

          {/* Input Field */}
          <View style={styles.inputContainer}>
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
    justifyContent: 'space-between',
    alignItems: 'center',
    gap: spacing['2xl'], // 16pt gap between badges (Apple standard)
    flexWrap: 'wrap',
  },
  weatherBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.accentBlue,
    borderWidth: 1,
    borderColor: colors.accentBlueMedium,
    borderRadius: borderRadius.md,
    paddingHorizontal: spacing['2xl'],
    paddingVertical: spacing.xs,
    gap: spacing.md,
    flexShrink: 0,
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
    paddingHorizontal: spacing['2xl'],
    paddingVertical: spacing.xs,
    gap: spacing.md,
    flex: 1,
    minWidth: width * 0.4,
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
    paddingHorizontal: spacing['2xl'],
    paddingVertical: spacing.xs,
    flexShrink: 0,
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
    marginTop: spacing.xl,
  },
  inputContainer: {
    paddingBottom: spacing['2xl'], // 16pt bottom padding before nav bar
  },
});

