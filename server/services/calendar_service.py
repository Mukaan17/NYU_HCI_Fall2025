# services/calendar_service.py
#
# ⚠️ DEPRECATED: This file contains legacy Google Calendar code that is NO LONGER USED.
# The app now uses system calendar (handled entirely client-side on iOS using EventKit).
# 
# This file is kept for reference only. All Google Calendar functionality has been removed.
# System calendar data is managed entirely by the iOS app - the backend does not fetch calendar events.
#
# If you need calendar functionality, use the system calendar on the client side.

from datetime import datetime, timedelta
import pytz
import logging

logger = logging.getLogger(__name__)

# Google Calendar imports removed - system calendar is used instead
# All functions below are deprecated and should not be called


def get_today_times():
    """Return RFC-3339 timestamps for now → midnight."""
    now = datetime.utcnow()
    end_of_day = datetime.utcnow().replace(hour=23, minute=59, second=59, microsecond=0)

    return (
        now.isoformat() + "Z",
        end_of_day.isoformat() + "Z"
    )


def refresh_google_token(refresh_token: str, client_id: str, client_secret: str):
    """
    ⚠️ DEPRECATED: Google Calendar is no longer used.
    System calendar is handled client-side on iOS.
    This function will raise NotImplementedError if called.
    """
    logger.error("refresh_google_token called but Google Calendar is deprecated - use system calendar instead")
    raise NotImplementedError("Google Calendar is no longer supported. Use system calendar (client-side).")


def fetch_today_events(refresh_token: str, client_id: str, client_secret: str):
    """
    ⚠️ DEPRECATED: Google Calendar is no longer used.
    System calendar is handled client-side on iOS.
    This function will raise NotImplementedError if called.
    """
    logger.error("fetch_today_events called but Google Calendar is deprecated - use system calendar instead")
    raise NotImplementedError("Google Calendar is no longer supported. Use system calendar (client-side).")


def parse_google_datetime(dt_str):
    """
    Safely parses Google Calendar RFC3339/ISO datetime strings.
    Handles timezone offsets and microseconds.
    """
    try:
        return datetime.fromisoformat(dt_str)
    except ValueError:
        # e.g. "2025-02-11T13:00:00-05:00"
        try:
            return datetime.strptime(dt_str, "%Y-%m-%dT%H:%M:%S%z")
        except Exception as e:
            logger.warning(f"Failed parsing datetime: {dt_str} - {e}")
            return None


def fetch_free_time_blocks(refresh_token, client_id, client_secret):
    """
    ⚠️ DEPRECATED: Google Calendar is no longer used.
    System calendar is handled client-side on iOS.
    Free time blocks are calculated on the client using EventKit.
    This function will raise NotImplementedError if called.
    """
    logger.error("fetch_free_time_blocks called but Google Calendar is deprecated - use system calendar instead")
    raise NotImplementedError("Google Calendar is no longer supported. Use system calendar (client-side).")
