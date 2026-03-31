import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_send_otp(client: AsyncClient):
    resp = await client.post("/api/v1/auth/send-otp", json={
        "phone": "+996555111001",
    })
    assert resp.status_code == 200
    data = resp.json()
    assert "otp_code" in data
    assert len(data["otp_code"]) == 4


@pytest.mark.asyncio
async def test_verify_otp_new_user(client: AsyncClient):
    """OTP verification should create a new user and return tokens."""
    phone = "+996555111002"
    # Send OTP
    send_resp = await client.post("/api/v1/auth/send-otp", json={"phone": phone})
    otp_code = send_resp.json()["otp_code"]

    # Verify OTP
    resp = await client.post("/api/v1/auth/verify-otp", json={
        "phone": phone,
        "otp_code": otp_code,
    })
    assert resp.status_code == 200
    data = resp.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["token_type"] == "bearer"


@pytest.mark.asyncio
async def test_verify_otp_existing_user(client: AsyncClient):
    """Second OTP login for same phone should return tokens (not create duplicate)."""
    phone = "+996555111003"

    # First login — creates user
    send1 = await client.post("/api/v1/auth/send-otp", json={"phone": phone})
    otp1 = send1.json()["otp_code"]
    resp1 = await client.post("/api/v1/auth/verify-otp", json={
        "phone": phone, "otp_code": otp1,
    })
    assert resp1.status_code == 200

    # Second login — same user
    send2 = await client.post("/api/v1/auth/send-otp", json={"phone": phone})
    otp2 = send2.json()["otp_code"]
    resp2 = await client.post("/api/v1/auth/verify-otp", json={
        "phone": phone, "otp_code": otp2,
    })
    assert resp2.status_code == 200
    assert "access_token" in resp2.json()


@pytest.mark.asyncio
async def test_verify_otp_wrong_code(client: AsyncClient):
    phone = "+996555111004"
    await client.post("/api/v1/auth/send-otp", json={"phone": phone})

    resp = await client.post("/api/v1/auth/verify-otp", json={
        "phone": phone,
        "otp_code": "0000",
    })
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_verify_otp_without_sending(client: AsyncClient):
    resp = await client.post("/api/v1/auth/verify-otp", json={
        "phone": "+996555999999",
        "otp_code": "1234",
    })
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_otp_single_use(client: AsyncClient):
    """OTP code should only work once."""
    phone = "+996555111005"
    send_resp = await client.post("/api/v1/auth/send-otp", json={"phone": phone})
    otp_code = send_resp.json()["otp_code"]

    # First use — success
    resp1 = await client.post("/api/v1/auth/verify-otp", json={
        "phone": phone, "otp_code": otp_code,
    })
    assert resp1.status_code == 200

    # Second use — fail
    resp2 = await client.post("/api/v1/auth/verify-otp", json={
        "phone": phone, "otp_code": otp_code,
    })
    assert resp2.status_code == 401


@pytest.mark.asyncio
async def test_refresh_token(client: AsyncClient):
    phone = "+996555111006"
    send_resp = await client.post("/api/v1/auth/send-otp", json={"phone": phone})
    otp_code = send_resp.json()["otp_code"]

    verify_resp = await client.post("/api/v1/auth/verify-otp", json={
        "phone": phone, "otp_code": otp_code,
    })
    refresh_token = verify_resp.json()["refresh_token"]

    resp = await client.post("/api/v1/auth/refresh", json={
        "refresh_token": refresh_token,
    })
    assert resp.status_code == 200
    assert "access_token" in resp.json()


@pytest.mark.asyncio
async def test_refresh_invalid_token(client: AsyncClient):
    resp = await client.post("/api/v1/auth/refresh", json={
        "refresh_token": "invalid-token",
    })
    assert resp.status_code == 401
