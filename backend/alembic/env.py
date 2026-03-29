import asyncio
import ssl as _ssl
from logging.config import fileConfig

from alembic import context
from sqlalchemy import pool
from sqlalchemy.ext.asyncio import async_engine_from_config

from app.config import settings
from app.database import Base
import app.models  # noqa — ensure all models are imported

config = context.config

# Strip sslmode/channel_binding from URL for asyncpg compatibility
_db_url = settings.DATABASE_URL
for _param in ("sslmode=require", "sslmode=verify-full", "channel_binding=require"):
    _db_url = _db_url.replace(f"?{_param}&", "?")
    _db_url = _db_url.replace(f"&{_param}", "")
    _db_url = _db_url.replace(f"?{_param}", "")

config.set_main_option("sqlalchemy.url", _db_url)

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata


def run_migrations_offline() -> None:
    url = config.get_main_option("sqlalchemy.url")
    context.configure(url=url, target_metadata=target_metadata, literal_binds=True)
    with context.begin_transaction():
        context.run_migrations()


def do_run_migrations(connection):
    context.configure(connection=connection, target_metadata=target_metadata)
    with context.begin_transaction():
        context.run_migrations()


async def run_async_migrations():
    connect_args = {}
    if "neon.tech" in settings.DATABASE_URL or "sslmode=require" in settings.DATABASE_URL:
        try:
            import certifi
            _ctx = _ssl.create_default_context(cafile=certifi.where())
        except ImportError:
            _ctx = _ssl.create_default_context()
        connect_args = {"ssl": _ctx}

    connectable = async_engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
        connect_args=connect_args,
    )
    async with connectable.connect() as connection:
        await connection.run_sync(do_run_migrations)
    await connectable.dispose()


def run_migrations_online() -> None:
    asyncio.run(run_async_migrations())


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
