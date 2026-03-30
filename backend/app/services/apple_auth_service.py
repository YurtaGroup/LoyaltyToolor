"""Apple Sign In — verify identity tokens using Apple's public JWKS.

Flow:
1. Flutter client calls Sign in with Apple → gets identityToken (JWT)
2. Client sends identityToken to POST /api/v1/auth/apple
3. We fetch Apple's public keys, verify the JWT signature + claims
4. Extract apple user id (sub) and optional email/name
5. Find-or-create Profile with apple_id = sub
"""

import logging
from datetime import datetime, timezone

import httpx
from jose import JWTError, jwk, jwt
from jose.utils import base64url_decode

logger = logging.getLogger("toolor")

APPLE_JWKS_URL = "https://appleid.apple.com/auth/keys"
APPLE_ISSUER = "https://appleid.apple.com"

# Cache Apple's public keys in memory (refreshed on miss)
_apple_keys: list[dict] | None = None


async def _fetch_apple_keys() -> list[dict]:
    """Fetch Apple's current public signing keys."""
    global _apple_keys
    async with httpx.AsyncClient() as client:
        resp = await client.get(APPLE_JWKS_URL, timeout=10)
        resp.raise_for_status()
        _apple_keys = resp.json()["keys"]
    return _apple_keys


def _get_key_for_token(token: str, keys: list[dict]) -> dict:
    """Find the correct Apple public key by matching the JWT header's 'kid'."""
    headers = jwt.get_unverified_headers(token)
    kid = headers.get("kid")
    for key in keys:
        if key["kid"] == kid:
            return key
    raise JWTError(f"No matching Apple key found for kid={kid}")


async def verify_apple_identity_token(identity_token: str, bundle_id: str) -> dict:
    """Verify an Apple identity token and return the decoded claims.

    Returns dict with at least: sub, iss, aud, email (if shared).
    Raises ValueError on any verification failure.
    """
    global _apple_keys

    # Fetch keys if not cached
    keys = _apple_keys or await _fetch_apple_keys()

    try:
        apple_key = _get_key_for_token(identity_token, keys)
    except JWTError:
        # Key might have rotated — refetch once
        keys = await _fetch_apple_keys()
        try:
            apple_key = _get_key_for_token(identity_token, keys)
        except JWTError as e:
            raise ValueError(f"Apple key not found: {e}")

    # Build RSA public key from JWK
    public_key = jwk.construct(apple_key)

    try:
        claims = jwt.decode(
            identity_token,
            public_key,
            algorithms=["RS256"],
            audience=bundle_id,
            issuer=APPLE_ISSUER,
        )
    except JWTError as e:
        logger.warning(f"Apple token verification failed: {e}")
        raise ValueError(f"Invalid Apple token: {e}")

    # Validate token hasn't expired (jose does this, but be safe)
    exp = claims.get("exp", 0)
    if datetime.now(timezone.utc).timestamp() > exp:
        raise ValueError("Apple token expired")

    return claims
