import uuid
from datetime import datetime, timedelta, timezone

import bcrypt
import httpx
from jose import JWTError, jwt
from google.oauth2 import id_token as google_id_token
from google.auth.transport import requests as google_requests
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.models.loyalty import LoyaltyAccount
from app.models.user import Profile

# ── Apple JWKS cache ──────────────────────────────────────────────────
_apple_jwks: dict | None = None


async def _get_apple_public_keys() -> dict:
    """Fetch Apple's public keys for Sign in with Apple JWT verification."""
    global _apple_jwks
    if _apple_jwks is None:
        async with httpx.AsyncClient() as client:
            resp = await client.get("https://appleid.apple.com/auth/keys")
            resp.raise_for_status()
            _apple_jwks = resp.json()
    return _apple_jwks


async def verify_apple_identity_token(identity_token: str) -> dict:
    """Verify an Apple identity token and return its claims.

    Returns dict with 'sub' (Apple user ID) and optionally 'email'.
    Raises ValueError on invalid token.
    """
    jwks = await _get_apple_public_keys()

    # Decode header to find the right key
    header = jwt.get_unverified_header(identity_token)
    kid = header.get("kid")

    key = None
    for k in jwks.get("keys", []):
        if k["kid"] == kid:
            key = k
            break
    if not key:
        # Refresh keys in case Apple rotated them
        global _apple_jwks
        _apple_jwks = None
        jwks = await _get_apple_public_keys()
        for k in jwks.get("keys", []):
            if k["kid"] == kid:
                key = k
                break
    if not key:
        raise ValueError("Apple public key not found for kid")

    claims = jwt.decode(
        identity_token,
        key,
        algorithms=["RS256"],
        audience="com.toolor.toolorApp",
        issuer="https://appleid.apple.com",
    )
    return claims


def verify_google_id_token(token: str) -> dict:
    """Verify a Google ID token and return its claims.

    Returns dict with 'sub' (Google user ID), 'email', 'name', etc.
    Raises ValueError on invalid token.
    """
    claims = google_id_token.verify_oauth2_token(
        token, google_requests.Request()
    )
    if claims.get("iss") not in ("accounts.google.com", "https://accounts.google.com"):
        raise ValueError("Invalid Google token issuer")
    return claims


def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()


def verify_password(plain: str, hashed: str) -> bool:
    return bcrypt.checkpw(plain.encode(), hashed.encode())


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
    password: str,
    full_name: str = "",
    referred_by: uuid.UUID | None = None,
) -> Profile:
    user_id = uuid.uuid4()
    ref_code = f"TOOLOR-{str(user_id)[:8].upper()}"
    qr_code = f"TOOLOR-{str(user_id).replace('-', '')[:12].upper()}"

    user = Profile(
        id=user_id,
        phone=phone,
        password_hash=hash_password(password),
        full_name=full_name,
        referral_code=ref_code,
        referred_by=referred_by,
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


async def create_oauth_user_with_loyalty(
    db: AsyncSession,
    *,
    full_name: str = "",
    email: str | None = None,
    apple_id: str | None = None,
    google_id: str | None = None,
) -> Profile:
    """Create a user from OAuth sign-in (no phone/password required)."""
    user_id = uuid.uuid4()
    ref_code = f"TOOLOR-{str(user_id)[:8].upper()}"
    qr_code = f"TOOLOR-{str(user_id).replace('-', '')[:12].upper()}"

    user = Profile(
        id=user_id,
        full_name=full_name,
        email=email,
        apple_id=apple_id,
        google_id=google_id,
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
