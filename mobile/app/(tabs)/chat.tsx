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
import RecommendationCard from '../../components/RecommendationCard.js';
import InputField from '../../components/InputField.js';
import { colors, typography, spacing, borderRadius, shadows } from '../../constants/theme';

const { width } = Dimensions.get('window');

export default function Chat() {
  const insets = useSafeAreaInsets();
  const scrollViewRef = useRef<ScrollView | null>(null);

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
    scrollViewRef.current?.scrollToEnd({ animated: true });
  }, [messages]);

  const handleSend = (text: string) => {
    if (!text.trim()) return;

    const userMessage = {
      id: Date.now(),
      role: 'user',
      content: text.trim(),
      timestamp: new Date(),
    };
    setMessages((prev) => [...prev, userMessage]);
    setIsTyping(true);

    setTimeout(() => {
      setIsTyping(false);
      const aiMessage = {
        id: Date.now() + 1,
        role: 'ai',
        content: 'Here are some great options for you!',
        timestamp: new Date(),
      };
      setMessages((prev) => [...prev, aiMessage]);
    }, 1200);
  };

  const formatTime = (date: Date) => {
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    const minutes = Math.floor(diff / 60000);

    if (minutes < 1) return 'Just now';
    if (minutes < 60) return `${minutes}m ago`;

    const hours = Math.floor(minutes / 60);
    if (hours < 24) return `${hours}h ago`;

    return date.toLocaleDateString();
  };

  const onRefresh = () => {
    setRefreshing(true);
    setTimeout(() => setRefreshing(false), 1000);
  };

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
        >
          {/* HEADER */}
          <View style={styles.header}>
            <Text style={styles.headerText}>VioletVibes</Text>
          </View>

          {/* MESSAGES */}
          <ScrollView
            ref={scrollViewRef}
            style={styles.scrollView}
            contentContainerStyle={styles.scrollContent}
            refreshControl={
              <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
            }
            showsVerticalScrollIndicator={false}
          >
            {messages.map((msg, index) => (
              <Animated.View
                entering={msg.role === 'ai' ? FadeInUp.delay(index * 25) : FadeInDown.delay(index * 25)}
                key={msg.id}
                style={[
                  styles.messageContainer,
                  msg.role === 'ai' && styles.aiMessageContainer,
                ]}
              >
                <LinearGradient
                  colors={[colors.gradientStart, colors.gradientEnd]}
                  style={styles.messageBubble}
                >
                  <Text style={styles.messageText}>{msg.content}</Text>
                  <Text style={styles.timestamp}>{formatTime(msg.timestamp)}</Text>
                </LinearGradient>
              </Animated.View>
            ))}

            {isTyping && (
              <View style={[styles.messageContainer, styles.aiMessageContainer]}>
                <View style={[styles.messageBubble, styles.typingBubble]}>
                  <View style={styles.typingIndicator}>
                    <View style={styles.typingDot} />
                    <View style={styles.typingDot} />
                    <View style={styles.typingDot} />
                  </View>
                </View>
              </View>
            )}

            {/* RECOMMENDATIONS */}
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

          {/* INPUT */}
          <View style={styles.inputContainer}>
            <InputField
                placeholder="Ask VioletVibes..."
                onSend={handleSend}
                style={{}}   // ← Add this
            />
          </View>
        </KeyboardAvoidingView>
      </LinearGradient>
    </View>
  );
}

/* ------------------ STYLES ------------------ */
const styles = StyleSheet.create({
  container: { flex: 1 },
  gradient: { flex: 1 },
  keyboardView: { flex: 1 },
  header: {
    paddingHorizontal: 20,
    paddingVertical: 10,
  },
  headerText: {
    fontSize: 24,
    fontWeight: '600',
    color: colors.textPrimary,
  },
  scrollView: { flex: 1 },
  scrollContent: {
    paddingHorizontal: 20,
    paddingTop: 10,
    paddingBottom: 150,
  },
  messageContainer: {
    width: '100%',
    alignItems: 'flex-end',
    marginBottom: 12,
  },
  aiMessageContainer: { alignItems: 'flex-start' },
  messageBubble: {
    padding: 14,
    borderRadius: 20,
    maxWidth: '80%',
  },
  messageText: {
    color: colors.textPrimary,
    fontSize: 16,
  },
  timestamp: {
    color: colors.textSecondary,
    fontSize: 12,
    marginTop: 4,
    opacity: 0.7,
  },
  typingBubble: {
    backgroundColor: colors.backgroundCard,
    padding: 14,
  },
  typingIndicator: {
    flexDirection: 'row',
    gap: 6,
  },
  typingDot: {
    width: 6,
    height: 6,
    borderRadius: 3,
    backgroundColor: colors.textSecondary,
    opacity: 0.5,
  },
  recommendationsContainer: {
    marginTop: 20,
    gap: 16,
  },
  inputContainer: {
    paddingBottom: 20,
    paddingHorizontal: 20,
  },
});
