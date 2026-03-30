"""Investor-grade analytics endpoints.

Provides DAU, WAU, MAU, retention, ARPU, LTV, funnels, cohorts,
and growth rates — all from the app_events + orders tables.
"""

from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select, func, distinct, case, text, and_
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import get_db, require_admin
from app.models.app_event import AppEvent
from app.models.order import Order
from app.models.user import Profile
from app.models.loyalty import LoyaltyAccount

router = APIRouter()


@router.get("/analytics/overview", dependencies=[Depends(require_admin)])
async def analytics_overview(
    days: int = Query(30, ge=1, le=365),
    db: AsyncSession = Depends(get_db),
):
    """High-level metrics investors care about."""
    now = datetime.now(timezone.utc)
    since = now - timedelta(days=days)
    yesterday = now - timedelta(days=1)
    prev_start = since - timedelta(days=days)  # previous period for comparison
    paid = ["payment_confirmed", "processing", "shipped", "delivered", "ready_for_pickup"]

    # ── Total users ──────────────────────────────────────────────────────
    total_users = (await db.execute(select(func.count(Profile.id)))).scalar() or 0
    new_users_period = (await db.execute(
        select(func.count(Profile.id)).where(Profile.created_at >= since)
    )).scalar() or 0
    new_users_prev = (await db.execute(
        select(func.count(Profile.id)).where(
            Profile.created_at >= prev_start, Profile.created_at < since
        )
    )).scalar() or 0
    user_growth_pct = (
        round((new_users_period - new_users_prev) / new_users_prev * 100, 1)
        if new_users_prev > 0 else 0
    )

    # ── DAU (from app_events) ────────────────────────────────────────────
    dau_q = (
        select(
            func.date_trunc("day", AppEvent.created_at).label("day"),
            func.count(distinct(AppEvent.user_id)).label("users"),
        )
        .where(AppEvent.created_at >= since, AppEvent.user_id.isnot(None))
        .group_by(text("1"))
    )
    dau_rows = (await db.execute(dau_q)).all()
    dau_series = [{"date": str(r.day.date()), "users": r.users} for r in dau_rows]
    avg_dau = round(sum(r.users for r in dau_rows) / len(dau_rows), 1) if dau_rows else 0

    # ── WAU (unique users in last 7 days) ────────────────────────────────
    wau = (await db.execute(
        select(func.count(distinct(AppEvent.user_id))).where(
            AppEvent.created_at >= now - timedelta(days=7),
            AppEvent.user_id.isnot(None),
        )
    )).scalar() or 0

    # ── MAU (unique users in last 30 days) ───────────────────────────────
    mau = (await db.execute(
        select(func.count(distinct(AppEvent.user_id))).where(
            AppEvent.created_at >= now - timedelta(days=30),
            AppEvent.user_id.isnot(None),
        )
    )).scalar() or 0

    # ── DAU/MAU ratio (stickiness) ───────────────────────────────────────
    stickiness = round(avg_dau / mau * 100, 1) if mau > 0 else 0

    # ── Revenue metrics ──────────────────────────────────────────────────
    revenue = float((await db.execute(
        select(func.coalesce(func.sum(Order.total), 0)).where(
            Order.created_at >= since, Order.status.in_(paid)
        )
    )).scalar())

    revenue_prev = float((await db.execute(
        select(func.coalesce(func.sum(Order.total), 0)).where(
            Order.created_at >= prev_start, Order.created_at < since,
            Order.status.in_(paid),
        )
    )).scalar())

    revenue_growth_pct = (
        round((revenue - revenue_prev) / revenue_prev * 100, 1)
        if revenue_prev > 0 else 0
    )

    paid_orders = (await db.execute(
        select(func.count(Order.id)).where(
            Order.created_at >= since, Order.status.in_(paid)
        )
    )).scalar() or 0

    # ── AOV (Average Order Value) ────────────────────────────────────────
    aov_raw = (await db.execute(
        select(func.avg(Order.total)).where(
            Order.created_at >= since, Order.status.in_(paid)
        )
    )).scalar()
    aov = round(float(aov_raw), 0) if aov_raw else 0

    # ── ARPU (Average Revenue Per User) ──────────────────────────────────
    arpu = round(revenue / mau, 0) if mau > 0 else 0

    # ── Buyers & conversion ──────────────────────────────────────────────
    buyers = (await db.execute(
        select(func.count(distinct(Order.user_id))).where(
            Order.created_at >= since, Order.status.in_(paid)
        )
    )).scalar() or 0

    conversion_rate = round(buyers / new_users_period * 100, 1) if new_users_period > 0 else 0

    # ── Repeat purchase rate ─────────────────────────────────────────────
    repeat_q = select(func.count()).select_from(
        select(Order.user_id)
        .where(Order.created_at >= since, Order.status.in_(paid))
        .group_by(Order.user_id)
        .having(func.count(Order.id) >= 2)
        .subquery()
    )
    repeat_buyers = (await db.execute(repeat_q)).scalar() or 0
    repeat_rate = round(repeat_buyers / buyers * 100, 1) if buyers > 0 else 0

    # ── Loyalty distribution ─────────────────────────────────────────────
    tier_dist = (await db.execute(
        select(LoyaltyAccount.tier, func.count(LoyaltyAccount.id))
        .group_by(LoyaltyAccount.tier)
    )).all()
    tier_distribution = {r[0]: r[1] for r in tier_dist}

    # ── Revenue time series (daily) ──────────────────────────────────────
    rev_series_q = (
        select(
            func.date_trunc("day", Order.created_at).label("day"),
            func.coalesce(func.sum(Order.total), 0).label("revenue"),
            func.count(Order.id).label("orders"),
        )
        .where(Order.created_at >= since, Order.status.in_(paid))
        .group_by(text("1"))
        .order_by(text("1"))
    )
    rev_rows = (await db.execute(rev_series_q)).all()
    revenue_series = [
        {"date": str(r.day.date()), "revenue": float(r.revenue), "orders": r.orders}
        for r in rev_rows
    ]

    # ── New users time series ────────────────────────────────────────────
    signup_series_q = (
        select(
            func.date_trunc("day", Profile.created_at).label("day"),
            func.count(Profile.id).label("signups"),
        )
        .where(Profile.created_at >= since)
        .group_by(text("1"))
        .order_by(text("1"))
    )
    signup_rows = (await db.execute(signup_series_q)).all()
    signup_series = [
        {"date": str(r.day.date()), "signups": r.signups}
        for r in signup_rows
    ]

    return {
        "period_days": days,
        # User metrics
        "total_users": total_users,
        "new_users": new_users_period,
        "user_growth_pct": user_growth_pct,
        # Activity
        "dau": avg_dau,
        "wau": wau,
        "mau": mau,
        "stickiness_pct": stickiness,
        # Revenue
        "revenue": revenue,
        "revenue_growth_pct": revenue_growth_pct,
        "paid_orders": paid_orders,
        "aov": aov,
        "arpu": arpu,
        # Conversion
        "buyers": buyers,
        "conversion_rate_pct": conversion_rate,
        "repeat_purchase_rate_pct": repeat_rate,
        "repeat_buyers": repeat_buyers,
        # Distribution
        "tier_distribution": tier_distribution,
        # Time series
        "dau_series": dau_series,
        "revenue_series": revenue_series,
        "signup_series": signup_series,
    }


@router.get("/analytics/retention", dependencies=[Depends(require_admin)])
async def analytics_retention(
    db: AsyncSession = Depends(get_db),
):
    """Cohort retention: D1, D7, D30 retention rates for recent cohorts.

    A user is 'retained' on day N if they have an app_event on that day
    relative to their signup date.
    """
    now = datetime.now(timezone.utc)

    # Get weekly cohorts from the last 8 weeks
    cohorts = []
    for weeks_ago in range(8):
        cohort_start = now - timedelta(weeks=weeks_ago + 1)
        cohort_end = now - timedelta(weeks=weeks_ago)

        # Users who signed up in this week
        cohort_users_q = select(Profile.id).where(
            Profile.created_at >= cohort_start,
            Profile.created_at < cohort_end,
        )
        cohort_users = (await db.execute(
            select(func.count()).select_from(cohort_users_q.subquery())
        )).scalar() or 0

        if cohort_users == 0:
            cohorts.append({
                "cohort_week": str(cohort_start.date()),
                "users": 0,
                "d1": 0, "d7": 0, "d30": 0,
            })
            continue

        # For each retention day, count users who had an event
        retention = {}
        for label, offset in [("d1", 1), ("d7", 7), ("d30", 30)]:
            target_start = cohort_start + timedelta(days=offset)
            target_end = target_start + timedelta(days=1)

            if target_end > now:
                retention[label] = None  # not enough time has passed
                continue

            retained = (await db.execute(
                select(func.count(distinct(AppEvent.user_id))).where(
                    AppEvent.user_id.in_(cohort_users_q),
                    AppEvent.created_at >= target_start,
                    AppEvent.created_at < target_end,
                )
            )).scalar() or 0

            retention[label] = round(retained / cohort_users * 100, 1)

        cohorts.append({
            "cohort_week": str(cohort_start.date()),
            "users": cohort_users,
            **retention,
        })

    return {"cohorts": cohorts}


@router.get("/analytics/funnel", dependencies=[Depends(require_admin)])
async def analytics_funnel(
    days: int = Query(30, ge=1, le=365),
    db: AsyncSession = Depends(get_db),
):
    """Conversion funnel: signup → product_view → add_to_cart → purchase."""
    now = datetime.now(timezone.utc)
    since = now - timedelta(days=days)

    steps = ["signup", "login", "product_view", "add_to_cart", "purchase"]
    funnel = []

    for step in steps:
        count = (await db.execute(
            select(func.count(distinct(AppEvent.user_id))).where(
                AppEvent.event == step,
                AppEvent.created_at >= since,
                AppEvent.user_id.isnot(None),
            )
        )).scalar() or 0
        funnel.append({"step": step, "unique_users": count})

    # Add drop-off rates
    for i in range(1, len(funnel)):
        prev = funnel[i - 1]["unique_users"]
        curr = funnel[i]["unique_users"]
        funnel[i]["conversion_from_prev_pct"] = (
            round(curr / prev * 100, 1) if prev > 0 else 0
        )

    return {"period_days": days, "funnel": funnel}


@router.get("/analytics/events", dependencies=[Depends(require_admin)])
async def analytics_events(
    days: int = Query(7, ge=1, le=90),
    db: AsyncSession = Depends(get_db),
):
    """Event volume breakdown — how many of each event type per day."""
    now = datetime.now(timezone.utc)
    since = now - timedelta(days=days)

    q = (
        select(
            AppEvent.event,
            func.date_trunc("day", AppEvent.created_at).label("day"),
            func.count(AppEvent.id).label("count"),
        )
        .where(AppEvent.created_at >= since)
        .group_by(AppEvent.event, text("2"))
        .order_by(text("2"))
    )
    rows = (await db.execute(q)).all()

    # Group by event name
    events: dict[str, list] = {}
    for r in rows:
        events.setdefault(r.event, []).append({
            "date": str(r.day.date()),
            "count": r.count,
        })

    # Totals
    totals_q = (
        select(AppEvent.event, func.count(AppEvent.id).label("total"))
        .where(AppEvent.created_at >= since)
        .group_by(AppEvent.event)
        .order_by(func.count(AppEvent.id).desc())
    )
    totals = {r.event: r.total for r in (await db.execute(totals_q)).all()}

    return {"period_days": days, "event_totals": totals, "event_series": events}
