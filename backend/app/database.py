import ssl as _ssl

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase

from app.config import settings

# Strip sslmode from URL (asyncpg doesn't accept it as a query param)
_db_url = settings.DATABASE_URL
for _param in ("sslmode=require", "sslmode=verify-full", "channel_binding=require"):
    _db_url = _db_url.replace(f"?{_param}&", "?")
    _db_url = _db_url.replace(f"&{_param}", "")
    _db_url = _db_url.replace(f"?{_param}", "")

# Use SSL for Neon / cloud Postgres
_connect_args = {}
if "neon.tech" in settings.DATABASE_URL or "sslmode=require" in settings.DATABASE_URL:
    try:
        import certifi
        _ssl_ctx = _ssl.create_default_context(cafile=certifi.where())
    except ImportError:
        _ssl_ctx = _ssl.create_default_context()
    _connect_args = {"ssl": _ssl_ctx}

engine = create_async_engine(_db_url, echo=False, connect_args=_connect_args)
async_session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)


class Base(DeclarativeBase):
    pass
