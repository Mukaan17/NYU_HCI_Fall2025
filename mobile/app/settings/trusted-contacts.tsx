// app/settings/trusted-contacts.tsx
import React, { useState, useEffect } from "react";
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  TouchableOpacity,
  TextInput,
  Alert,
  Platform,
} from "react-native";
import { LinearGradient } from "expo-linear-gradient";
import { BlurView } from "expo-blur";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import AsyncStorage from "@react-native-async-storage/async-storage";
import Animated, { FadeInDown } from "react-native-reanimated";
import * as Haptics from "expo-haptics";

import LiquidGlassButton from "../../components/LiquidGlassButton";
import {
  colors,
  typography,
  spacing,
  borderRadius,
} from "../../constants/theme";

interface TrustedContact {
  id: string;
  name: string;
  phoneNumber?: string;
  email?: string;
}

export default function TrustedContacts() {
  const insets = useSafeAreaInsets();
  const [trustedContacts, setTrustedContacts] = useState<TrustedContact[]>([]);
  const [showAddForm, setShowAddForm] = useState(false);
  const [newContactName, setNewContactName] = useState("");
  const [newContactPhone, setNewContactPhone] = useState("");
  const [newContactEmail, setNewContactEmail] = useState("");

  useEffect(() => {
    loadContacts();
  }, []);

  const loadContacts = async () => {
    try {
      const contactsStr = await AsyncStorage.getItem("trustedContacts");
      if (contactsStr) {
        const contacts = JSON.parse(contactsStr);
        setTrustedContacts(Array.isArray(contacts) ? contacts : []);
      }
    } catch (error) {
      console.error("Error loading contacts:", error);
    }
  };

  const saveContacts = async (contacts: TrustedContact[]) => {
    try {
      await AsyncStorage.setItem("trustedContacts", JSON.stringify(contacts));
      setTrustedContacts(contacts);
    } catch (error) {
      console.error("Error saving contacts:", error);
      Alert.alert("Error", "Failed to save contacts");
    }
  };

  const handleAddContact = () => {
    if (!newContactName.trim()) {
      Alert.alert("Error", "Please enter a contact name");
      return;
    }

    const newContact: TrustedContact = {
      id: Date.now().toString(),
      name: newContactName.trim(),
      phoneNumber: newContactPhone.trim() || undefined,
      email: newContactEmail.trim() || undefined,
    };

    const updatedContacts = [...trustedContacts, newContact];
    saveContacts(updatedContacts);

    setNewContactName("");
    setNewContactPhone("");
    setNewContactEmail("");
    setShowAddForm(false);

    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
  };

  const handleRemoveContact = (contactId: string) => {
    Alert.alert(
      "Remove Contact",
      "Are you sure you want to remove this trusted contact?",
      [
        { text: "Cancel", style: "cancel" },
        {
          text: "Remove",
          style: "destructive",
          onPress: () => {
            const updatedContacts = trustedContacts.filter(
              (c) => c.id !== contactId
            );
            saveContacts(updatedContacts);
            Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
          },
        },
      ]
    );
  };

  return (
    <View style={styles.container}>
      <LinearGradient
        colors={[colors.background, colors.backgroundSecondary, colors.background]}
        style={styles.gradient}
      />

      {/* Blur Shapes */}
      <View style={styles.blurShape1} />
      <View style={styles.blurShape2} />

      <ScrollView
        contentContainerStyle={[
          styles.scrollContent,
          { paddingTop: insets.top + 40, paddingBottom: insets.bottom + 20 },
        ]}
        showsVerticalScrollIndicator={false}
      >
        <View style={styles.content}>
          {/* Title */}
          <Animated.View entering={FadeInDown.duration(400)} style={styles.titleContainer}>
            <Text style={styles.title}>Trusted Contacts</Text>
            <Text style={styles.subtitle}>
              Manage contacts who can receive your location
            </Text>
          </Animated.View>

          {/* Add Contact Form */}
          {showAddForm && (
            <View style={styles.addFormContainer}>
              <View style={styles.card}>
                <Text style={styles.formTitle}>Add Trusted Contact</Text>

                <View style={styles.inputWrapper}>
                  <BlurView
                    intensity={Platform.OS === "ios" ? 40 : 30}
                    tint="dark"
                    style={styles.inputBlur}
                  >
                    <View style={styles.inputGlassOverlay} />
                    <TextInput
                      style={styles.input}
                      placeholder="Contact Name *"
                      placeholderTextColor={colors.textSecondary}
                      value={newContactName}
                      onChangeText={setNewContactName}
                      autoCapitalize="words"
                    />
                  </BlurView>
                </View>

                <View style={styles.inputWrapper}>
                  <BlurView
                    intensity={Platform.OS === "ios" ? 40 : 30}
                    tint="dark"
                    style={styles.inputBlur}
                  >
                    <View style={styles.inputGlassOverlay} />
                    <TextInput
                      style={styles.input}
                      placeholder="Phone Number (Optional)"
                      placeholderTextColor={colors.textSecondary}
                      value={newContactPhone}
                      onChangeText={setNewContactPhone}
                      keyboardType="phone-pad"
                    />
                  </BlurView>
                </View>

                <View style={styles.inputWrapper}>
                  <BlurView
                    intensity={Platform.OS === "ios" ? 40 : 30}
                    tint="dark"
                    style={styles.inputBlur}
                  >
                    <View style={styles.inputGlassOverlay} />
                    <TextInput
                      style={styles.input}
                      placeholder="Email (Optional)"
                      placeholderTextColor={colors.textSecondary}
                      value={newContactEmail}
                      onChangeText={setNewContactEmail}
                      keyboardType="email-address"
                      autoCapitalize="none"
                    />
                  </BlurView>
                </View>

                <View style={styles.formButtons}>
                  <TouchableOpacity
                    style={styles.cancelButton}
                    onPress={() => {
                      setShowAddForm(false);
                      setNewContactName("");
                      setNewContactPhone("");
                      setNewContactEmail("");
                    }}
                  >
                    <Text style={styles.cancelButtonText}>Cancel</Text>
                  </TouchableOpacity>
                  <TouchableOpacity
                    style={styles.addButton}
                    onPress={handleAddContact}
                  >
                    <Text style={styles.addButtonText}>Add</Text>
                  </TouchableOpacity>
                </View>
              </View>
            </View>
          )}

          {/* Contacts List */}
          {trustedContacts.length === 0 && !showAddForm ? (
            <View style={styles.emptyContainer}>
              <Text style={styles.emptyIcon}>👥</Text>
              <Text style={styles.emptyTitle}>No Trusted Contacts</Text>
              <Text style={styles.emptyDescription}>
                Add contacts to share your location with
              </Text>
            </View>
          ) : (
            <View style={styles.contactsList}>
              {trustedContacts.map((contact) => (
                <View key={contact.id} style={styles.contactCard}>
                  <View style={styles.contactInfo}>
                    <Text style={styles.contactName}>{contact.name}</Text>
                    {contact.phoneNumber && (
                      <Text style={styles.contactDetail}>
                        📞 {contact.phoneNumber}
                      </Text>
                    )}
                    {contact.email && (
                      <Text style={styles.contactDetail}>
                        ✉️ {contact.email}
                      </Text>
                    )}
                  </View>
                  <TouchableOpacity
                    style={styles.removeButton}
                    onPress={() => handleRemoveContact(contact.id)}
                  >
                    <Text style={styles.removeButtonText}>Remove</Text>
                  </TouchableOpacity>
                </View>
              ))}
            </View>
          )}

          {/* Add Contact Button */}
          {!showAddForm && (
            <LiquidGlassButton
              title="Add Trusted Contact"
              onPress={() => {
                Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
                setShowAddForm(true);
              }}
              variant="gradient"
              style={styles.addButtonContainer}
            />
          )}
        </View>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  gradient: {
    ...StyleSheet.absoluteFillObject,
  },
  blurShape1: {
    position: "absolute",
    top: -100,
    left: -50,
    width: 300,
    height: 300,
    borderRadius: 150,
    backgroundColor: colors.accentPurpleMedium,
    opacity: 0.6,
  },
  blurShape2: {
    position: "absolute",
    bottom: -80,
    right: -80,
    width: 250,
    height: 250,
    borderRadius: 125,
    backgroundColor: colors.accentBlue,
    opacity: 0.5,
  },
  scrollContent: {
    flexGrow: 1,
    paddingHorizontal: spacing["2xl"],
  },
  content: {
    flex: 1,
    paddingTop: spacing["4xl"],
  },
  titleContainer: {
    alignItems: "center",
    marginBottom: spacing["4xl"],
  },
  title: {
    fontSize: typography.fontSize["3xl"],
    fontWeight: typography.fontWeight.bold,
    color: colors.textPrimary,
    marginBottom: spacing.sm,
    textAlign: "center",
  },
  subtitle: {
    fontSize: typography.fontSize.base,
    fontWeight: typography.fontWeight.regular,
    color: colors.textSecondary,
    textAlign: "center",
  },
  addFormContainer: {
    marginBottom: spacing["4xl"],
  },
  card: {
    borderRadius: borderRadius.md,
    overflow: "hidden",
    borderWidth: 1,
    borderColor: colors.border,
    backgroundColor: colors.glassBackground,
    padding: spacing["2xl"],
  },
  formTitle: {
    fontSize: typography.fontSize.xl,
    fontWeight: typography.fontWeight.semiBold,
    color: colors.textPrimary,
    marginBottom: spacing["2xl"],
  },
  inputWrapper: {
    borderRadius: borderRadius.md,
    overflow: "hidden",
    borderWidth: 1,
    borderColor: colors.border,
    marginBottom: spacing.md,
  },
  inputBlur: {
    ...StyleSheet.absoluteFillObject,
  },
  inputGlassOverlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: colors.glassBackground,
  },
  input: {
    paddingHorizontal: spacing["2xl"],
    paddingVertical: spacing["2xl"],
    fontSize: typography.fontSize.base,
    color: colors.textPrimary,
    minHeight: 56,
  },
  formButtons: {
    flexDirection: "row",
    gap: spacing.md,
    marginTop: spacing.md,
  },
  cancelButton: {
    flex: 1,
    paddingVertical: spacing.lg,
    borderRadius: borderRadius.md,
    borderWidth: 1,
    borderColor: colors.border,
    alignItems: "center",
    backgroundColor: colors.glassBackground,
  },
  cancelButtonText: {
    fontSize: typography.fontSize.base,
    fontWeight: typography.fontWeight.semiBold,
    color: colors.textSecondary,
  },
  addButton: {
    flex: 1,
    paddingVertical: spacing.lg,
    borderRadius: borderRadius.md,
    alignItems: "center",
    backgroundColor: colors.gradientStart,
  },
  addButtonText: {
    fontSize: typography.fontSize.base,
    fontWeight: typography.fontWeight.semiBold,
    color: colors.textPrimary,
  },
  emptyContainer: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    paddingVertical: spacing["6xl"],
  },
  emptyIcon: {
    fontSize: 60,
    marginBottom: spacing["2xl"],
    opacity: 0.5,
  },
  emptyTitle: {
    fontSize: typography.fontSize.xl,
    fontWeight: typography.fontWeight.semiBold,
    color: colors.textSecondary,
    marginBottom: spacing.sm,
  },
  emptyDescription: {
    fontSize: typography.fontSize.base,
    fontWeight: typography.fontWeight.regular,
    color: colors.textSecondary,
    opacity: 0.7,
    textAlign: "center",
  },
  contactsList: {
    marginBottom: spacing["2xl"],
  },
  contactCard: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    padding: spacing["2xl"],
    borderRadius: borderRadius.md,
    borderWidth: 1,
    borderColor: colors.border,
    backgroundColor: colors.glassBackground,
    marginBottom: spacing.md,
  },
  contactInfo: {
    flex: 1,
  },
  contactName: {
    fontSize: typography.fontSize.base,
    fontWeight: typography.fontWeight.semiBold,
    color: colors.textPrimary,
    marginBottom: spacing.xs,
  },
  contactDetail: {
    fontSize: typography.fontSize.sm,
    fontWeight: typography.fontWeight.regular,
    color: colors.textSecondary,
    marginTop: spacing.xs,
  },
  removeButton: {
    paddingHorizontal: spacing["2xl"],
    paddingVertical: spacing.md,
    borderRadius: borderRadius.md,
    borderWidth: 1,
    borderColor: colors.textError,
    backgroundColor: colors.accentError,
  },
  removeButtonText: {
    fontSize: typography.fontSize.sm,
    fontWeight: typography.fontWeight.semiBold,
    color: colors.textError,
  },
  addButtonContainer: {
    marginTop: spacing["2xl"],
    marginBottom: spacing["4xl"],
  },
});

