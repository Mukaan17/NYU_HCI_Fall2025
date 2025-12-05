// mobile/services/calendarService.ts
import { apiService } from "./apiService";
import { FreeTimeBlock, FreeTimeSuggestion, Recommendation } from "../types/dashboard";

export interface FreeTimeBlocksResponse {
  free_blocks: FreeTimeBlock[];
  error?: string;
}

export interface NextFreeBlockResponse {
  status: string;
  free_block: {
    start: string;
    end: string;
    duration_minutes: number;
  };
  error?: string;
}

export interface NextFreeRecommendationResponse {
  has_free_time: boolean;
  next_free: FreeTimeBlock;
  suggestion: {
    type: string;
    name: string;
    start?: string;
    location?: string;
    description?: string;
    address?: string;
    maps_link?: string;
    photo_url?: string;
  };
  suggestion_type: string;
  message: string;
  error?: string;
}

export interface FullRecommendationResponse {
  has_free_time: boolean;
  next_free: FreeTimeBlock;
  suggestion: {
    name: string;
    location?: string;
    description?: string;
    address?: string;
    maps_link?: string;
    photo_url?: string;
  };
  suggestion_type: string;
  message: string;
  error?: string;
}

class CalendarService {
  async getFreeTimeBlocks(token: string): Promise<FreeTimeBlocksResponse> {
    return apiService.get<FreeTimeBlocksResponse>("/api/calendar/free_time");
  }

  async getNextFreeBlock(token: string): Promise<NextFreeBlockResponse> {
    return apiService.get<NextFreeBlockResponse>("/api/calendar/next_free_block");
  }

  async getNextFreeWithRecommendation(token: string): Promise<NextFreeRecommendationResponse> {
    return apiService.get<NextFreeRecommendationResponse>("/api/calendar/next_free");
  }

  async getFullRecommendation(token: string): Promise<FullRecommendationResponse> {
    return apiService.get<FullRecommendationResponse>("/api/calendar/recommendation");
  }
}

export const calendarService = new CalendarService();
