import uuid
import random
from datetime import datetime, timedelta, timezone

from jose import JWTError, jwt
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.models.loyalty import LoyaltyAccount
from app.models.user import Profile

# ── In-memory OTP store (phone -> {code, expires_at}) ────────────────
# TODO: Replace with Redis or a real SMS OTP service in production.
_otp_store: dict[str, dict] = {}

OTP_LENGTH = 4
OTP_TTL_SECONDS = 120  # OTP valid for 2 minutes


def generate_otp(phone: str) -> str:
    """Generate a random OTP code, store it, and return it."""
    code = "".join([str(random.randint(0, 9)) for _ in range(OTP_LENGTH)])
    _otp_store[phone] = {
        "code": code,
        "expires_at": datetime.now(timezone.utc) + timedelta(seconds=OTP_TTL_SECONDS),
    }
    return code


def verify_otp(phone: str, code: str) -> bool:
    """Verify an OTP code for a given phone number."""
    entry = _otp_store.get(phone)
    if not entry:
        return False
    if datetime.now(timezone.utc) > entry["expires_at"]:
        _otp_store.pop(phone, None)
        return False
    if entry["code"] != code:
        return False
    # OTP is single-use
    _otp_store.pop(phone, None)
    return True


def create_token(data: dict, expires_delta: timedelta) -> str:
    to_encode = data.copy()
    to_encode["exp"] = datetime.now(timezone.utc) + expires_delta
    return jwt.encode(to_encode, settings.JWT_SECRET, algorithm=settings.JWT_ALGORITHM)


def create_access_token(user: Profile) -> str:
    return create_token(
        {"sub": str(user.id), "is_admin": user.is_admin},
        timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES),
    )


def create_refresh_token(user: Profile) -> str:
    return create_token(
        {"sub": str(user.id), "type": "refresh"},
        timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS),
    )


def verify_token(token: str) -> dict | None:
    try:
        return jwt.decode(token, settings.JWT_SECRET, algorithms=[settings.JWT_ALGORITHM])
    except JWTError:
        return None


async def create_user_with_loyalty(
    db: AsyncSession,
    phone: str,
) -> Profile:
    """Create a new user (phone-only, no password) with a loyalty account."""
    user_id = uuid.uuid4()
    ref_code = f"TOOLOR-{str(user_id)[:8].upper()}"
    qr_code = f"TOOLOR-{str(user_id).replace('-', '')[:12].upper()}"

    user = Profile(
        id=user_id,
        phone=phone,
        password_hash="",
        full_name="",
        referral_code=ref_code,
    )
    db.add(user)

    loyalty = LoyaltyAccount(
        user_id=user_id,
        qr_code=qr_code,
        tier="bronze",
        points=0,
        total_spent=0,
    )
    db.add(loyalty)

    await db.flush()
    return user
