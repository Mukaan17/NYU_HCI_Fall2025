// mobile/context/AuthContext.tsx
import React, { createContext, useContext, useState, useEffect, useCallback } from "react";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { apiService, ApiError } from "../services/apiService";

export interface User {
  id: number;
  email: string;
  first_name?: string;
  home_address?: string;
  preferences?: any;
  settings?: any;
}

interface AuthResponse {
  token: string;
  user: User;
}

interface AuthContextType {
  isAuthenticated: boolean;
  token: string | null;
  user: User | null;
  isLoading: boolean;
  login: (email: string, password: string) => Promise<void>;
  signup: (email: string, password: string, firstName?: string) => Promise<void>;
  logout: () => Promise<void>;
  refreshToken: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [token, setToken] = useState<string | null>(null);
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  // Load token from storage on mount
  useEffect(() => {
    const loadToken = async () => {
      try {
        const storedToken = await apiService.getAuthToken();
        if (storedToken) {
          setToken(storedToken);
          // Optionally verify token and load user data
          // For now, just set the token
        }
      } catch (error) {
        console.error("Error loading token:", error);
      } finally {
        setIsLoading(false);
      }
    };

    loadToken();
  }, []);

  const login = useCallback(async (email: string, password: string) => {
    try {
      const response = await apiService.post<AuthResponse>("/api/auth/login", {
        email,
        password,
      });

      await apiService.setAuthToken(response.token);
      setToken(response.token);
      setUser(response.user);
    } catch (error) {
      const apiError = error as ApiError;
      throw new Error(apiError.message || "Login failed");
    }
  }, []);

  const signup = useCallback(async (email: string, password: string, firstName?: string) => {
    try {
      const payload: any = { email, password };
      if (firstName) {
        payload.first_name = firstName;
      }

      const response = await apiService.post<AuthResponse>("/api/auth/signup", payload);

      await apiService.setAuthToken(response.token);
      setToken(response.token);
      setUser(response.user);
    } catch (error) {
      const apiError = error as ApiError;
      throw new Error(apiError.message || "Signup failed");
    }
  }, []);

  const logout = useCallback(async () => {
    try {
      await apiService.clearAuthToken();
      setToken(null);
      setUser(null);
      // Also clear other user data
      await AsyncStorage.removeItem("userAccount");
      await AsyncStorage.removeItem("hasLoggedIn");
    } catch (error) {
      console.error("Error during logout:", error);
      // Still clear local state even if storage fails
      setToken(null);
      setUser(null);
    }
  }, []);

  const refreshToken = useCallback(async () => {
    // Token refresh logic if backend supports it
    // For now, just verify token is still valid
    if (!token) {
      return;
    }

    try {
      // Could call a token refresh endpoint here
      // For now, just check if token exists
      const storedToken = await apiService.getAuthToken();
      if (!storedToken) {
        await logout();
      }
    } catch (error) {
      console.error("Error refreshing token:", error);
      await logout();
    }
  }, [token, logout]);

  const value: AuthContextType = {
    isAuthenticated: !!token,
    token,
    user,
    isLoading,
    login,
    signup,
    logout,
    refreshToken,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
}
