// mobile/services/apiService.ts
import AsyncStorage from "@react-native-async-storage/async-storage";

const AUTH_TOKEN_KEY = "authToken";
const BASE_URL = process.env.EXPO_PUBLIC_API_URL || "http://localhost:5001";
const REQUEST_TIMEOUT = 30000; // 30 seconds

export interface ApiError {
  message: string;
  status?: number;
  code?: string;
}

class ApiService {
  private baseURL: string;

  constructor() {
    this.baseURL = BASE_URL;
  }

  // Get JWT token from AsyncStorage
  async getAuthToken(): Promise<string | null> {
    try {
      return await AsyncStorage.getItem(AUTH_TOKEN_KEY);
    } catch (error) {
      console.error("Error getting auth token:", error);
      return null;
    }
  }

  // Set JWT token in AsyncStorage
  async setAuthToken(token: string): Promise<void> {
    try {
      await AsyncStorage.setItem(AUTH_TOKEN_KEY, token);
    } catch (error) {
      console.error("Error setting auth token:", error);
      throw error;
    }
  }

  // Clear JWT token from AsyncStorage
  async clearAuthToken(): Promise<void> {
    try {
      await AsyncStorage.removeItem(AUTH_TOKEN_KEY);
    } catch (error) {
      console.error("Error clearing auth token:", error);
    }
  }

  // Generic request method with authentication and error handling
  async request<T>(
    endpoint: string,
    options: RequestInit = {}
  ): Promise<T> {
    const token = await this.getAuthToken();

    const headers: HeadersInit = {
      "Content-Type": "application/json",
      ...options.headers,
    };

    // Add Authorization header if token exists
    if (token) {
      headers["Authorization"] = `Bearer ${token}`;
    }

    const url = `${this.baseURL}${endpoint}`;
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), REQUEST_TIMEOUT);

    try {
      const response = await fetch(url, {
        ...options,
        headers,
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      // Handle rate limiting (429)
      if (response.status === 429) {
        throw {
          message: "Rate limit exceeded. Please try again in a moment.",
          status: 429,
          code: "RATE_LIMIT",
        } as ApiError;
      }

      // Handle authentication errors (401)
      if (response.status === 401) {
        // Clear token on 401
        await this.clearAuthToken();
        throw {
          message: "Authentication required. Please log in again.",
          status: 401,
          code: "UNAUTHORIZED",
        } as ApiError;
      }

      // Handle other errors
      if (!response.ok) {
        let errorMessage = `Request failed with status ${response.status}`;
        try {
          const errorData = await response.json();
          errorMessage = errorData.error || errorData.message || errorMessage;
        } catch {
          // If response is not JSON, use status text
          errorMessage = response.statusText || errorMessage;
        }

        throw {
          message: errorMessage,
          status: response.status,
          code: "API_ERROR",
        } as ApiError;
      }

      // Parse JSON response
      const data = await response.json();
      return data as T;
    } catch (error) {
      clearTimeout(timeoutId);

      // Handle abort (timeout)
      if (error instanceof Error && error.name === "AbortError") {
        throw {
          message: "Request timeout. Please check your connection.",
          code: "TIMEOUT",
        } as ApiError;
      }

      // Handle network errors
      if (error instanceof TypeError && error.message.includes("fetch")) {
        throw {
          message: "Network error. Please check your connection.",
          code: "NETWORK_ERROR",
        } as ApiError;
      }

      // Re-throw ApiError
      if (error && typeof error === "object" && "message" in error) {
        throw error;
      }

      // Unknown error
      throw {
        message: error instanceof Error ? error.message : "Unknown error occurred",
        code: "UNKNOWN_ERROR",
      } as ApiError;
    }
  }

  // GET request helper
  async get<T>(endpoint: string, params?: Record<string, string | number>): Promise<T> {
    let url = endpoint;
    if (params) {
      const queryString = new URLSearchParams(
        Object.entries(params).reduce((acc, [key, value]) => {
          acc[key] = String(value);
          return acc;
        }, {} as Record<string, string>)
      ).toString();
      url += `?${queryString}`;
    }
    return this.request<T>(url, { method: "GET" });
  }

  // POST request helper
  async post<T>(endpoint: string, body?: any): Promise<T> {
    return this.request<T>(endpoint, {
      method: "POST",
      body: body ? JSON.stringify(body) : undefined,
    });
  }

  // PUT request helper
  async put<T>(endpoint: string, body?: any): Promise<T> {
    return this.request<T>(endpoint, {
      method: "PUT",
      body: body ? JSON.stringify(body) : undefined,
    });
  }

  // DELETE request helper
  async delete<T>(endpoint: string): Promise<T> {
    return this.request<T>(endpoint, { method: "DELETE" });
  }
}

// Export singleton instance
export const apiService = new ApiService();
