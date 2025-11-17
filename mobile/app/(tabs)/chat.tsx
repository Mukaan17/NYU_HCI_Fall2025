// mobile/app/(tabs)/chat.tsx
import React, { useRef, useEffect } from "react";
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  KeyboardAvoidingView,
  Platform,
  RefreshControl,
  ScrollView as RNScrollView,
} from "react-native";
import { LinearGradient } from "expo-linear-gradient";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import Animated, { FadeInDown, FadeInUp } from "react-native-reanimated";
import RecommendationCard from "../../components/RecommendationCard";
import InputField from "../../components/InputField";
import { colors } from "../../constants/theme";
import { router } from "expo-router";
import { usePlace } from "../../context/PlaceContext";
import {
  useChat,
  ChatMessage,
  Recommendation,
} from "../../context/ChatContext";

const BACKEND_URL =
  process.env.EXPO_PUBLIC_API_URL || "http://192.168.1.155:5000";

export default function Chat() {
  const insets = useSafeAreaInsets();
  const scrollViewRef = useRef<RNScrollView | null>(null);
  const { setSelectedPlace } = usePlace();
  const { messages, setMessages } = useChat();

  const [refreshing] = React.useState(false);
  const [isTyping, setIsTyping] = React.useState(false);

  // Keep enough padding so InputField sits above the NavBar
  const navOffset = insets.bottom + 40;

  useEffect(() => {
    const id = setTimeout(() => {
      scrollViewRef.current?.scrollToEnd({ animated: true });
    }, 50);

    return () => clearTimeout(id);
  }, [messages]);

  const handleCardPress = (rec: Recommendation) => {
    setSelectedPlace({
      name: rec.title,
      latitude: rec.lat ?? 40.693393,
      longitude: rec.lng ?? -73.98555,
      walkTime: rec.walkTime,
      distance: rec.distance,
      address: rec.description,
    });

    router.push("/(tabs)/map");
  };

  const handleSend = async (text: string) => {
    const trimmed = text.trim();
    if (!trimmed) return;

    // Add user message
    setMessages((prev: ChatMessage[]) => [
      ...prev,
      {
        id: Date.now(),
        type: "text",
        role: "user",
        content: trimmed,
        timestamp: new Date(),
      },
    ]);

    setIsTyping(true);

    try {
      const response = await fetch(`${BACKEND_URL}/api/chat`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ message: trimmed }),
      });

      const data = await response.json();

      // Add AI reply text
      setMessages((prev: ChatMessage[]) => [
        ...prev,
        {
          id: Date.now() + 1,
          type: "text",
          role: "ai",
          content: data.reply || "I couldn’t think of anything — try again!",
          timestamp: new Date(),
        },
      ]);

      // If backend includes places → render recommendation cards
      if (data.places && Array.isArray(data.places) && data.places.length > 0) {
        const recs: Recommendation[] = data.places.map(
          (p: any, index: number) => ({
            id: index,
            title: p.name,
            description: p.address,
            distance: p.distance,
            walkTime: p.walk_time,
            lat: p.location?.lat,
            lng: p.location?.lng,
            popularity: p.rating ? `⭐ ${p.rating}` : null,
          })
        );

        setMessages((prev: ChatMessage[]) => [
          ...prev,
          {
            id: Date.now() + 2,
            type: "recommendations",
            role: "ai",
            recommendations: recs,
            timestamp: new Date(),
          },
        ]);
      }
    } catch (err) {
      console.log(err);
    } finally {
      setIsTyping(false);
    }
  };

  return (
    <View style={styles.container}>
      <LinearGradient
        colors={[
          colors.background,
          colors.backgroundSecondary,
          colors.background,
        ]}
        style={[
          styles.gradient,
          { paddingTop: insets.top, paddingBottom: navOffset },
        ]}
      >
        <KeyboardAvoidingView
          behavior={Platform.OS === "ios" ? "padding" : "height"}
          style={{ flex: 1 }}
          keyboardVerticalOffset={insets.top + 40}
        >
          <ScrollView
            ref={scrollViewRef}
            style={{ flex: 1 }}
            contentContainerStyle={styles.content}
            showsVerticalScrollIndicator={false}
            refreshControl={
              <RefreshControl refreshing={refreshing} onRefresh={() => {}} />
            }
          >
            {messages.map((msg: ChatMessage, index: number) => {
              if (msg.type === "recommendations") {
                return (
                  <Animated.View
                    key={msg.id}
                    entering={FadeInUp.delay(index * 40)}
                    style={styles.aiBubbleContainer}
                  >
                    {msg.recommendations.map(
                      (rec: Recommendation) => (
                        <RecommendationCard
                          key={rec.id}
                          title={rec.title}
                          description={rec.description}
                          walkTime={rec.walkTime}
                          popularity={rec.popularity}
                          onPress={() => handleCardPress(rec)}
                        />
                      )
                    )}
                  </Animated.View>
                );
              }

              return (
                <Animated.View
                  key={msg.id}
                  entering={
                    msg.role === "ai"
                      ? FadeInUp.delay(index * 40)
                      : FadeInDown.delay(index * 40)
                  }
                  style={[
                    styles.messageBubble,
                    msg.role === "ai" ? styles.aiBubble : styles.userBubble,
                  ]}
                >
                  <Text style={styles.text}>{msg.content}</Text>
                </Animated.View>
              );
            })}

            {isTyping && (
              <Animated.View
                entering={FadeInUp}
                style={[styles.messageBubble, styles.aiBubble]}
              >
                <Text style={styles.text}>Violet is thinking…</Text>
              </Animated.View>
            )}
          </ScrollView>

          {/* Extra bottom padding so this doesn't sit under NavBar */}
          <View
            style={{
              paddingHorizontal: 20,
              paddingBottom: insets.bottom,
            }}
          >
            <InputField placeholder="Ask VioletVibes..." onSend={handleSend} />
          </View>
        </KeyboardAvoidingView>
      </LinearGradient>
    </View>
  );
}

/* ---------- STYLES ---------- */

const styles = StyleSheet.create({
  container: { flex: 1 },
  gradient: { flex: 1 },
  content: { padding: 20, paddingBottom: 50 },
  aiBubbleContainer: { width: "100%" },
  messageBubble: {
    maxWidth: "80%",
    padding: 14,
    borderRadius: 18,
    marginBottom: 10,
  },
  aiBubble: { backgroundColor: "#2b2f47" },
  userBubble: {
    backgroundColor: "#5a4ccf",
    alignSelf: "flex-end",
  },
  text: { color: "white", fontSize: 16 },
});

export {};

