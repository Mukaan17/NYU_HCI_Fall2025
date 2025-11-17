// mobile/context/ChatContext.tsx
import React, { createContext, useContext, useState } from "react";

export type Recommendation = {
  id: number;
  title: string;
  description?: string;
  distance?: string;
  walkTime?: string;
  lat?: number;
  lng?: number;
  popularity?: string | null;
};

export type TextMessage = {
  id: number;
  type: "text";
  role: "ai" | "user";
  content: string;
  timestamp: Date;
};

export type RecommendationsMessage = {
  id: number;
  type: "recommendations";
  role: "ai";
  recommendations: Recommendation[];
  timestamp: Date;
};

export type ChatMessage = TextMessage | RecommendationsMessage;

type ChatContextType = {
  messages: ChatMessage[];
  setMessages: React.Dispatch<React.SetStateAction<ChatMessage[]>>;
};

const ChatContext = createContext<ChatContextType | undefined>(undefined);

type ChatProviderProps = {
  children: React.ReactNode;
};

export const ChatProvider: React.FC<ChatProviderProps> = ({ children }) => {
  const [messages, setMessages] = useState<ChatMessage[]>([
    {
      id: 1,
      type: "text",
      role: "ai",
      content:
        "Hey Tandon! I'm VioletVibes. Tell me what you're in the mood for — drinks, food, coffee, or something fun.",
      timestamp: new Date(),
    },
  ]);

  return (
    <ChatContext.Provider value={{ messages, setMessages }}>
      {children}
    </ChatContext.Provider>
  );
};

export function useChat() {
  const ctx = useContext(ChatContext);
  if (!ctx) {
    throw new Error("useChat must be used within a ChatProvider");
  }
  return ctx;
}

