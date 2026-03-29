import uuid

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.cart import CartItem
from app.models.product import Category, Subcategory, Product
from app.models.user import Profile


async def _seed_product(db: AsyncSession) -> uuid.UUID:
    """Create a category, subcategory, and product for order tests."""
    cat_id = uuid.uuid4()
    cat = Category(id=cat_id, name="Test Category", slug="test-cat")
    db.add(cat)

    sub_id = uuid.uuid4()
    sub = Subcategory(id=sub_id, name="Test Sub", slug="test-sub", category_id=cat_id)
    db.add(sub)

    prod_id = uuid.uuid4()
    prod = Product(
        id=prod_id,
        name="Test Jacket",
        slug=f"test-jacket-{prod_id.hex[:8]}",
        price=5000,
        category_id=cat_id,
        subcategory_id=sub_id,
        image_url="https://example.com/jacket.jpg",
        stock=10,
    )
    db.add(prod)
    await db.flush()
    return prod_id


async def _add_to_cart(db: AsyncSession, user_id: uuid.UUID, product_id: uuid.UUID):
    """Add a product to user's cart."""
    cart_item = CartItem(
        user_id=user_id,
        product_id=product_id,
        quantity=1,
        selected_size="M",
    )
    db.add(cart_item)
    await db.commit()


@pytest.mark.asyncio
async def test_create_order(client: AsyncClient, auth_headers: dict, test_user: Profile, db: AsyncSession):
    prod_id = await _seed_product(db)
    await _add_to_cart(db, test_user.id, prod_id)

    resp = await client.post("/api/v1/orders", json={
        "payment_method": "finik",
        "delivery_type": "pickup",
    }, headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "pending"
    assert data["total"] == "5000.00"
    assert data["payment_method"] == "finik"
    assert "TOOLOR-" in data["order_number"]


@pytest.mark.asyncio
async def test_create_order_empty_cart(client: AsyncClient, auth_headers: dict):
    resp = await client.post("/api/v1/orders", json={
        "payment_method": "finik",
        "delivery_type": "pickup",
    }, headers=auth_headers)
    assert resp.status_code == 400
    assert "empty" in resp.json()["detail"].lower()


@pytest.mark.asyncio
async def test_get_my_orders(client: AsyncClient, auth_headers: dict):
    resp = await client.get("/api/v1/orders/me", headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert "items" in data
    assert "total" in data


@pytest.mark.asyncio
async def test_confirm_finik_payment(
    client: AsyncClient, auth_headers: dict, test_user: Profile, db: AsyncSession
):
    prod_id = await _seed_product(db)
    await _add_to_cart(db, test_user.id, prod_id)

    create_resp = await client.post("/api/v1/orders", json={
        "payment_method": "finik",
        "delivery_type": "delivery",
    }, headers=auth_headers)
    assert create_resp.status_code == 200
    order_id = create_resp.json()["id"]

    confirm_resp = await client.post(
        f"/api/v1/orders/{order_id}/confirm-payment",
        json={
            "status": "SUCCEEDED",
            "transactionId": "txn-test-12345",
            "amount": 5000.0,
        },
        headers=auth_headers,
    )
    assert confirm_resp.status_code == 200
    assert confirm_resp.json()["status"] == "payment_confirmed"
    assert confirm_resp.json()["payment_transaction_id"] == "txn-test-12345"
    assert confirm_resp.json()["payment_provider"] == "finik"


@pytest.mark.asyncio
async def test_cancel_order(client: AsyncClient, auth_headers: dict, test_user: Profile, db: AsyncSession):
    prod_id = await _seed_product(db)
    await _add_to_cart(db, test_user.id, prod_id)

    create_resp = await client.post("/api/v1/orders", json={
        "payment_method": "finik",
        "delivery_type": "pickup",
    }, headers=auth_headers)
    order_id = create_resp.json()["id"]

    cancel_resp = await client.post(
        f"/api/v1/orders/{order_id}/cancel",
        headers=auth_headers,
    )
    assert cancel_resp.status_code == 200
    assert cancel_resp.json()["status"] == "cancelled"


@pytest.mark.asyncio
async def test_finik_webhook(client: AsyncClient, test_user: Profile, db: AsyncSession, auth_headers: dict):
    prod_id = await _seed_product(db)
    await _add_to_cart(db, test_user.id, prod_id)

    create_resp = await client.post("/api/v1/orders", json={
        "payment_method": "finik",
        "delivery_type": "pickup",
    }, headers=auth_headers)
    order_id = create_resp.json()["id"]

    # Simulate Finik webhook call (no auth required)
    webhook_resp = await client.post("/api/v1/webhooks/finik", json={
        "status": "SUCCEEDED",
        "transactionId": "txn-webhook-99",
        "amount": 5000.0,
        "fields": {"order_id": order_id},
    })
    assert webhook_resp.status_code == 200
    assert webhook_resp.json()["action"] == "confirmed"

    # Verify order is confirmed
    order_resp = await client.get(
        f"/api/v1/orders/{order_id}",
        headers=auth_headers,
    )
    assert order_resp.json()["status"] == "payment_confirmed"


@pytest.mark.asyncio
async def test_order_unauthenticated(client: AsyncClient):
    resp = await client.post("/api/v1/orders", json={
        "payment_method": "finik",
        "delivery_type": "pickup",
    })
    assert resp.status_code == 403
