import React from "react";
import {
  View,
  Text,
  StyleSheet,
  Modal,
  TouchableOpacity,
  TouchableWithoutFeedback,
} from "react-native";
import { LinearGradient } from "expo-linear-gradient";
import SvgIcon from "./SvgIcon";
import { colors, typography, spacing, borderRadius } from "../constants/theme";

type NotificationData = {
  message?: string;
};

type NotificationProps = {
  visible: boolean;
  onDismiss?: () => void;
  onViewEvent?: () => void;
  notification?: NotificationData;
};

const Notification: React.FC<NotificationProps> = ({
  visible,
  onDismiss,
  onViewEvent,
  notification,
}) => {
  if (!visible) return null;

  const handleDismiss = () => onDismiss?.();
  const handleViewEvent = () => onViewEvent?.();

  return (
    <Modal
      visible={visible}
      transparent
      animationType="fade"
      onRequestClose={handleDismiss}
    >
      <TouchableWithoutFeedback onPress={handleDismiss}>
        <View style={styles.overlay}>
          <TouchableWithoutFeedback>
            <View style={styles.container}>
              <LinearGradient
                colors={[colors.backgroundCard, colors.backgroundCardDark]}
                start={{ x: 0, y: 0 }}
                end={{ x: 1, y: 1 }}
                style={styles.content}
              >
                {/* HEADER */}
                <View style={styles.header}>
                  <View style={styles.avatarContainer}>
                    <View style={styles.avatar}>
                      <SvgIcon name="icon" size={28} color="#FFFFFF" />
                    </View>
                  </View>

                  <View style={styles.headerText}>
                    <View style={styles.headerTop}>
                      <Text style={styles.appName}>VioletVibes</Text>
                      <Text style={styles.time}>now</Text>
                    </View>

                    <View style={styles.notificationTitle}>
                      <Text style={styles.bellIcon}>🔔</Text>
                      <Text style={styles.notificationText}>
                        You're free till 8 PM!
                      </Text>
                    </View>

                    <Text style={styles.notificationDescription}>
                      {notification?.message ||
                        "Live jazz at Fulton St starts soon (7 min walk)."}
                    </Text>
                  </View>
                </View>

                {/* ACTION BUTTONS */}
                <View style={styles.actions}>
                  <TouchableOpacity
                    style={styles.viewEventButton}
                    onPress={handleViewEvent}
                    activeOpacity={0.8}
                  >
                    <Text style={styles.viewEventText}>View Event</Text>
                  </TouchableOpacity>

                  <TouchableOpacity
                    style={styles.dismissButton}
                    onPress={handleDismiss}
                    activeOpacity={0.8}
                  >
                    <Text style={styles.dismissText}>Dismiss</Text>
                  </TouchableOpacity>
                </View>
              </LinearGradient>
            </View>
          </TouchableWithoutFeedback>
        </View>
      </TouchableWithoutFeedback>
    </Modal>
  );
};

export default Notification;

const styles = StyleSheet.create({
  overlay: {
    flex: 1,
    backgroundColor: "rgba(0,0,0,0.5)",
    justifyContent: "center",
    alignItems: "center",
    padding: spacing["3xl"],
  },
  container: {
    width: "100%",
    maxWidth: 361,
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    borderColor: colors.borderMedium,
    overflow: "hidden",
  },
  content: {
    padding: spacing["3xl"],
  },
  header: {
    flexDirection: "row",
    marginBottom: spacing["3xl"],
  },
  avatarContainer: {
    marginRight: spacing["2xl"],
  },
  avatar: {
    width: 48,
    height: 48,
    borderRadius: borderRadius.md,
    backgroundColor: colors.backgroundCard,
    borderWidth: 1,
    borderColor: colors.borderMedium,
    justifyContent: "center",
    alignItems: "center",
  },
  headerText: {
    flex: 1,
  },
  headerTop: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: spacing.md,
  },
  appName: {
    fontSize: typography.fontSize.md,
    fontWeight: typography.fontWeight.bold,
    color: colors.textPrimary,
  },
  time: {
    fontSize: typography.fontSize.xs,
    fontWeight: typography.fontWeight.medium,
    color: colors.textSecondary,
  },
  notificationTitle: {
    flexDirection: "row",
    alignItems: "center",
    marginBottom: spacing.xs,
    gap: spacing.md,
  },
  bellIcon: {
    fontSize: 16,
  },
  notificationText: {
    fontSize: typography.fontSize.md,
    fontWeight: typography.fontWeight.semiBold,
    color: colors.textPrimary,
  },
  notificationDescription: {
    fontSize: typography.fontSize.base,
    fontWeight: typography.fontWeight.regular,
    color: colors.textSecondary,
    lineHeight: typography.lineHeight.relaxed,
    marginTop: spacing.xs,
  },
  actions: {
    flexDirection: "row",
    gap: spacing.xl,
    borderTopWidth: 1,
    borderTopColor: colors.border,
    paddingTop: spacing["2xl"],
  },
  viewEventButton: {
    flex: 1,
    backgroundColor: colors.accentPurpleMedium,
    borderRadius: borderRadius.md,
    paddingVertical: spacing.lg,
    paddingHorizontal: spacing["2xl"],
    alignItems: "center",
  },
  viewEventText: {
    fontSize: typography.fontSize.sm,
    fontWeight: typography.fontWeight.semiBold,
    color: colors.gradientStart,
  },
  dismissButton: {
    flex: 1,
    backgroundColor: colors.whiteOverlay,
    borderRadius: borderRadius.md,
    paddingVertical: spacing.lg,
    paddingHorizontal: spacing["2xl"],
    alignItems: "center",
  },
  dismissText: {
    fontSize: typography.fontSize.sm,
    fontWeight: typography.fontWeight.semiBold,
    color: colors.textPrimary,
  },
});
