# services/notification_service.py
"""
Service to check for free time in user's calendar and match with events
to send push notifications.
"""

from datetime import datetime, timedelta
from typing import List, Dict, Any, Optional
import logging

from services.calendar_service import fetch_today_events
from services.scrapers.engage_events_service import fetch_engage_events
from services.recommendation.quick_recommendations import EVENT_SOURCES

logger = logging.getLogger(__name__)


def parse_datetime(date_str: Optional[str]) -> Optional[datetime]:
    """Parse ISO datetime string to datetime object."""
    if not date_str:
        return None
    try:
        # Handle both with and without timezone
        if date_str.endswith('Z'):
            date_str = date_str[:-1] + '+00:00'
        return datetime.fromisoformat(date_str.replace('Z', '+00:00'))
    except Exception as e:
        logger.warning(f"Failed to parse datetime {date_str}: {e}")
        return None


def find_free_time_slots(calendar_events: List[Dict[str, Any]], 
                        start_time: datetime, 
                        end_time: datetime,
                        min_free_duration_minutes: int = 30) -> List[Dict[str, Any]]:
    """
    Find free time slots between calendar events.
    Returns list of {start, end, duration_minutes} for each free slot.
    """
    if not calendar_events:
        # No events = entire period is free
        duration = (end_time - start_time).total_seconds() / 60
        if duration >= min_free_duration_minutes:
            return [{
                "start": start_time.isoformat(),
                "end": end_time.isoformat(),
                "duration_minutes": duration
            }]
        return []
    
    # Parse and sort events by start time
    parsed_events = []
    for event in calendar_events:
        start = parse_datetime(event.get("start"))
        end = parse_datetime(event.get("end"))
        if start and end:
            parsed_events.append({"start": start, "end": end})
    
    parsed_events.sort(key=lambda x: x["start"])
    
    free_slots = []
    current_time = start_time
    
    for event in parsed_events:
        event_start = event["start"]
        event_end = event["end"]
        
        # If there's a gap before this event
        if current_time < event_start:
            gap_duration = (event_start - current_time).total_seconds() / 60
            if gap_duration >= min_free_duration_minutes:
                free_slots.append({
                    "start": current_time.isoformat(),
                    "end": event_start.isoformat(),
                    "duration_minutes": gap_duration
                })
        
        # Move current time to end of this event
        current_time = max(current_time, event_end)
    
    # Check for free time after last event
    if current_time < end_time:
        gap_duration = (end_time - current_time).total_seconds() / 60
        if gap_duration >= min_free_duration_minutes:
            free_slots.append({
                "start": current_time.isoformat(),
                "end": end_time.isoformat(),
                "duration_minutes": gap_duration
            })
    
    return free_slots


def find_matching_events(free_slot: Dict[str, Any], 
                        available_events: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """
    Find events that match a free time slot.
    An event matches if it starts during or shortly before the free slot.
    """
    slot_start = parse_datetime(free_slot["start"])
    slot_end = parse_datetime(free_slot["end"])
    
    if not slot_start or not slot_end:
        return []
    
    matching = []
    
    for event in available_events:
        event_start_str = event.get("start") or event.get("event_start")
        if not event_start_str:
            continue
        
        event_start = parse_datetime(event_start_str)
        if not event_start:
            continue
        
        # Event should start within the free slot, or up to 15 minutes before
        time_before_slot = (slot_start - event_start).total_seconds() / 60
        time_after_slot_start = (event_start - slot_start).total_seconds() / 60
        
        # Match if event starts:
        # - Up to 15 minutes before free slot starts (user can arrive early)
        # - Or during the free slot
        if -15 <= time_after_slot_start <= free_slot["duration_minutes"]:
            matching.append(event)
    
    return matching


def check_free_time_and_events(refresh_token: str, 
                               client_id: str, 
                               client_secret: str) -> List[Dict[str, Any]]:
    """
    Check user's calendar for free time and match with available events.
    Returns list of notifications to send: [{free_time, matching_events}]
    """
    try:
        # Fetch user's calendar events for today
        calendar_events = fetch_today_events(refresh_token, client_id, client_secret)
        
        # Define time window (now to end of day)
        now = datetime.utcnow()
        end_of_day = now.replace(hour=23, minute=59, second=59, microsecond=0)
        
        # Find free time slots (minimum 30 minutes)
        free_slots = find_free_time_slots(calendar_events, now, end_of_day, min_free_duration_minutes=30)
        
        if not free_slots:
            return []
        
        # Fetch available events (NYU Engage + external events)
        available_events = []
        try:
            # Get NYU Engage events
            engage_events = fetch_engage_events(days_ahead=1, limit=50)
            for ev in engage_events:
                available_events.append({
                    "title": ev.get("event_name") or ev.get("name"),
                    "start": ev.get("event_start") or ev.get("start") or ev.get("startDate"),
                    "description": ev.get("event_description") or ev.get("description"),
                    "location": ev.get("event_location") or ev.get("location") or ev.get("address"),
                    "type": "nyu_engage"
                })
        except Exception as e:
            logger.warning(f"Error fetching Engage events: {e}")
        
        try:
            # Get external events from scrapers
            for scraper_fn in EVENT_SOURCES:
                try:
                    scraped_events = scraper_fn(limit=30)
                    for ev in scraped_events:
                        available_events.append({
                            "title": ev.get("title") or ev.get("name"),
                            "start": ev.get("start"),
                            "description": ev.get("description"),
                            "location": ev.get("location"),
                            "type": "external"
                        })
                except Exception as e:
                    logger.warning(f"Error fetching from scraper: {e}")
        except Exception as e:
            logger.warning(f"Error fetching external events: {e}")
        
        # Match free slots with events
        notifications = []
        for free_slot in free_slots:
            matching_events = find_matching_events(free_slot, available_events)
            if matching_events:
                notifications.append({
                    "free_time": free_slot,
                    "events": matching_events
                })
        
        return notifications
        
    except Exception as e:
        logger.error(f"Error checking free time and events: {e}", exc_info=True)
        return []

