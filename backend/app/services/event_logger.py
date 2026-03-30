"""Server-side event logger — writes to app_events table.

Use this instead of (or in addition to) Mixpanel for metrics you own.
Every event here feeds the DAU/MAU/retention/funnel analytics endpoints.
"""

import logging
import uuid
from typing import Any

from sqlalchemy.ext.asyncio import AsyncSession

from app.models.app_event import AppEvent

logger = logging.getLogger("toolor")


async def log_event(
    db: AsyncSession,
    user_id: uuid.UUID | None,
    event: str,
    properties: dict[str, Any] | None = None,
) -> None:
    """Write an analytics event. Non-blocking — errors are logged, not raised."""
    try:
        db.add(AppEvent(user_id=user_id, event=event, properties=properties))
        await db.flush()
    except Exception as e:
        logger.warning(f"Event log failed ({event}): {e}")
