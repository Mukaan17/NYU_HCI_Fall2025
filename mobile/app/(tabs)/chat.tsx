// mobile/app/(tabs)/chat.tsx
import React, { useRef, useEffect, useCallback, useState } from "react";
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  KeyboardAvoidingView,
  Platform,
  RefreshControl,
  Dimensions,
} from "react-native";
import { LinearGradient } from "expo-linear-gradient";
import Animated, { FadeInDown, FadeInUp } from "react-native-reanimated";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import SvgIcon from "../../components/SvgIcon";
import RecommendationCard from "../../components/RecommendationCard";
import InputField from "../../components/InputField";
import { getWeather } from "../../utils/getWeather";
import { colors, typography, spacing, borderRadius, shadows } from "../../constants/theme";
import { useChat, ChatMessage, Recommendation } from "../../context/ChatContext";
import { usePlace } from "../../context/PlaceContext";
import useLocation from "../../hooks/useLocation";
import { router } from "expo-router";

const { width } = Dimensions.get("window");
const NAV_BAR_OFFSET = 75;

const BACKEND_URL =
  process.env.EXPO_PUBLIC_API_URL || "http://localhost:5001";

export default function Chat() {
  const insets = useSafeAreaInsets();
  const scrollViewRef = useRef<ScrollView | null>(null);

  const { messages, setMessages } = useChat();
  const { setSelectedPlace } = usePlace();
  const { location } = useLocation();
  useEffect(() => {
    let isMounted = true;
    
    async function loadWeather() {
      if (!location || !isMounted) return;

      const w = await getWeather(location.latitude, location.longitude);
      if (w && isMounted) {
        setTemp(w.temp);
        setWeatherEmoji(w.emoji);
      }
    }
    loadWeather();

    return () => {
      isMounted = false;
    };
  }, [location]);


  const [isTyping, setIsTyping] = useState(false);
  const [refreshing, setRefreshing] = useState(false);

  const [temp, setTemp] = useState<number | null>(null);
  const [weatherEmoji, setWeatherEmoji] = useState<string>("☀️");

  /* ------------------ Auto scroll to bottom ------------------ */
  useEffect(() => {
    const timer = setTimeout(() => {
      scrollViewRef.current?.scrollToEnd({ animated: true });
    }, 80);
    return () => clearTimeout(timer);
  }, [messages]);

  /* ------------------ Handle sending message ------------------ */
  const handleSend = useCallback(
    async (text: string) => {
      const trimmed = text.trim();
      if (!trimmed) return;

      // Add user message
      setMessages((prev: ChatMessage[]) => [
        ...prev,
        {
          id: Date.now(),
          role: "user",
          type: "text",
          content: trimmed,
          timestamp: new Date(),
        },
      ]);

      setIsTyping(true);

      try {
        const payload: any = { message: trimmed };
        if (location) {
          payload.latitude = location.latitude;
          payload.longitude = location.longitude;
        }

        const res = await fetch(`${BACKEND_URL}/api/chat`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(payload),
        });

        const data = await res.json();

        // Add AI text reply
        setMessages((prev) => [
          ...prev,
          {
            id: Date.now() + 1,
            role: "ai",
            type: "text",
            content: data.reply || "I'm not sure — try asking differently!",
            timestamp: new Date(),
          },
        ]);

        // Add recommendations if present
        if (data.places && Array.isArray(data.places)) {
          const formatted: Recommendation[] = data.places.map(
            (p: any, index: number) => ({
              id: index,
              title: p.name,
              description: p.address,
              walkTime: p.walk_time,
              distance: p.distance,
              lat: p.location?.lat,
              lng: p.location?.lng,
              popularity: p.rating ? `⭐ ${p.rating}` : "N/A",
              image: p.photo_url,
            })
          );

          setMessages((prev) => [
            ...prev,
            {
              id: Date.now() + 2,
              role: "ai",
              type: "recommendations",
              recommendations: formatted,
              timestamp: new Date(),
            },
          ]);
        }
      } catch (err) {
        console.error(err);
      } finally {
        setIsTyping(false);
      }
    },
    [location, setMessages]
  );

  /* ------------------ Tap a recommendation → go to map ------------------ */
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

  /* ------------------ Pull to refresh ------------------ */
  const onRefresh = () => {
    setRefreshing(true);
    setTimeout(() => setRefreshing(false), 800);
  };

  /* ------------------ Format timestamps ------------------ */
  const formatTime = (date: Date) => {
    const diff = Date.now() - date.getTime();
    const minutes = Math.floor(diff / 60000);
    if (minutes < 1) return "Just now";
    if (minutes < 60) return `${minutes}m ago`;
    const hours = Math.floor(minutes / 60);
    if (hours < 24) return `${hours}h ago`;
    return date.toLocaleDateString();
  };

  return (
    <View style={styles.container}>
      <LinearGradient
        colors={[colors.background, colors.backgroundSecondary, colors.background]}
        style={[styles.gradient, { paddingTop: insets.top }]}
      >
        <KeyboardAvoidingView
          behavior={Platform.OS === "ios" ? "padding" : undefined}
          style={styles.keyboardView}
        >
          {/* ---------- HEADER (kept from JS version) ---------- */}
          <View style={styles.header}>
            <LinearGradient
              colors={[colors.accentPurple, colors.accentBlue, "transparent"]}
              style={styles.headerGradient}
            />
            <View style={styles.headerContent}>
              <View style={styles.weatherBadge}>
                <Text style={styles.weatherText}>
                  {weatherEmoji} {temp ? `${temp}°F` : "—"}
                </Text>
              </View>
              <View style={styles.scheduleBadge}>
                <SvgIcon name="clock" size={18} color={colors.textPrimary} />
                <Text style={styles.scheduleText}>Free until 6:30 PM</Text>
              </View>
              <View style={styles.moodBadge}>
                <Text style={styles.moodText}>Chill ✨</Text>
              </View>
            </View>
          </View>

          {/* ---------- MAIN CHAT SCROLLVIEW ---------- */}
          <ScrollView
            ref={scrollViewRef}
            contentContainerStyle={styles.scrollContent}
            showsVerticalScrollIndicator={false}
            refreshControl={
              <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
            }
          >
            {messages.map((msg, index) => {
              if (msg.type === "recommendations") {
                return (
                  <Animated.View
                    key={msg.id}
                    entering={FadeInUp.delay(40 * index)}
                    style={styles.recommendationsContainer}
                  >
                    {msg.recommendations?.map((rec) => (
                      <RecommendationCard
                        key={rec.id}
                        title={rec.title}
                        description={rec.description}
                        walkTime={rec.walkTime}
                        popularity={rec.popularity}
                        image={rec.image}
                        onPress={() => handleCardPress(rec)}
                      />
                    ))}
                  </Animated.View>
                );
              }

              return (
                <Animated.View
                  key={msg.id}
                  entering={
                    msg.role === "ai"
                      ? FadeInUp.delay(40 * index)
                      : FadeInDown.delay(40 * index)
                  }
                  style={[
                    styles.messageContainer,
                    msg.role === "ai" && styles.aiMessageContainer,
                  ]}
                >
                  <LinearGradient
                    colors={
                      msg.role === "user"
                        ? [colors.gradientStart, colors.gradientEnd]
                        : ["#31374D", "#31374D"]
                    }
                    style={[
                      styles.messageBubble,
                      msg.role === "ai" && styles.aiBubble,
                    ]}
                  >
                    <Text style={styles.messageText}>{msg.content}</Text>
                    <Text style={styles.timestamp}>{formatTime(msg.timestamp)}</Text>
                  </LinearGradient>
                </Animated.View>
              );
            })}

            {isTyping && (
              <Animated.View
                entering={FadeInUp}
                style={[styles.messageContainer, styles.aiMessageContainer]}
              >
                <View style={[styles.messageBubble, styles.aiBubble]}>
                  <Text style={styles.messageText}>Violet is thinking…</Text>
                </View>
              </Animated.View>
            )}
          </ScrollView>

          {/* ---------- INPUT FIELD ---------- */}
          <View
            style={[
              styles.inputContainer,
              { paddingBottom: insets.bottom + NAV_BAR_OFFSET },
            ]}
          >
            <InputField placeholder="Ask VioletVibes..." onSend={handleSend} />
          </View>
        </KeyboardAvoidingView>
      </LinearGradient>
    </View>
  );
}

/* --------------------------------------------------------- */
/* ---------------------------- STYLES ---------------------- */
/* --------------------------------------------------------- */

const styles = StyleSheet.create({
  container: { flex: 1 },
  gradient: { flex: 1 },
  keyboardView: { flex: 1 },

  header: {
    paddingTop: spacing["2xl"],
    paddingBottom: spacing["2xl"],
    paddingHorizontal: spacing["2xl"],
    borderBottomWidth: 0.5,
    borderBottomColor: colors.separator || colors.borderLight,
    position: "relative",
  },
  headerGradient: {
    position: "absolute",
    top: 0,
    left: 0,
    right: 0,
    height: 80,
    opacity: 0.4,
  },
  headerContent: {
    flexDirection: "row",
    justifyContent: "center",
    alignItems: "center",
    gap: spacing.lg,
  },
  weatherBadge: {
    flexDirection: "row",
    backgroundColor: colors.accentBlue,
    borderColor: colors.accentBlueMedium,
    borderRadius: borderRadius.md,
    borderWidth: 1,
    paddingHorizontal: spacing.xl,
    paddingVertical: spacing.sm,
    gap: spacing.sm,
  },
  weatherText: {
    fontSize: typography.fontSize.base,
    fontWeight: typography.fontWeight.semiBold,
    color: colors.textBlue,
    fontFamily: typography.fontFamily,
  },
  scheduleBadge: {
    flexDirection: "row",
    alignItems: "center",
    backgroundColor: colors.glassBackground,
    borderColor: colors.border,
    borderWidth: 1,
    borderRadius: borderRadius.md,
    paddingHorizontal: spacing.xl,
    paddingVertical: spacing.sm,
    gap: spacing.sm,
  },
  scheduleText: {
    fontSize: typography.fontSize.base,
    color: colors.textPrimary,
    fontWeight: typography.fontWeight.semiBold,
    fontFamily: typography.fontFamily,
  },
  moodBadge: {
    backgroundColor: colors.whiteOverlay,
    borderColor: colors.border,
    borderWidth: 1,
    borderRadius: borderRadius.md,
    paddingHorizontal: spacing.xl,
    paddingVertical: spacing.sm,
  },
  moodText: {
    fontSize: typography.fontSize.base,
    color: colors.textSecondary,
    fontWeight: typography.fontWeight.semiBold,
    fontFamily: typography.fontFamily,
  },

  scrollContent: {
    paddingHorizontal: spacing["2xl"],
    paddingTop: spacing["3xl"],
    paddingBottom: 120,
  },

  messageContainer: {
    marginBottom: spacing.xl,
    alignItems: "flex-end",
  },
  aiMessageContainer: { alignItems: "flex-start" },

  messageBubble: {
    maxWidth: width * 0.75,
    paddingHorizontal: spacing["3xl"],
    paddingVertical: spacing["2xl"],
    borderRadius: borderRadius.lg,
    borderTopRightRadius: 7,
    ...shadows.message,
  },
  aiBubble: {
    borderTopLeftRadius: 7,
    borderTopRightRadius: borderRadius.lg,
  },

  messageText: {
    fontSize: typography.fontSize.lg,
    color: colors.textPrimary,
    marginBottom: spacing.xs,
    fontFamily: typography.fontFamily,
  },
  timestamp: {
    fontSize: typography.fontSize.xs,
    opacity: 0.6,
    color: colors.textSecondary,
    fontFamily: typography.fontFamily,
  },

  recommendationsContainer: {
    marginTop: spacing["2xl"],
    marginBottom: spacing.xl,
    width: "100%",
  },

  inputContainer: {
    paddingHorizontal: spacing["2xl"],
  },
});