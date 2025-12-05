// mobile/utils/errorHandler.ts
import { ApiError } from "../services/apiService";

export interface UserFriendlyError {
  title: string;
  message: string;
  retryable: boolean;
}

/**
 * Maps API errors to user-friendly messages
 */
export function handleApiError(error: unknown): UserFriendlyError {
  if (error && typeof error === "object" && "message" in error) {
    const apiError = error as ApiError;

    // Rate limiting
    if (apiError.status === 429 || apiError.code === "RATE_LIMIT") {
      return {
        title: "Too Many Requests",
        message: "You're making requests too quickly. Please wait a moment and try again.",
        retryable: true,
      };
    }

    // Authentication errors
    if (apiError.status === 401 || apiError.code === "UNAUTHORIZED") {
      return {
        title: "Authentication Required",
        message: "Please log in again to continue.",
        retryable: false,
      };
    }

    // Network errors
    if (apiError.code === "NETWORK_ERROR" || apiError.code === "TIMEOUT") {
      return {
        title: "Connection Error",
        message: "Unable to connect to the server. Please check your internet connection.",
        retryable: true,
      };
    }

    // Server errors
    if (apiError.status && apiError.status >= 500) {
      return {
        title: "Server Error",
        message: "The server is experiencing issues. Please try again later.",
        retryable: true,
      };
    }

    // Client errors (400-499)
    if (apiError.status && apiError.status >= 400 && apiError.status < 500) {
      return {
        title: "Request Error",
        message: apiError.message || "Invalid request. Please check your input.",
        retryable: false,
      };
    }

    // Generic API error
    return {
      title: "Error",
      message: apiError.message || "An error occurred. Please try again.",
      retryable: true,
    };
  }

  // Unknown error
  if (error instanceof Error) {
    return {
      title: "Error",
      message: error.message || "An unexpected error occurred.",
      retryable: true,
    };
  }

  return {
    title: "Error",
    message: "An unexpected error occurred. Please try again.",
    retryable: true,
  };
}

/**
 * Retry a function with exponential backoff
 */
export async function retryWithBackoff<T>(
  fn: () => Promise<T>,
  maxRetries: number = 3,
  initialDelay: number = 1000
): Promise<T> {
  let lastError: unknown;

  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error;

      // Don't retry on authentication errors or client errors (4xx)
      if (error && typeof error === "object" && "status" in error) {
        const apiError = error as ApiError;
        if (apiError.status === 401 || (apiError.status && apiError.status >= 400 && apiError.status < 500)) {
          throw error;
        }
      }

      // If this is the last attempt, throw the error
      if (attempt === maxRetries - 1) {
        throw error;
      }

      // Wait before retrying (exponential backoff)
      const delay = initialDelay * Math.pow(2, attempt);
      await new Promise((resolve) => setTimeout(resolve, delay));
    }
  }

  throw lastError;
}
