import asyncio
import uuid
from datetime import datetime, timezone
from unittest.mock import patch

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy import JSON, event
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.database import Base
from app.main import app
from app.dependencies import get_db
from app.services.auth_service import create_access_token, hash_password
from app.models.user import Profile
from app.models.loyalty import LoyaltyAccount

# In-memory SQLite for tests
TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"

engine = create_async_engine(TEST_DATABASE_URL, echo=False)
TestSession = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)


# ── SQLite compatibility ─────────────────────────────────────────────
from sqlalchemy import String as SAString, TypeDecorator
from sqlalchemy.ext.compiler import compiles
from sqlalchemy.dialects.postgresql import UUID as PG_UUID


@compiles(JSONB, "sqlite")
def compile_jsonb_sqlite(type_, compiler, **kw):
    return "JSON"


# Make PostgreSQL UUID work with SQLite by treating as CHAR(32)
@compiles(PG_UUID, "sqlite")
def compile_uuid_sqlite(type_, compiler, **kw):
    return "CHAR(36)"


# Patch UUID type to handle string values in SQLite
_orig_uuid_bind = PG_UUID.bind_processor

def _patched_uuid_bind(self, dialect):
    if dialect.name == "sqlite":
        def process(value):
            if value is not None:
                return str(value)
            return value
        return process
    return _orig_uuid_bind(self, dialect)

PG_UUID.bind_processor = _patched_uuid_bind

_orig_uuid_result = PG_UUID.result_processor

def _patched_uuid_result(self, dialect, coltype):
    if dialect.name == "sqlite":
        def process(value):
            if value is not None:
                if self.as_uuid:
                    import uuid as _uuid
                    return _uuid.UUID(str(value)) if not isinstance(value, _uuid.UUID) else value
                return str(value)
            return value
        return process
    return _orig_uuid_result(self, dialect, coltype)

PG_UUID.result_processor = _patched_uuid_result


# Strip Postgres-specific server_defaults before creating tables on SQLite
@event.listens_for(Base.metadata, "before_create")
def _strip_pg_defaults(target, connection, **kw):
    if connection.dialect.name != "sqlite":
        return
    for table in target.sorted_tables:
        for col in table.columns:
            sd = col.server_default
            if sd is not None:
                text_val = str(sd.arg) if hasattr(sd, "arg") else ""
                if "gen_random_uuid" in text_val or "::jsonb" in text_val:
                    col.server_default = None

# Counter for order numbers in tests
_order_counter = 0


async def _fake_generate_order_number(db):
    global _order_counter
    _order_counter += 1
    year = datetime.now(timezone.utc).strftime("%Y")
    return f"TOOLOR-{year}-{_order_counter:05d}"


@pytest.fixture(scope="session")
def event_loop():
    loop = asyncio.new_event_loop()
    yield loop
    loop.close()


@pytest_asyncio.fixture(autouse=True)
async def setup_db():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


@pytest.fixture(autouse=True)
def patch_order_number():
    with patch(
        "app.services.order_service.generate_order_number",
        side_effect=_fake_generate_order_number,
    ):
        yield


async def override_get_db():
    async with TestSession() as session:
        yield session


app.dependency_overrides[get_db] = override_get_db


@pytest_asyncio.fixture
async def client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        yield c


@pytest_asyncio.fixture
async def db():
    async with TestSession() as session:
        yield session


@pytest_asyncio.fixture
async def test_user(db: AsyncSession):
    """Create a test user with loyalty account."""
    user_id = uuid.uuid4()
    user = Profile(
        id=user_id,
        phone="+996555000001",
        password_hash=hash_password("testpass123"),
        full_name="Test User",
        referral_code=f"TEST-{str(user_id)[:8].upper()}",
    )
    db.add(user)

    loyalty = LoyaltyAccount(
        user_id=user_id,
        qr_code=f"QR-{str(user_id)[:12].upper()}",
        tier="bronze",
        points=100,
        total_spent=0,
    )
    db.add(loyalty)
    await db.commit()
    await db.refresh(user)
    return user


@pytest_asyncio.fixture
async def auth_headers(test_user: Profile):
    """Return Authorization headers for the test user."""
    token = create_access_token(test_user)
    return {"Authorization": f"Bearer {token}"}


@pytest_asyncio.fixture
async def admin_user(db: AsyncSession):
    """Create an admin user."""
    user_id = uuid.uuid4()
    user = Profile(
        id=user_id,
        phone="+996555000099",
        password_hash=hash_password("admin123"),
        full_name="Admin User",
        is_admin=True,
        referral_code=f"ADMIN-{str(user_id)[:8].upper()}",
    )
    db.add(user)

    loyalty = LoyaltyAccount(
        user_id=user_id,
        qr_code=f"QRA-{str(user_id)[:12].upper()}",
        tier="bronze",
        points=0,
        total_spent=0,
    )
    db.add(loyalty)
    await db.commit()
    await db.refresh(user)
    return user


@pytest_asyncio.fixture
async def admin_headers(admin_user: Profile):
    token = create_access_token(admin_user)
    return {"Authorization": f"Bearer {token}"}
