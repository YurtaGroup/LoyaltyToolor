from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import get_db
from app.models.loyalty import LoyaltyAccount
from app.models.user import Profile
from app.config import settings
from app.schemas.auth import AppleAuthRequest, LoginRequest, RefreshRequest, RegisterRequest, TokenResponse
from app.services.auth_service import (
    create_access_token,
    create_refresh_token,
    create_user_with_loyalty,
    verify_password,
    verify_token,
)
from app.services.apple_auth_service import verify_apple_identity_token
from app.services.loyalty_service import check_birthday_reward
from app.services.analytics_service import track_signup, track_login
from app.services.event_logger import log_event

router = APIRouter()


@router.post("/register", response_model=TokenResponse)
async def register(body: RegisterRequest, db: AsyncSession = Depends(get_db)):
    existing = await db.execute(select(Profile).where(Profile.phone == body.phone))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Phone already registered")

    referred_by = None
    if body.referral_code:
        ref_result = await db.execute(
            select(Profile).where(Profile.referral_code == body.referral_code)
        )
        referrer = ref_result.scalar_one_or_none()
        if referrer:
            referred_by = referrer.id

    user = await create_user_with_loyalty(
        db, body.phone, body.password, body.full_name, referred_by
    )
    await log_event(db, user.id, "signup", {"method": "phone"})
    await db.commit()
    track_signup(str(user.id), body.phone, body.referral_code)
    return TokenResponse(
        access_token=create_access_token(user),
        refresh_token=create_refresh_token(user),
    )


@router.post("/login", response_model=TokenResponse)
async def login(body: LoginRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Profile).where(Profile.phone == body.phone))
    user = result.scalar_one_or_none()
    if not user or not verify_password(body.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid phone or password")

    # Check birthday reward on login
    if user.birth_date:
        loyalty_result = await db.execute(
            select(LoyaltyAccount).where(LoyaltyAccount.user_id == user.id)
        )
        loyalty = loyalty_result.scalar_one_or_none()
        if loyalty:
            await check_birthday_reward(db, user, loyalty)
            await db.commit()

    await log_event(db, user.id, "login", {"method": "phone"})
    await db.commit()
    track_login(str(user.id))
    return TokenResponse(
        access_token=create_access_token(user),
        refresh_token=create_refresh_token(user),
    )


@router.post("/apple", response_model=TokenResponse)
async def apple_auth(body: AppleAuthRequest, db: AsyncSession = Depends(get_db)):
    """Sign in with Apple: verify identity token, find or create user."""
    try:
        claims = await verify_apple_identity_token(
            body.identity_token,
            settings.APPLE_BUNDLE_ID,
        )
    except ValueError as e:
        raise HTTPException(status_code=401, detail=str(e))

    apple_sub = claims["sub"]  # Apple's unique user ID

    # Look up existing user by apple_id
    result = await db.execute(select(Profile).where(Profile.apple_id == apple_sub))
    user = result.scalar_one_or_none()

    if user is None:
        # First time — create account
        import uuid

        user_id = uuid.uuid4()
        ref_code = f"TOOLOR-{str(user_id)[:8].upper()}"
        qr_code = f"TOOLOR-{str(user_id).replace('-', '')[:12].upper()}"

        email = claims.get("email")
        name = body.full_name or email or "Apple User"

        user = Profile(
            id=user_id,
            phone=f"apple_{apple_sub[:16]}",  # placeholder phone for Apple users
            password_hash="APPLE_OAUTH",  # no password — Apple-only auth
            full_name=name,
            email=email,
            apple_id=apple_sub,
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
        await log_event(db, user.id, "signup", {"method": "apple"})
        await db.commit()

        track_signup(str(user.id), user.phone)
    else:
        # Existing user — update email if newly shared
        if claims.get("email") and not user.email:
            user.email = claims["email"]
        if body.full_name and user.full_name in ("", "Apple User"):
            user.full_name = body.full_name
        await log_event(db, user.id, "login", {"method": "apple"})
        await db.commit()

        track_login(str(user.id))

    # Check birthday reward
    if user.birth_date:
        loyalty_result = await db.execute(
            select(LoyaltyAccount).where(LoyaltyAccount.user_id == user.id)
        )
        loyalty = loyalty_result.scalar_one_or_none()
        if loyalty:
            await check_birthday_reward(db, user, loyalty)
            await db.commit()

    return TokenResponse(
        access_token=create_access_token(user),
        refresh_token=create_refresh_token(user),
    )


@router.post("/refresh", response_model=TokenResponse)
async def refresh(body: RefreshRequest, db: AsyncSession = Depends(get_db)):
    payload = verify_token(body.refresh_token)
    if not payload or payload.get("type") != "refresh":
        raise HTTPException(status_code=401, detail="Invalid refresh token")
    user = await db.get(Profile, payload["sub"])
    if not user:
        raise HTTPException(status_code=401, detail="User not found")
    return TokenResponse(
        access_token=create_access_token(user),
        refresh_token=create_refresh_token(user),
    )
