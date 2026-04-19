# Guest Mode + Anonymous Tracking — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let guests browse the app freely; gate personal actions (loyalty QR, checkout, favorites, promo) behind login; track guest activity server-side under a device-bound anonymous identity and merge it into the real customer on registration.

**Architecture:** Backend adds two tables (`guest_sessions`, `customer_events`), guest JWTs, event ingestion endpoint, and a merge service run atomically inside `verify-otp`. Frontend bootstraps a guest JWT on first launch, switches Dio auth header based on available token, drops the welcome-screen short-circuit, gates restricted actions with direct `Navigator.push(AuthScreen)`, and flushes analytics events in batches.

**Tech Stack:**
- Backend: FastAPI, SQLAlchemy (async), Alembic, pytest, pyjwt
- Frontend: Flutter 3.x, Dio, Provider, `shared_preferences`, `flutter_secure_storage`
- Two repositories:
  - **Backend repo:** `/Users/izzat/PycharmProjects/cool group/backend`
  - **Frontend repo:** `/Users/izzat/PycharmProjects/LoyaltyToolor`

**Spec:** `docs/superpowers/specs/2026-04-14-guest-mode-design.md` (LoyaltyToolor repo)

---

## File Structure

### Backend (`/Users/izzat/PycharmProjects/cool group/backend`)

- **New**
  - `migrations/versions/054_guest_sessions_and_customer_events.py` — Alembic migration
  - `app/customers/guest_models.py` — `GuestSession`, `CustomerEvent` ORM models (kept out of `customers/models.py` to keep that file focused on the Customer aggregate)
  - `app/customers/guest_router.py` — `POST /api/me/guest/init`
  - `app/customers/events_router.py` — `POST /api/me/events`
  - `app/customers/merge_service.py` — `merge_guest_into_customer`
  - `tests/test_phase16_guest_mode.py` — new test module
- **Modified**
  - `app/auth/security.py` — `create_guest_token`, `decode_guest_token`
  - `app/auth/dependencies.py` — `get_current_guest`, `get_current_actor`, `Actor` dataclass
  - `app/auth/customer_router.py` — extend `VerifyOtpBody` with `guest_id`, call merge service
  - `app/main.py` — include new routers

### Frontend (`/Users/izzat/PycharmProjects/LoyaltyToolor`)

- **New**
  - `lib/services/device_id_service.dart` — device_id generate/load
  - `lib/services/analytics_service.dart` — event queue, batch flush
  - `lib/widgets/guest_cta_card.dart` — compact CTA card shown to guests on home
- **Modified**
  - `lib/services/api_service.dart` — guest token storage, `bootstrapGuest()`, interceptor update
  - `lib/providers/auth_provider.dart` — pass `guest_id` on verify, preserve guest token on logout
  - `lib/providers/cart_provider.dart` — SharedPreferences persistence for guest cart + `syncLocalCartToServer`
  - `lib/screens/home_screen.dart` — delete `_welcome`, always render `_home`, show guest CTA instead of loyalty card when guest
  - `lib/main.dart` — call `bootstrapGuest`, bottom-nav gate for QR tab, post-login cart sync
  - `lib/screens/auth_screen.dart` — `Navigator.pop(true)` on successful login
  - `lib/screens/cart_screen.dart` — checkout gate
  - `lib/screens/product_detail_screen.dart` — analytics track + favorite gate
  - `lib/screens/catalog_screen.dart` — category + search analytics
  - `lib/screens/promo_codes_screen.dart` — in-screen guest guard
  - `lib/widgets/product_card.dart` (or wherever favorite button lives — verify during Task F1)

---

## Task order

Phase A (backend foundation) → Phase B (backend events + merge) → Phase C (frontend bootstrap) → Phase D (frontend gating) → Phase E (frontend analytics) → Phase F (frontend cart sync + login wiring) → Phase G (manual QA).

Backend phases (A, B) can merge independently of frontend phases. Frontend phases C–F depend on backend being deployed to the dev environment.

---

## Phase A — Backend foundation

### Task A1: Alembic migration for `guest_sessions` and `customer_events`

**Files:**
- Create: `/Users/izzat/PycharmProjects/cool group/backend/migrations/versions/054_guest_sessions_and_customer_events.py`

- [ ] **Step 1: Create the migration file**

```python
"""guest_sessions and customer_events

Revision ID: 054_guest_mode
Revises: 053_location_photo_and_delivery_fields
Create Date: 2026-04-14

"""
from __future__ import annotations

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "054_guest_mode"
down_revision = "053_location_photo_and_delivery_fields"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "guest_sessions",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            primary_key=True,
            server_default=sa.text("gen_random_uuid()"),
        ),
        sa.Column("device_id", sa.String(64), nullable=False),
        sa.Column("platform", sa.String(20), nullable=True),
        sa.Column("app_version", sa.String(20), nullable=True),
        sa.Column("locale", sa.String(5), nullable=True),
        sa.Column(
            "first_seen_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("now()"),
        ),
        sa.Column(
            "last_seen_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("now()"),
        ),
        sa.Column(
            "merged_to_customer_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("customers.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("merged_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index(
        "ix_guest_sessions_device_id",
        "guest_sessions",
        ["device_id"],
        unique=True,
    )
    op.create_index(
        "ix_guest_sessions_merged_to_customer_id",
        "guest_sessions",
        ["merged_to_customer_id"],
    )

    op.create_table(
        "customer_events",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            primary_key=True,
            server_default=sa.text("gen_random_uuid()"),
        ),
        sa.Column("actor_type", sa.String(10), nullable=False),
        sa.Column("actor_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("session_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("event_type", sa.String(50), nullable=False),
        sa.Column(
            "payload",
            postgresql.JSONB(astext_type=sa.Text()),
            nullable=False,
            server_default=sa.text("'{}'::jsonb"),
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("now()"),
        ),
        sa.CheckConstraint(
            "actor_type IN ('guest','customer')",
            name="ck_customer_events_actor_type",
        ),
    )
    op.create_index(
        "ix_customer_events_actor",
        "customer_events",
        ["actor_id", "created_at"],
    )
    op.create_index(
        "ix_customer_events_event_type",
        "customer_events",
        ["event_type", "created_at"],
    )
    op.create_index(
        "ix_customer_events_session_id",
        "customer_events",
        ["session_id"],
    )


def downgrade() -> None:
    op.drop_index("ix_customer_events_session_id", table_name="customer_events")
    op.drop_index("ix_customer_events_event_type", table_name="customer_events")
    op.drop_index("ix_customer_events_actor", table_name="customer_events")
    op.drop_table("customer_events")
    op.drop_index(
        "ix_guest_sessions_merged_to_customer_id", table_name="guest_sessions"
    )
    op.drop_index("ix_guest_sessions_device_id", table_name="guest_sessions")
    op.drop_table("guest_sessions")
```

- [ ] **Step 2: Verify migration identifier**

Before assuming `053_location_photo_and_delivery_fields` is the current head, run:

```bash
cd "/Users/izzat/PycharmProjects/cool group/backend" && alembic heads
```

Expected: one line containing `053_location_photo_and_delivery_fields (head)` or the actual ID used in that file. If the revision ID differs, update `down_revision` to match exactly.

- [ ] **Step 3: Apply migration against the dev DB**

```bash
cd "/Users/izzat/PycharmProjects/cool group/backend" && alembic upgrade head
```

Expected: `INFO  [alembic.runtime.migration] Running upgrade 053_... -> 054_guest_mode`.

- [ ] **Step 4: Verify tables exist**

```bash
cd "/Users/izzat/PycharmProjects/cool group/backend" && python -c "
import asyncio
from sqlalchemy import text
from app.database import engine

async def main():
    async with engine.connect() as c:
        for t in ('guest_sessions','customer_events'):
            r = await c.execute(text(f\"SELECT 1 FROM information_schema.tables WHERE table_name='{t}'\"))
            print(t, 'ok' if r.first() else 'MISSING')
asyncio.run(main())
"
```

Expected: `guest_sessions ok` and `customer_events ok`.

- [ ] **Step 5: Commit**

```bash
cd "/Users/izzat/PycharmProjects/cool group/backend" && \
git add migrations/versions/054_guest_sessions_and_customer_events.py && \
git commit -m "feat(guest-mode): add guest_sessions and customer_events tables"
```

---

### Task A2: ORM models for `GuestSession` and `CustomerEvent`

**Files:**
- Create: `/Users/izzat/PycharmProjects/cool group/backend/app/customers/guest_models.py`
- Modify: `/Users/izzat/PycharmProjects/cool group/backend/app/customers/__init__.py` (if it re-exports models)

- [ ] **Step 1: Write the models file**

```python
"""Guest sessions and customer events — see
docs spec 2026-04-14-guest-mode-design.md.
"""
from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import (
    CheckConstraint,
    DateTime,
    ForeignKey,
    String,
)
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.sql import func

from app.database import Base


class GuestSession(Base):
    __tablename__ = "guest_sessions"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    device_id: Mapped[str] = mapped_column(
        String(64), nullable=False, unique=True
    )
    platform: Mapped[str | None] = mapped_column(String(20), nullable=True)
    app_version: Mapped[str | None] = mapped_column(String(20), nullable=True)
    locale: Mapped[str | None] = mapped_column(String(5), nullable=True)
    first_seen_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    last_seen_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
        onupdate=func.now(),
    )
    merged_to_customer_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("customers.id", ondelete="SET NULL"),
        nullable=True,
    )
    merged_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )


class CustomerEvent(Base):
    __tablename__ = "customer_events"
    __table_args__ = (
        CheckConstraint(
            "actor_type IN ('guest','customer')",
            name="ck_customer_events_actor_type",
        ),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    actor_type: Mapped[str] = mapped_column(String(10), nullable=False)
    actor_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), nullable=False)
    session_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), nullable=False)
    event_type: Mapped[str] = mapped_column(String(50), nullable=False)
    payload: Mapped[dict] = mapped_column(
        JSONB, nullable=False, default=dict, server_default="{}"
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
```

- [ ] **Step 2: Make sure models are imported so SQLAlchemy sees them**

Check `app/database.py` or `app/main.py` for a module that imports all models at startup. Add an import of `app.customers.guest_models` next to the existing model imports. If `app/customers/__init__.py` already does `from .models import *`, add `from .guest_models import GuestSession, CustomerEvent` there.

- [ ] **Step 3: Run a smoke import**

```bash
cd "/Users/izzat/PycharmProjects/cool group/backend" && \
python -c "from app.customers.guest_models import GuestSession, CustomerEvent; print(GuestSession.__tablename__, CustomerEvent.__tablename__)"
```

Expected: `guest_sessions customer_events`

- [ ] **Step 4: Commit**

```bash
cd "/Users/izzat/PycharmProjects/cool group/backend" && \
git add app/customers/guest_models.py app/customers/__init__.py && \
git commit -m "feat(guest-mode): add GuestSession and CustomerEvent ORM models"
```

---

### Task A3: Guest token helpers in `security.py`

**Files:**
- Modify: `/Users/izzat/PycharmProjects/cool group/backend/app/auth/security.py`
- Test: `/Users/izzat/PycharmProjects/cool group/backend/tests/test_phase16_guest_mode.py`

- [ ] **Step 1: Read the existing security module**

Open `app/auth/security.py` and find the existing `create_customer_access_token` + `decode_customer_refresh_token` functions. The guest helpers must use the same JWT secret/algorithm configuration. Note the exact helper names and settings keys used for customers.

- [ ] **Step 2: Write the failing test**

Create `tests/test_phase16_guest_mode.py`:

```python
"""Phase 16 — guest mode tests."""
from __future__ import annotations

import uuid

import pytest


def test_create_and_decode_guest_token_roundtrip():
    from app.auth.security import create_guest_token, decode_guest_token

    session_id = uuid.uuid4()
    token = create_guest_token(session_id)
    payload = decode_guest_token(token)

    assert payload is not None
    assert payload["sub"] == str(session_id)
    assert payload["type"] == "guest"


def test_decode_guest_token_rejects_customer_token():
    from app.auth.security import (
        create_customer_access_token,
        decode_guest_token,
    )

    customer_id = uuid.uuid4()
    customer_tok = create_customer_access_token(customer_id)
    assert decode_guest_token(customer_tok) is None


def test_decode_guest_token_rejects_garbage():
    from app.auth.security import decode_guest_token

    assert decode_guest_token("not-a-token") is None
```

- [ ] **Step 3: Run the test to see it fail**

```bash
cd "/Users/izzat/PycharmProjects/cool group/backend" && \
pytest tests/test_phase16_guest_mode.py::test_create_and_decode_guest_token_roundtrip -x
```

Expected: `ImportError: cannot import name 'create_guest_token'`.

- [ ] **Step 4: Implement the helpers**

At the bottom of `app/auth/security.py`, add (mirroring the customer variant — adapt to the exact secret/alg used in that file):

```python
GUEST_TOKEN_TTL_SECONDS = 60 * 60 * 24 * 90  # 90 days


def create_guest_token(session_id: uuid.UUID) -> str:
    import jwt
    from datetime import datetime, timedelta, timezone

    now = datetime.now(timezone.utc)
    payload = {
        "sub": str(session_id),
        "type": "guest",
        "iat": int(now.timestamp()),
        "exp": int((now + timedelta(seconds=GUEST_TOKEN_TTL_SECONDS)).timestamp()),
    }
    return jwt.encode(
        payload,
        settings.customer_jwt_secret,  # use whatever variable customer tokens use
        algorithm="HS256",
    )


def decode_guest_token(token: str) -> dict | None:
    import jwt

    try:
        payload = jwt.decode(
            token,
            settings.customer_jwt_secret,
            algorithms=["HS256"],
        )
    except jwt.PyJWTError:
        return None
    if payload.get("type") != "guest":
        return None
    return payload
```

Replace `settings.customer_jwt_secret` with the actual settings name already used by `create_customer_access_token` (check the file — common names: `settings.customer_access_token_secret`, `settings.jwt_secret_key`). Same for the algorithm. Do **not** introduce new settings keys.

Add `import uuid` at the top if not already present.

- [ ] **Step 5: Run tests**

```bash
cd "/Users/izzat/PycharmProjects/cool group/backend" && \
pytest tests/test_phase16_guest_mode.py -x -k "guest_token"
```

Expected: 3 passed.

- [ ] **Step 6: Commit**

```bash
cd "/Users/izzat/PycharmProjects/cool group/backend" && \
git add app/auth/security.py tests/test_phase16_guest_mode.py && \
git commit -m "feat(guest-mode): add create/decode guest token helpers"
```

---

### Task A4: `get_current_guest` and `get_current_actor` dependencies

**Files:**
- Modify: `/Users/izzat/PycharmProjects/cool group/backend/app/auth/dependencies.py`
- Test: `/Users/izzat/PycharmProjects/cool group/backend/tests/test_phase16_guest_mode.py`

- [ ] **Step 1: Append tests**

Append to `tests/test_phase16_guest_mode.py`:

```python
@pytest.mark.asyncio
async def test_get_current_actor_with_guest_token(db_session):
    from app.auth.dependencies import get_current_actor
    from app.auth.security import create_guest_token
    from app.customers.guest_models import GuestSession

    gs = GuestSession(device_id="dev-test-1", platform="ios")
    db_session.add(gs)
    await db_session.flush()

    token = create_guest_token(gs.id)

    class _Req:
        headers = {"authorization": f"Bearer {token}"}

    actor = await get_current_actor(_Req(), db_session)
    assert actor.type == "guest"
    assert actor.id == gs.id


@pytest.mark.asyncio
async def test_get_current_actor_with_customer_token(db_session, sample_customer):
    from app.auth.dependencies import get_current_actor
    from app.auth.security import create_customer_access_token

    token = create_customer_access_token(sample_customer.id)

    class _Req:
        headers = {"authorization": f"Bearer {token}"}

    actor = await get_current_actor(_Req(), db_session)
    assert actor.type == "customer"
    assert actor.id == sample_customer.id


@pytest.mark.asyncio
async def test_get_current_actor_rejects_missing_auth(db_session):
    from fastapi import HTTPException
    from app.auth.dependencies import get_current_actor

    class _Req:
        headers = {}

    with pytest.raises(HTTPException) as exc_info:
        await get_current_actor(_Req(), db_session)
    assert exc_info.value.status_code == 401
```

If the project's test fixtures don't include `sample_customer`, check `tests/conftest.py` for the actual fixture name (`customer`, `test_customer`, etc.) and replace accordingly. If no fixture exists yet, inline the creation: `customer = Customer(phone="+996700000000"); db_session.add(customer); await db_session.flush()`.

- [ ] **Step 2: Run the tests to see them fail**

```bash
cd "/Users/izzat/PycharmProjects/cool group/backend" && \
pytest tests/test_phase16_guest_mode.py -x -k "get_current_actor"
```

Expected: `ImportError: cannot import name 'get_current_actor'`.

- [ ] **Step 3: Implement the dependency**

At the bottom of `app/auth/dependencies.py`:

```python
from dataclasses import dataclass
from typing import Literal
import uuid as _uuid

from fastapi import HTTPException, Request, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.security import decode_guest_token
from app.customers.guest_models import GuestSession


@dataclass(frozen=True)
class Actor:
    type: Literal["guest", "customer"]
    id: _uuid.UUID


def _extract_bearer(request: Request) -> str | None:
    header = request.headers.get("authorization") or request.headers.get("Authorization")
    if not header or not header.lower().startswith("bearer "):
        return None
    return header[7:].strip() or None


async def get_current_guest(
    request: Request,
    db: AsyncSession = Depends(get_db),
) -> GuestSession:
    token = _extract_bearer(request)
    if token is None:
        raise HTTPException(status_code=401, detail="Missing credentials")
    payload = decode_guest_token(token)
    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid guest token")
    try:
        gid = _uuid.UUID(str(payload["sub"]))
    except (KeyError, ValueError):
        raise HTTPException(status_code=401, detail="Malformed guest token")
    guest = (await db.execute(
        select(GuestSession).where(GuestSession.id == gid)
    )).scalar_one_or_none()
    if guest is None:
        raise HTTPException(status_code=401, detail="Guest session not found")
    return guest


async def get_current_actor(
    request: Request,
    db: AsyncSession = Depends(get_db),
) -> Actor:
    token = _extract_bearer(request)
    if token is None:
        raise HTTPException(status_code=401, detail="Missing credentials")

    # Try customer token first (most requests from logged-in users).
    from app.auth.security import decode_customer_access_token  # local import avoids cycles
    cust_payload = None
    try:
        cust_payload = decode_customer_access_token(token)
    except Exception:
        cust_payload = None
    if cust_payload and cust_payload.get("type") != "guest":
        try:
            cid = _uuid.UUID(str(cust_payload["sub"]))
            return Actor(type="customer", id=cid)
        except (KeyError, ValueError):
            pass

    guest_payload = decode_guest_token(token)
    if guest_payload is not None:
        try:
            gid = _uuid.UUID(str(guest_payload["sub"]))
            return Actor(type="guest", id=gid)
        except (KeyError, ValueError):
            pass

    raise HTTPException(status_code=401, detail="Invalid credentials")
```

Adjust imports (`Depends`, `get_db`, `select`) to match what's already imported in the file. Replace `decode_customer_access_token` with whatever the project actually calls that function — look it up in `app/auth/security.py`. If no `decode_customer_access_token` exists and the project only decodes on demand inside `get_current_customer`, factor a small helper out: make `get_current_actor` call a new `_try_decode_customer(token)` internal helper you add to `dependencies.py`.

- [ ] **Step 4: Run tests**

```bash
cd "/Users/izzat/PycharmProjects/cool group/backend" && \
pytest tests/test_phase16_guest_mode.py -x -k "get_current_actor"
```

Expected: 3 passed.

- [ ] **Step 5: Commit**

```bash
cd "/Users/izzat/PycharmProjects/cool group/backend" && \
git add app/auth/dependencies.py tests/test_phase16_guest_mode.py && \
git commit -m "feat(guest-mode): add get_current_guest/get_current_actor dependencies"
```

---

### Task A5: `POST /api/me/guest/init` endpoint

**Files:**
- Create: `/Users/izzat/PycharmProjects/cool group/backend/app/customers/guest_router.py`
- Modify: `/Users/izzat/PycharmProjects/cool group/backend/app/main.py`
- Test: `/Users/izzat/PycharmProjects/cool group/backend/tests/test_phase16_guest_mode.py`

- [ ] **Step 1: Append the endpoint test**

```python
@pytest.mark.asyncio
async def test_guest_init_creates_session(async_client):
    r = await async_client.post(
        "/api/me/guest/init",
        json={
            "device_id": "test-device-abc",
            "platform": "ios",
            "app_version": "1.0.0",
            "locale": "ru",
        },
    )
    assert r.status_code == 200
    body = r.json()
    assert "guest_id" in body
    assert "guest_token" in body
    assert body["expires_in"] > 0


@pytest.mark.asyncio
async def test_guest_init_is_idempotent(async_client):
    body_one = (await async_client.post(
        "/api/me/guest/init",
        json={"device_id": "test-device-xyz", "platform": "android"},
    )).json()

    body_two = (await async_client.post(
        "/api/me/guest/init",
        json={"device_id": "test-device-xyz", "platform": "android", "app_version": "1.0.1"},
    )).json()

    assert body_one["guest_id"] == body_two["guest_id"]
```

Check `tests/conftest.py` for the existing HTTP test client fixture name (it may be `client`, `async_client`, or `api_client`) and use that.

- [ ] **Step 2: Run tests to see them fail**

```bash
cd "/Users/izzat/PycharmProjects/cool group/backend" && \
pytest tests/test_phase16_guest_mode.py -x -k "guest_init"
```

Expected: 404 (route not found).

- [ ] **Step 3: Write the router**

`app/customers/guest_router.py`:

```python
"""Guest session bootstrap — see spec 2026-04-14-guest-mode-design.md."""
from __future__ import annotations

from datetime import datetime, timezone

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.security import GUEST_TOKEN_TTL_SECONDS, create_guest_token
from app.customers.guest_models import GuestSession
from app.database import get_db


router = APIRouter(prefix="/api/me/guest", tags=["guest"])


class GuestInitBody(BaseModel):
    device_id: str = Field(min_length=8, max_length=64)
    platform: str | None = Field(default=None, max_length=20)
    app_version: str | None = Field(default=None, max_length=20)
    locale: str | None = Field(default=None, max_length=5)


class GuestInitResponse(BaseModel):
    guest_id: str
    guest_token: str
    expires_in: int


@router.post("/init", response_model=GuestInitResponse)
async def guest_init(
    body: GuestInitBody,
    db: AsyncSession = Depends(get_db),
):
    existing = (
        await db.execute(
            select(GuestSession).where(GuestSession.device_id == body.device_id)
        )
    ).scalar_one_or_none()

    if existing is None:
        session = GuestSession(
            device_id=body.device_id,
            platform=body.platform,
            app_version=body.app_version,
            locale=body.locale,
        )
        db.add(session)
        await db.flush()
        await db.refresh(session)
    else:
        session = existing
        if body.platform:
            session.platform = body.platform
        if body.app_version:
            session.app_version = body.app_version
        if body.locale:
            session.locale = body.locale
        session.last_seen_at = datetime.now(timezone.utc)
        await db.flush()

    return GuestInitResponse(
        guest_id=str(session.id),
        guest_token=create_guest_token(session.id),
        expires_in=GUEST_TOKEN_TTL_SECONDS,
    )
```

- [ ] **Step 4: Wire it up in `main.py`**

In `app/main.py`, next to the other router includes:

```python
from app.customers.guest_router import router as guest_router
app.include_router(guest_router)
```

- [ ] **Step 5: Run tests**

```bash
cd "/Users/izzat/PycharmProjects/cool group/backend" && \
pytest tests/test_phase16_guest_mode.py -x -k "guest_init"
```

Expected: 2 passed.

- [ ] **Step 6: Commit**

```bash
cd "/Users/izzat/PycharmProjects/cool group/backend" && \
git add app/customers/guest_router.py app/main.py tests/test_phase16_guest_mode.py && \
git commit -m "feat(guest-mode): add POST /api/me/guest/init endpoint"
```

---

## Phase B — Backend events + merge

### Task B1: `POST /api/me/events` endpoint

**Files:**
- Create: `/Users/izzat/PycharmProjects/cool group/backend/app/customers/events_router.py`
- Modify: `/Users/izzat/PycharmProjects/cool group/backend/app/main.py`
- Test: `/Users/izzat/PycharmProjects/cool group/backend/tests/test_phase16_guest_mode.py`

- [ ] **Step 1: Append tests**

```python
@pytest.mark.asyncio
async def test_events_as_guest(async_client, db_session):
    init = (await async_client.post(
        "/api/me/guest/init",
        json={"device_id": "evt-device-1", "platform": "ios"},
    )).json()
    token = init["guest_token"]

    r = await async_client.post(
        "/api/me/events",
        headers={"Authorization": f"Bearer {token}"},
        json={"events": [
            {"type": "view_product", "payload": {"product_id": "p1"}, "occurred_at": "2026-04-14T10:00:00Z"},
            {"type": "view_banner", "payload": {}, "occurred_at": "2026-04-14T10:00:05Z"},
        ]},
    )
    assert r.status_code == 200
    assert r.json() == {"accepted": 2}

    from app.customers.guest_models import CustomerEvent
    from sqlalchemy import select as _sel

    rows = (await db_session.execute(
        _sel(CustomerEvent).where(CustomerEvent.actor_id == uuid.UUID(init["guest_id"]))
    )).scalars().all()
    assert len(rows) == 2
    assert all(r.actor_type == "guest" for r in rows)


@pytest.mark.asyncio
async def test_events_reject_unauth(async_client):
    r = await async_client.post(
        "/api/me/events",
        json={"events": [{"type": "view_product", "payload": {}, "occurred_at": "2026-04-14T10:00:00Z"}]},
    )
    assert r.status_code == 401


@pytest.mark.asyncio
async def test_events_reject_oversized_batch(async_client):
    init = (await async_client.post(
        "/api/me/guest/init",
        json={"device_id": "evt-device-big"},
    )).json()

    r = await async_client.post(
        "/api/me/events",
        headers={"Authorization": f"Bearer {init['guest_token']}"},
        json={"events": [
            {"type": "t", "payload": {}, "occurred_at": "2026-04-14T10:00:00Z"}
            for _ in range(51)
        ]},
    )
    assert r.status_code == 422
```

- [ ] **Step 2: Run tests to see them fail**

```bash
cd "/Users/izzat/PycharmProjects/cool group/backend" && \
pytest tests/test_phase16_guest_mode.py -x -k "test_events"
```

Expected: 404.

- [ ] **Step 3: Write the router**

`app/customers/events_router.py`:

```python
"""Customer/guest event ingestion — see spec 2026-04-14-guest-mode-design.md."""
from __future__ import annotations

import logging
from datetime import datetime

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field, conlist
from sqlalchemy import desc, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.dependencies import Actor, get_current_actor
from app.customers.guest_models import CustomerEvent, GuestSession
from app.database import get_db

_log = logging.getLogger("app.customers.events")

router = APIRouter(prefix="/api/me", tags=["events"])

MAX_BATCH = 50


class EventIn(BaseModel):
    type: str = Field(min_length=1, max_length=50)
    payload: dict = Field(default_factory=dict)
    occurred_at: datetime


class EventBatch(BaseModel):
    events: conlist(EventIn, min_length=1, max_length=MAX_BATCH)


class EventBatchResponse(BaseModel):
    accepted: int


async def _resolve_session_id(
    db: AsyncSession, actor: Actor
) -> "uuid.UUID":
    if actor.type == "guest":
        return actor.id
    # Customer: find their most recent merged guest session.
    row = (await db.execute(
        select(GuestSession.id)
        .where(GuestSession.merged_to_customer_id == actor.id)
        .order_by(desc(GuestSession.merged_at))
        .limit(1)
    )).scalar_one_or_none()
    if row is not None:
        return row
    # Customer with no guest session history — use actor.id itself as session_id
    # so the column stays non-null. It's still queryable because session_id
    # indexes are only used for cohort lookups.
    return actor.id


@router.post("/events", response_model=EventBatchResponse)
async def ingest_events(
    batch: EventBatch,
    db: AsyncSession = Depends(get_db),
    actor: Actor = Depends(get_current_actor),
):
    session_id = await _resolve_session_id(db, actor)
    inserted = 0
    for evt in batch.events:
        try:
            db.add(CustomerEvent(
                actor_type=actor.type,
                actor_id=actor.id,
                session_id=session_id,
                event_type=evt.type,
                payload=evt.payload or {},
                created_at=evt.occurred_at,
            ))
            inserted += 1
        except Exception as exc:
            _log.warning("event_insert_failed", extra={"error": str(exc)})
            continue
    await db.flush()
    return EventBatchResponse(accepted=inserted)
```

Note: `import uuid` at top of file for the type hint.

- [ ] **Step 4: Wire router in `main.py`**

```python
from app.customers.events_router import router as events_router
app.include_router(events_router)
```

- [ ] **Step 5: Run tests**

```bash
cd "/Users/izzat/PycharmProjects/cool group/backend" && \
pytest tests/test_phase16_guest_mode.py -x -k "test_events"
```

Expected: 3 passed.

- [ ] **Step 6: Commit**

```bash
cd "/Users/izzat/PycharmProjects/cool group/backend" && \
git add app/customers/events_router.py app/main.py tests/test_phase16_guest_mode.py && \
git commit -m "feat(guest-mode): add POST /api/me/events endpoint"
```

---

### Task B2: Merge service and `verify-otp` wiring

**Files:**
- Create: `/Users/izzat/PycharmProjects/cool group/backend/app/customers/merge_service.py`
- Modify: `/Users/izzat/PycharmProjects/cool group/backend/app/auth/customer_router.py`
- Test: `/Users/izzat/PycharmProjects/cool group/backend/tests/test_phase16_guest_mode.py`

- [ ] **Step 1: Append merge test**

```python
@pytest.mark.asyncio
async def test_merge_guest_into_customer(db_session, sample_customer):
    from app.customers.guest_models import CustomerEvent, GuestSession
    from app.customers.merge_service import merge_guest_into_customer

    guest = GuestSession(device_id="merge-dev")
    db_session.add(guest)
    await db_session.flush()

    db_session.add(CustomerEvent(
        actor_type="guest",
        actor_id=guest.id,
        session_id=guest.id,
        event_type="view_product",
        payload={"product_id": "p1"},
    ))
    await db_session.flush()

    await merge_guest_into_customer(db_session, guest.id, sample_customer.id)
    await db_session.flush()
    await db_session.refresh(guest)

    assert guest.merged_to_customer_id == sample_customer.id
    assert guest.merged_at is not None

    from sqlalchemy import select as _sel
    rows = (await db_session.execute(
        _sel(CustomerEvent).where(CustomerEvent.session_id == guest.id)
    )).scalars().all()
    # original view_product + register_completed audit entry
    assert {r.event_type for r in rows} == {"view_product", "register_completed"}
    assert all(r.actor_type == "customer" and r.actor_id == sample_customer.id for r in rows)


@pytest.mark.asyncio
async def test_merge_is_idempotent(db_session, sample_customer):
    from app.customers.guest_models import GuestSession
    from app.customers.merge_service import merge_guest_into_customer

    guest = GuestSession(device_id="merge-dev-2")
    db_session.add(guest)
    await db_session.flush()

    await merge_guest_into_customer(db_session, guest.id, sample_customer.id)
    await db_session.flush()
    await merge_guest_into_customer(db_session, guest.id, sample_customer.id)  # should no-op
    await db_session.flush()

    from sqlalchemy import select as _sel
    from app.customers.guest_models import CustomerEvent
    audit_rows = (await db_session.execute(
        _sel(CustomerEvent).where(
            CustomerEvent.session_id == guest.id,
            CustomerEvent.event_type == "register_completed",
        )
    )).scalars().all()
    assert len(audit_rows) == 1  # not duplicated
```

- [ ] **Step 2: Run to see it fail**

```bash
cd "/Users/izzat/PycharmProjects/cool group/backend" && \
pytest tests/test_phase16_guest_mode.py -x -k "merge"
```

Expected: ImportError.

- [ ] **Step 3: Write the merge service**

`app/customers/merge_service.py`:

```python
"""Merge a guest session's activity into a real customer record.

Called from verify-otp inside the same DB session so the update is
atomic with customer creation.
"""
from __future__ import annotations

import logging
import uuid

from sqlalchemy import update
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.sql import func

from app.customers.guest_models import CustomerEvent, GuestSession

_log = logging.getLogger("app.customers.merge")


async def merge_guest_into_customer(
    db: AsyncSession,
    guest_id: uuid.UUID,
    customer_id: uuid.UUID,
) -> None:
    guest = await db.get(GuestSession, guest_id)
    if guest is None:
        _log.info("merge_skipped_guest_missing", extra={"guest_id": str(guest_id)})
        return
    if guest.merged_to_customer_id is not None:
        _log.info(
            "merge_skipped_already_merged",
            extra={"guest_id": str(guest_id), "customer_id": str(customer_id)},
        )
        return

    await db.execute(
        update(CustomerEvent)
        .where(CustomerEvent.actor_type == "guest")
        .where(CustomerEvent.actor_id == guest_id)
        .values(actor_type="customer", actor_id=customer_id)
    )
    guest.merged_to_customer_id = customer_id
    guest.merged_at = func.now()

    db.add(CustomerEvent(
        actor_type="customer",
        actor_id=customer_id,
        session_id=guest_id,
        event_type="register_completed",
        payload={},
    ))
```

- [ ] **Step 4: Wire into verify-otp**

In `app/auth/customer_router.py`:

1. Extend `VerifyOtpBody`:

```python
class VerifyOtpBody(BaseModel):
    phone: str = Field(min_length=8, max_length=20)
    code: str = Field(min_length=1, max_length=12)
    guest_id: str | None = None
```

2. After the successful `customer, is_new = await verify_otp(...)` call and before returning the token pair, add:

```python
    if body.guest_id:
        try:
            import uuid as _uuid
            from app.customers.merge_service import merge_guest_into_customer
            gid = _uuid.UUID(body.guest_id)
            await merge_guest_into_customer(db, gid, customer.id)
        except Exception as exc:
            _audit_logger.warning(
                "guest_merge_failed",
                extra={"event": "guest_merge_failed", "error": str(exc)},
            )
```

Best-effort: merge failures never block login.

- [ ] **Step 5: Run all phase-16 tests**

```bash
cd "/Users/izzat/PycharmProjects/cool group/backend" && \
pytest tests/test_phase16_guest_mode.py -x
```

Expected: all green.

- [ ] **Step 6: Run the broader auth test to make sure nothing regressed**

```bash
cd "/Users/izzat/PycharmProjects/cool group/backend" && \
pytest tests/test_phase3_customer_auth.py -x
```

Expected: still green.

- [ ] **Step 7: Commit**

```bash
cd "/Users/izzat/PycharmProjects/cool group/backend" && \
git add app/customers/merge_service.py app/auth/customer_router.py tests/test_phase16_guest_mode.py && \
git commit -m "feat(guest-mode): merge guest session on verify-otp"
```

---

### Task B3: Deploy backend and smoke-test against dev

- [ ] **Step 1: Push branch and deploy to dev environment**

Follow the repo's standard deploy flow (check `.omc/` or `docs/` for notes). This might be `git push origin ...` + a Render auto-deploy or a manual `render deploys create`.

- [ ] **Step 2: Smoke test the endpoints with curl**

```bash
BASE="https://<dev-backend-host>"
curl -sX POST "$BASE/api/me/guest/init" \
  -H "Content-Type: application/json" \
  -d '{"device_id":"smoke-device-1","platform":"ios","app_version":"1.0.0"}'
```

Expected: JSON with `guest_id`, `guest_token`, `expires_in=7776000`.

```bash
TOKEN="<guest_token from previous>"
curl -sX POST "$BASE/api/me/events" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"events":[{"type":"view_product","payload":{"product_id":"smoke-p1"},"occurred_at":"2026-04-14T10:00:00Z"}]}'
```

Expected: `{"accepted":1}`.

- [ ] **Step 3: No commit** — this is a verification step only.

---

## Phase C — Frontend bootstrap

### Task C1: `DeviceIdService`

**Files:**
- Create: `/Users/izzat/PycharmProjects/LoyaltyToolor/lib/services/device_id_service.dart`

- [ ] **Step 1: Write the service**

```dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceIdService {
  static const _key = 'device_id';

  /// Returns the persistent device identifier, creating it on first call.
  /// Pure app-layer UUID — not tied to OS identifiers, survives reinstall
  /// only if the OS preserves SharedPreferences (typically yes on both
  /// iOS and Android once granted).
  static Future<String> get() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_key);
    if (existing != null && existing.isNotEmpty) return existing;
    final fresh = const Uuid().v4();
    await prefs.setString(_key, fresh);
    return fresh;
  }
}
```

- [ ] **Step 2: Check pubspec dependencies**

Open `/Users/izzat/PycharmProjects/LoyaltyToolor/pubspec.yaml` and confirm `shared_preferences` and `uuid` are both listed. If `uuid` is missing, add it:

```yaml
dependencies:
  uuid: ^4.5.1
```

Then:

```bash
cd /Users/izzat/PycharmProjects/LoyaltyToolor && flutter pub get
```

- [ ] **Step 3: Verify it compiles**

```bash
cd /Users/izzat/PycharmProjects/LoyaltyToolor && flutter analyze lib/services/device_id_service.dart
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
cd /Users/izzat/PycharmProjects/LoyaltyToolor && \
git add lib/services/device_id_service.dart pubspec.yaml pubspec.lock && \
git commit -m "feat(guest-mode): add DeviceIdService for persistent device UUID"
```

---

### Task C2: Guest token storage + `bootstrapGuest` in `ApiService`

**Files:**
- Modify: `/Users/izzat/PycharmProjects/LoyaltyToolor/lib/services/api_service.dart`

- [ ] **Step 1: Read the current token-handling code**

Open `lib/services/api_service.dart` and identify:
1. The secure storage keys used for `access_token` and `refresh_token`.
2. The Dio request interceptor that attaches the Authorization header.
3. The 401 response interceptor.

Note the exact key names used so you don't break existing logins.

- [ ] **Step 2: Add guest token constants and helpers**

Near the other token key constants, add:

```dart
static const _kGuestAccessToken = 'guest_access_token';
static String? _guestAccessToken;
static String? get guestAccessToken => _guestAccessToken;
```

In `init()` (after the existing token load), load the guest token:

```dart
_guestAccessToken = await _secureStorage.read(key: _kGuestAccessToken);
```

Add a bootstrap method (below `init()`):

```dart
/// If we have no customer token, ensure there's a valid guest token
/// and fetch one if missing. Safe to call repeatedly — idempotent.
static Future<void> bootstrapGuest() async {
  if (_accessToken != null && _accessToken!.isNotEmpty) return;
  if (_guestAccessToken != null && _guestAccessToken!.isNotEmpty) {
    // We trust the cached token until a 401 forces a refresh.
    return;
  }

  try {
    final deviceId = await DeviceIdService.get();
    final response = await _bootstrapDio.post(
      '/api/me/guest/init',
      data: {
        'device_id': deviceId,
        'platform': Platform.isIOS
            ? 'ios'
            : Platform.isAndroid
                ? 'android'
                : 'macos',
        'app_version': '1.0.0',
        'locale': 'ru',
      },
    );
    final data = response.data as Map<String, dynamic>;
    final token = data['guest_token'] as String?;
    if (token != null && token.isNotEmpty) {
      _guestAccessToken = token;
      await _secureStorage.write(key: _kGuestAccessToken, value: token);
    }
  } catch (e) {
    debugPrint('[ApiService] bootstrapGuest failed: $e');
  }
}
```

`_bootstrapDio` is a plain `Dio` instance without the auth interceptor (so it won't recursively try to attach a token). Create one alongside the main `dio` static:

```dart
static final Dio _bootstrapDio = Dio(BaseOptions(baseUrl: _baseUrl));
```

Add `import 'dart:io';` at the top if not already present, and import `device_id_service.dart`.

- [ ] **Step 3: Update the request interceptor**

Find the existing request interceptor. Change it so:
- If `_accessToken` is non-empty → attach `Bearer $_accessToken`.
- Else if `_guestAccessToken` is non-empty → attach `Bearer $_guestAccessToken`.
- Else → no Authorization header.

```dart
onRequest: (options, handler) {
  final customer = _accessToken;
  final guest = _guestAccessToken;
  if (customer != null && customer.isNotEmpty) {
    options.headers['Authorization'] = 'Bearer $customer';
  } else if (guest != null && guest.isNotEmpty) {
    options.headers['Authorization'] = 'Bearer $guest';
  }
  return handler.next(options);
},
```

- [ ] **Step 4: Update the 401 interceptor**

Modify the 401 handler so that:
- If the failing request was authed with the customer token → existing behavior (clear customer tokens, don't touch guest).
- If with the guest token → clear `_guestAccessToken`, call `bootstrapGuest()`, retry the request once.

```dart
onError: (error, handler) async {
  if (error.response?.statusCode == 401) {
    final path = error.requestOptions.path;
    // Never loop on the auth endpoints themselves.
    if (path.startsWith('/api/me/auth/') || path.startsWith('/api/me/guest/')) {
      return handler.next(error);
    }

    final usedGuest = _accessToken == null || _accessToken!.isEmpty;
    if (usedGuest) {
      _guestAccessToken = null;
      await _secureStorage.delete(key: _kGuestAccessToken);
      await bootstrapGuest();
      if (_guestAccessToken != null) {
        final opts = error.requestOptions;
        opts.headers['Authorization'] = 'Bearer $_guestAccessToken';
        try {
          final r = await _retryDio.fetch(opts);
          return handler.resolve(r);
        } catch (_) {
          return handler.next(error);
        }
      }
    } else {
      // Existing customer-token logic — keep as-is.
    }
  }
  return handler.next(error);
},
```

`_retryDio` is another bare Dio instance without interceptors to avoid recursion (create it next to `_bootstrapDio`).

- [ ] **Step 5: Add a `logout()`-preserves-guest note**

Find the existing `logout()` method. Do **not** delete `_guestAccessToken` — it should survive logout so the same device keeps its tracking identity. Leave `_kGuestAccessToken` out of the `deleteAll` / explicit delete list.

- [ ] **Step 6: Verify**

```bash
cd /Users/izzat/PycharmProjects/LoyaltyToolor && flutter analyze lib/services/api_service.dart
```

Expected: no errors.

- [ ] **Step 7: Commit**

```bash
cd /Users/izzat/PycharmProjects/LoyaltyToolor && \
git add lib/services/api_service.dart && \
git commit -m "feat(guest-mode): add guest token bootstrap and interceptor support"
```

---

### Task C3: Call `bootstrapGuest` from `main()`

**Files:**
- Modify: `/Users/izzat/PycharmProjects/LoyaltyToolor/lib/main.dart`

- [ ] **Step 1: Edit `main()`**

Replace

```dart
await ApiService.init();
```

with

```dart
await ApiService.init();
await ApiService.bootstrapGuest();
```

- [ ] **Step 2: Verify**

```bash
cd /Users/izzat/PycharmProjects/LoyaltyToolor && flutter analyze lib/main.dart
```

Expected: clean.

- [ ] **Step 3: Manual smoke (build + launch app, watch logs)**

```bash
cd /Users/izzat/PycharmProjects/LoyaltyToolor && flutter run -d <device-id>
```

On first launch, look for:
- No `bootstrapGuest failed` log line.
- A 200 response to `/api/me/guest/init` in backend logs.

On second launch: no second call to `/guest/init` (token is cached).

- [ ] **Step 4: Commit**

```bash
cd /Users/izzat/PycharmProjects/LoyaltyToolor && \
git add lib/main.dart && \
git commit -m "feat(guest-mode): bootstrap guest token on app startup"
```

---

## Phase D — Frontend gating

### Task D1: Remove welcome screen from `HomeScreen`

**Files:**
- Modify: `/Users/izzat/PycharmProjects/LoyaltyToolor/lib/screens/home_screen.dart`
- Create: `/Users/izzat/PycharmProjects/LoyaltyToolor/lib/widgets/guest_cta_card.dart`

- [ ] **Step 1: Create the guest CTA card**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/auth_screen.dart';
import '../theme/app_theme.dart';

class GuestCtaCard extends StatelessWidget {
  const GuestCtaCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: S.x16),
      padding: const EdgeInsets.all(S.x20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accent.withValues(alpha: 0.12), AppColors.accent.withValues(alpha: 0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(R.lg),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOOLOR LOYALTY',
            style: TextStyle(fontSize: 10, letterSpacing: 2, color: AppColors.accent, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: S.x8),
          Text(
            'Войдите и получайте бонусы за покупки',
            style: TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w600, height: 1.3),
          ),
          const SizedBox(height: S.x16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.md)),
              ),
              child: const Text('ВОЙТИ'),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Modify `HomeScreen.build`**

In `lib/screens/home_screen.dart`:

1. Remove the entire `_welcome(auth)` method and its import of `Image.asset` if unused.
2. In `build`, replace:

```dart
if (auth.isLoading && !auth.isLoggedIn) { ... }
if (!auth.isLoggedIn) return _welcome(auth);
return _home(context, auth);
```

with:

```dart
return _home(context, auth);
```

3. In `_home`, change the loyalty-card slot: where the current code does

```dart
SliverToBoxAdapter(child: Padding(
  padding: const EdgeInsets.symmetric(horizontal: S.x16),
  child: _loyaltyCard(context, loyalty),
)),
```

wrap it:

```dart
SliverToBoxAdapter(
  child: auth.isLoggedIn && loyalty != null
      ? Padding(
          padding: const EdgeInsets.symmetric(horizontal: S.x16),
          child: _loyaltyCard(context, loyalty),
        )
      : const GuestCtaCard(),
),
```

4. Remove the `if (loyalty == null) return CircularProgressIndicator;` short-circuit for the guest case: guard it on `auth.isLoggedIn` first:

```dart
if (auth.isLoggedIn && loyalty == null) {
  if (!_loyaltyRetried) {
    _loyaltyRetried = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      auth.fetchLoyalty().then((_) { if (mounted) setState(() {}); });
    });
  }
  return const Center(child: CircularProgressIndicator());
}
```

5. In `_header`, make greeting gracefully degrade:

```dart
final firstName = (auth.user?.name ?? '').isNotEmpty ? auth.user!.name.split(' ').first : null;
final greeting = firstName != null ? 'Привет, $firstName' : 'Добро пожаловать';
```

Use `greeting` instead of the interpolated string. Where the header shows the avatar, render an empty circle / logo icon when `auth.user` is null.

- [ ] **Step 3: Import the new widget**

```dart
import '../widgets/guest_cta_card.dart';
```

- [ ] **Step 4: Verify**

```bash
cd /Users/izzat/PycharmProjects/LoyaltyToolor && flutter analyze lib/screens/home_screen.dart lib/widgets/guest_cta_card.dart
```

Expected: clean.

- [ ] **Step 5: Manual smoke**

Launch app fresh (clear app data first). Expected: home screen renders immediately with products; where the loyalty card usually sits, the CTA card is shown.

- [ ] **Step 6: Commit**

```bash
cd /Users/izzat/PycharmProjects/LoyaltyToolor && \
git add lib/screens/home_screen.dart lib/widgets/guest_cta_card.dart && \
git commit -m "feat(guest-mode): let guests browse home; remove welcome screen"
```

---

### Task D2: Bottom-nav QR gate in `main.dart`

**Files:**
- Modify: `/Users/izzat/PycharmProjects/LoyaltyToolor/lib/main.dart`

- [ ] **Step 1: Replace the `onTap` handler**

In `_MainShellState.build`, change the `BottomNavigationBar.onTap`:

```dart
onTap: (i) async {
  HapticFeedback.selectionClick();
  if (i == 2 && !auth.isLoggedIn) {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
    if (ok == true && mounted) {
      setState(() => _tab = 2);
    }
    return;
  }
  setState(() => _tab = i);
},
```

Add the `AuthScreen` import if not already present.

- [ ] **Step 2: Verify**

```bash
cd /Users/izzat/PycharmProjects/LoyaltyToolor && flutter analyze lib/main.dart
```

- [ ] **Step 3: Manual smoke**

As a guest, tap the center QR tab → auth screen opens. Close without logging in → still on home (tab 0). Log in successfully → land on QR tab.

- [ ] **Step 4: Commit**

```bash
cd /Users/izzat/PycharmProjects/LoyaltyToolor && \
git add lib/main.dart && \
git commit -m "feat(guest-mode): gate QR tab behind auth for guests"
```

---

### Task D3: `AuthScreen.pop(true)` on success

**Files:**
- Modify: `/Users/izzat/PycharmProjects/LoyaltyToolor/lib/screens/auth_screen.dart`

- [ ] **Step 1: Find the success path**

In `auth_screen.dart`, locate the block around line 230 where `auth.isLoggedIn` is true and the code navigates forward (pop or replace).

- [ ] **Step 2: Change any `Navigator.pop(context)` on the success branch to**

```dart
Navigator.of(context).pop(true);
```

If onboarding is required, keep the push to onboarding, and on the onboarding success path pop back to the auth-screen caller with `pop(true)` chained (or set a flag and pop on the next frame). The caller of AuthScreen only needs to see `true` as the final result when the user is fully authed.

- [ ] **Step 3: Verify**

```bash
cd /Users/izzat/PycharmProjects/LoyaltyToolor && flutter analyze lib/screens/auth_screen.dart
```

- [ ] **Step 4: Commit**

```bash
cd /Users/izzat/PycharmProjects/LoyaltyToolor && \
git add lib/screens/auth_screen.dart && \
git commit -m "feat(guest-mode): return bool result from AuthScreen for callers"
```

---

### Task D4: Checkout gate on `CartScreen`

**Files:**
- Modify: `/Users/izzat/PycharmProjects/LoyaltyToolor/lib/screens/cart_screen.dart`

- [ ] **Step 1: Find the checkout button**

Grep for the button that navigates to `CheckoutScreen` or calls the checkout provider.

- [ ] **Step 2: Wrap its `onPressed`**

```dart
onPressed: () async {
  final auth = context.read<AuthProvider>();
  if (!auth.isLoggedIn) {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
    if (ok != true) return;
  }
  // existing checkout navigation
  Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen()));
},
```

Import `AuthProvider` and `AuthScreen` if missing.

- [ ] **Step 3: Verify**

```bash
cd /Users/izzat/PycharmProjects/LoyaltyToolor && flutter analyze lib/screens/cart_screen.dart
```

- [ ] **Step 4: Commit**

```bash
cd /Users/izzat/PycharmProjects/LoyaltyToolor && \
git add lib/screens/cart_screen.dart && \
git commit -m "feat(guest-mode): gate checkout behind auth"
```

---

### Task D5: Favorite gate on product card and detail

**Files:**
- Modify: one of `lib/widgets/product_card.dart` or wherever the favorite icon lives (run `grep -rn toggleFavorite lib/` to locate)
- Modify: `/Users/izzat/PycharmProjects/LoyaltyToolor/lib/screens/product_detail_screen.dart`

- [ ] **Step 1: Locate all favorite buttons**

```bash
cd /Users/izzat/PycharmProjects/LoyaltyToolor && grep -rn "toggleFavorite\|FavoritesProvider" lib/
```

- [ ] **Step 2: Wrap each `toggleFavorite` call**

```dart
Future<void> _onFavTap(BuildContext context, ...) async {
  final auth = context.read<AuthProvider>();
  if (!auth.isLoggedIn) {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
    return;  // don't proceed — favorites will sync on login
  }
  context.read<FavoritesProvider>().toggleFavorite(...);
}
```

Apply the same pattern wherever the favorite button sits.

- [ ] **Step 3: Verify**

```bash
cd /Users/izzat/PycharmProjects/LoyaltyToolor && flutter analyze
```

- [ ] **Step 4: Commit**

```bash
cd /Users/izzat/PycharmProjects/LoyaltyToolor && \
git add -u lib/ && \
git commit -m "feat(guest-mode): gate favorite actions behind auth"
```

---

### Task D6: In-screen guard on `PromoCodesScreen`

**Files:**
- Modify: `/Users/izzat/PycharmProjects/LoyaltyToolor/lib/screens/promo_codes_screen.dart`

- [ ] **Step 1: Add an auth guard at the top of `build`**

```dart
@override
Widget build(BuildContext context) {
  final auth = context.watch<AuthProvider>();
  if (!auth.isLoggedIn) {
    return Scaffold(
      appBar: AppBar(title: const Text('Промокоды')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_offer_outlined, size: 40, color: AppColors.textTertiary),
              const SizedBox(height: 16),
              Text('Войдите, чтобы видеть промокоды', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const AuthScreen())),
                  child: const Text('ВОЙТИ'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // existing body
}
```

- [ ] **Step 2: Verify + commit**

```bash
cd /Users/izzat/PycharmProjects/LoyaltyToolor && flutter analyze lib/screens/promo_codes_screen.dart && \
git add lib/screens/promo_codes_screen.dart && \
git commit -m "feat(guest-mode): in-screen auth guard for PromoCodesScreen"
```

---

## Phase E — Frontend analytics

### Task E1: `AnalyticsService`

**Files:**
- Create: `/Users/izzat/PycharmProjects/LoyaltyToolor/lib/services/analytics_service.dart`
- Modify: `/Users/izzat/PycharmProjects/LoyaltyToolor/lib/services/api_service.dart` (call `AnalyticsService.init` at the end of `ApiService.init`)

- [ ] **Step 1: Write the service**

```dart
import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'api_service.dart';

class _PendingEvent {
  final String type;
  final Map<String, dynamic> payload;
  final DateTime occurredAt;
  _PendingEvent(this.type, this.payload, this.occurredAt);

  Map<String, dynamic> toJson() => {
        'type': type,
        'payload': payload,
        'occurred_at': occurredAt.toUtc().toIso8601String(),
      };
}

class AnalyticsService {
  static const _maxQueue = 200;
  static const _batchSize = 50;
  static const _flushInterval = Duration(seconds: 10);
  static const _flushThreshold = 20;

  static final Queue<_PendingEvent> _queue = Queue<_PendingEvent>();
  static Timer? _timer;
  static bool _flushing = false;

  static void init() {
    _timer ??= Timer.periodic(_flushInterval, (_) => _flush());
  }

  static void track(String type, {Map<String, dynamic>? payload}) {
    _queue.add(_PendingEvent(type, payload ?? const {}, DateTime.now()));
    while (_queue.length > _maxQueue) {
      _queue.removeFirst();
    }
    if (_queue.length >= _flushThreshold) {
      // Fire-and-forget, no await.
      _flush();
    }
  }

  static Future<void> _flush() async {
    if (_flushing || _queue.isEmpty) return;
    _flushing = true;
    try {
      final batch = <_PendingEvent>[];
      while (_queue.isNotEmpty && batch.length < _batchSize) {
        batch.add(_queue.removeFirst());
      }
      try {
        await ApiService.dio.post(
          '/api/me/events',
          data: {'events': batch.map((e) => e.toJson()).toList()},
        );
      } catch (e) {
        debugPrint('[AnalyticsService] flush failed: $e — requeueing ${batch.length}');
        for (final item in batch.reversed) {
          _queue.addFirst(item);
        }
        while (_queue.length > _maxQueue) {
          _queue.removeFirst();
        }
      }
    } finally {
      _flushing = false;
    }
  }
}
```

- [ ] **Step 2: Init in `ApiService.init`**

At the end of `ApiService.init()`:

```dart
AnalyticsService.init();
```

Import `analytics_service.dart`.

- [ ] **Step 3: Verify**

```bash
cd /Users/izzat/PycharmProjects/LoyaltyToolor && flutter analyze lib/services/
```

- [ ] **Step 4: Commit**

```bash
cd /Users/izzat/PycharmProjects/LoyaltyToolor && \
git add lib/services/analytics_service.dart lib/services/api_service.dart && \
git commit -m "feat(guest-mode): add AnalyticsService with batched flush"
```

---

### Task E2: Wire tracking call sites

**Files:**
- Modify: `lib/screens/product_detail_screen.dart`, `lib/screens/catalog_screen.dart`, `lib/providers/cart_provider.dart`, `lib/screens/auth_screen.dart`, `lib/main.dart`

- [ ] **Step 1: `view_product` in `ProductDetailScreen`**

Convert to StatefulWidget if needed. In `initState`:

```dart
@override
void initState() {
  super.initState();
  AnalyticsService.track('view_product', payload: {'product_id': widget.product.id});
}
```

- [ ] **Step 2: `view_category` in `CatalogScreen`**

When the active category changes (in the setState block that updates the filter), call:

```dart
AnalyticsService.track('view_category', payload: {'category': newCategory});
```

- [ ] **Step 3: `add_to_cart` in `CartProvider.addItem`**

Inside `addItem(...)`, right after the item is persisted locally/server-side:

```dart
AnalyticsService.track('add_to_cart', payload: {
  'product_id': product.id,
  'quantity': quantity,
});
```

- [ ] **Step 4: `register_started` in `AuthScreen`**

When the user submits the phone for OTP, call `AnalyticsService.track('register_started', payload: {})`.

- [ ] **Step 5: `open_qr_gate` in `main.dart`**

Inside the bottom-nav handler, right before pushing AuthScreen in the guest-QR branch:

```dart
AnalyticsService.track('open_qr_gate', payload: {});
```

- [ ] **Step 6: Verify**

```bash
cd /Users/izzat/PycharmProjects/LoyaltyToolor && flutter analyze
```

- [ ] **Step 7: Commit**

```bash
cd /Users/izzat/PycharmProjects/LoyaltyToolor && \
git add -u lib/ && \
git commit -m "feat(guest-mode): emit analytics events from key user actions"
```

---

## Phase F — Frontend cart sync + login wiring

### Task F1: Local guest cart persistence in `CartProvider`

**Files:**
- Modify: `/Users/izzat/PycharmProjects/LoyaltyToolor/lib/providers/cart_provider.dart`

- [ ] **Step 1: Add persistence helpers**

Near the top of the class:

```dart
static const _kGuestCart = 'guest_cart_v1';

Future<void> _persistGuestCart() async {
  final prefs = await SharedPreferences.getInstance();
  final items = _items.map((i) => i.toJson()).toList();
  await prefs.setString(_kGuestCart, jsonEncode(items));
}

Future<void> _loadGuestCart() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_kGuestCart);
  if (raw == null || raw.isEmpty) return;
  try {
    final decoded = jsonDecode(raw) as List<dynamic>;
    _items
      ..clear()
      ..addAll(decoded.map((m) => CartItem.fromJson(m as Map<String, dynamic>)));
    notifyListeners();
  } catch (_) {
    await prefs.remove(_kGuestCart);
  }
}
```

Make sure `CartItem` has `toJson` / `fromJson`. If it doesn't, add them now.

- [ ] **Step 2: Call `_loadGuestCart()` in the constructor**

- [ ] **Step 3: After every mutation in the guest branch, call `_persistGuestCart()`**

Specifically in `addItem`, `removeItem`, `updateQuantity`, `clearCart` — within the `!isLoggedIn` path.

- [ ] **Step 4: Add `syncLocalCartToServer`**

```dart
Future<void> syncLocalCartToServer() async {
  if (_items.isEmpty) return;
  final loggedIn = await ApiService.isLoggedIn();
  if (!loggedIn) return;
  final local = List<CartItem>.from(_items);
  for (final it in local) {
    try {
      // Use the existing add-to-cart endpoint (reuse serverAddItem)
      await _serverAddItem(it.productId, it.quantity, size: it.size, color: it.color);
    } catch (e) {
      debugPrint('[CartProvider] sync item failed: $e');
    }
  }
  // Clear local copy (server is now source of truth).
  _items.clear();
  await _clearGuestCart();
  await fetchFromServer();  // reload canonical state
  notifyListeners();
}

Future<void> _clearGuestCart() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_kGuestCart);
}
```

Replace `_serverAddItem` / `fetchFromServer` with the real private method names in the current file.

- [ ] **Step 5: Verify**

```bash
cd /Users/izzat/PycharmProjects/LoyaltyToolor && flutter analyze lib/providers/cart_provider.dart
```

- [ ] **Step 6: Commit**

```bash
cd /Users/izzat/PycharmProjects/LoyaltyToolor && \
git add lib/providers/cart_provider.dart && \
git commit -m "feat(guest-mode): local guest cart persistence + syncLocalCartToServer"
```

---

### Task F2: Pass `guest_id` on verify-otp and trigger cart sync post-login

**Files:**
- Modify: `/Users/izzat/PycharmProjects/LoyaltyToolor/lib/providers/auth_provider.dart`
- Modify: `/Users/izzat/PycharmProjects/LoyaltyToolor/lib/services/api_service.dart`
- Modify: `/Users/izzat/PycharmProjects/LoyaltyToolor/lib/main.dart`

- [ ] **Step 1: Extract guest_id from token**

In `ApiService`, add a helper:

```dart
static String? decodeGuestSubject() {
  final t = _guestAccessToken;
  if (t == null) return null;
  try {
    final parts = t.split('.');
    if (parts.length != 3) return null;
    final payload = utf8.decode(base64Url.decode(base64.normalize(parts[1])));
    final map = jsonDecode(payload) as Map<String, dynamic>;
    return map['sub'] as String?;
  } catch (_) {
    return null;
  }
}
```

Add `import 'dart:convert';` if missing.

- [ ] **Step 2: Update `ApiService.verifyOtp`**

Extend the call signature to accept an optional `guestId`:

```dart
static Future<Response> verifyOtp(String phone, String code) async {
  final guestId = decodeGuestSubject();
  return dio.post('/api/me/auth/verify-otp', data: {
    'phone': phone,
    'code': code,
    if (guestId != null) 'guest_id': guestId,
  });
}
```

Adjust to match whatever the current verify-otp call path looks like.

- [ ] **Step 3: Hook cart sync in `main.dart`**

In `_MainShellState.build`, alongside the existing `_favoritesSynced` flag, add:

```dart
bool _cartSynced = false;

// inside build:
if (auth.isLoggedIn && !_cartSynced) {
  _cartSynced = true;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<CartProvider>().syncLocalCartToServer();
  });
} else if (!auth.isLoggedIn && _cartSynced) {
  _cartSynced = false;
}
```

- [ ] **Step 4: Verify**

```bash
cd /Users/izzat/PycharmProjects/LoyaltyToolor && flutter analyze
```

- [ ] **Step 5: Commit**

```bash
cd /Users/izzat/PycharmProjects/LoyaltyToolor && \
git add lib/providers/auth_provider.dart lib/services/api_service.dart lib/main.dart && \
git commit -m "feat(guest-mode): send guest_id on verify-otp and sync cart post-login"
```

---

## Phase G — Manual QA

### Task G1: Full manual smoke test

No code changes; no commit. Walk through these scenarios and fix any issues found (they become new tasks).

- [ ] **Scenario 1: Fresh install as guest**
  1. Uninstall/reinstall the app.
  2. Launch. Expect home screen with products. No welcome screen.
  3. Check backend logs: one `POST /api/me/guest/init` call with 200.
  4. Navigate catalog, open a product. Check backend logs: `POST /api/me/events` with `view_product`.

- [ ] **Scenario 2: Guest hits QR tab**
  1. Tap the center QR button.
  2. AuthScreen opens. Backend log: one `open_qr_gate` event.
  3. Press back without logging in. Land on Home (tab 0 still selected).

- [ ] **Scenario 3: Guest → login merges activity**
  1. As a guest, view 3 different products.
  2. Tap QR tab → log in via OTP.
  3. Backend: verify the `customer_events` rows for those 3 products are now `actor_type='customer'` with the new `customer_id`. Check the `register_completed` audit event appeared.
  4. Frontend: QR tab is now selected and shows the loyalty card.

- [ ] **Scenario 4: Guest cart survives login**
  1. As a guest, add 2 items to the cart.
  2. Kill and relaunch the app — cart should still have 2 items.
  3. Tap Checkout → AuthScreen → log in.
  4. After return, cart should reflect server state (same 2 items, now server-synced).

- [ ] **Scenario 5: Logout keeps guest identity**
  1. Log out from Profile.
  2. Confirm `bootstrapGuest` does **not** re-run (check logs). Analytics events continue under the same `guest_session.id`.

- [ ] **Scenario 6: Guest 401 recovery**
  1. Manually expire the guest token in secure storage (or wait until expiry).
  2. Next backend call returns 401. Interceptor should call `bootstrapGuest` and retry.
  3. Verify in logs: exactly one retry, no infinite loop.

---

## Self-review notes

- **Spec coverage check passed.** Every spec section has at least one task:
  - Guest_sessions + customer_events → A1, A2
  - Guest token → A3
  - Dependencies → A4
  - /guest/init → A5
  - /me/events → B1
  - merge service + verify-otp wiring → B2
  - Frontend bootstrap → C1, C2, C3
  - Welcome-screen removal → D1
  - QR gate → D2
  - AuthScreen pop(true) → D3
  - Checkout gate → D4
  - Favorite gate → D5
  - Promo screen → D6
  - Analytics service → E1
  - Tracking call sites → E2
  - Guest cart persistence → F1
  - guest_id on verify + cart sync → F2
  - Manual QA → G1

- **Known adaptation points** (documented inline, not placeholders):
  - Backend `settings.customer_jwt_secret` name — look up actual name in `security.py`.
  - Conftest fixture name for HTTP client + customer fixture.
  - Favorite button location (widget file) — grep-based discovery in D5.
  - Exact `_serverAddItem` / `fetchFromServer` names in `CartProvider`.

  These are not TBDs — they are real "look up the existing symbol before typing" instructions that any engineer needs to execute.
