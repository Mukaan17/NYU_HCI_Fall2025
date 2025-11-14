import React, { useState } from "react";
import { StyleSheet, Text, TextInput, View, ScrollView, TouchableOpacity, KeyboardAvoidingView } from "react-native";

export default function App() {
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState("");

  const sendMessage = async () => {
    if (!input.trim()) return;
    setMessages([...messages, { role: "user", content: input }]);
    try {
      const res = await fetch("http://YOUR_IP:5000/api/chat", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ mood: "chill", message: input }),
      });
      const data = await res.json();
      setMessages((prev) => [...prev, { role: "ai", content: data.reply || "..." }]);
    } catch {
      setMessages((prev) => [...prev, { role: "ai", content: "Server error." }]);
    }
    setInput("");
  };

  return (
    <KeyboardAvoidingView style={styles.container} behavior="padding">
      <ScrollView style={styles.chat}>
        {messages.map((m, i) => (
          <Text key={i} style={m.role === "user" ? styles.user : styles.ai}>
            {m.role === "user" ? "You: " : "NYightOut: "}
            {m.content}
          </Text>
        ))}
      </ScrollView>
      <View style={styles.row}>
        <TextInput
          style={styles.input}
          placeholder="Ask NYightOut..."
          placeholderTextColor="#999"
          value={input}
          onChangeText={setInput}
        />
        <TouchableOpacity onPress={sendMessage} style={styles.sendBtn}>
          <Text style={{ color: "#fff" }}>Send</Text>
        </TouchableOpacity>
      </View>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: "#111", paddingTop: 50 },
  chat: { flex: 1, padding: 10 },
  row: { flexDirection: "row", padding: 10 },
  input: { flex: 1, backgroundColor: "#333", color: "#fff", borderRadius: 10, paddingHorizontal: 10 },
  sendBtn: { backgroundColor: "#1e88e5", marginLeft: 8, borderRadius: 8, padding: 10 },
  user: { alignSelf: "flex-end", color: "#fff", backgroundColor: "#1e88e5", margin: 5, padding: 8, borderRadius: 8 },
  ai: { alignSelf: "flex-start", color: "#fff", backgroundColor: "#333", margin: 5, padding: 8, borderRadius: 8 },
});
