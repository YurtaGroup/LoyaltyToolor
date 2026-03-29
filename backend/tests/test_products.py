import uuid

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.product import Category, Subcategory, Product


async def _seed_catalog(db: AsyncSession):
    cat = Category(id=uuid.uuid4(), name="Куртки", slug="kurtki")
    db.add(cat)

    sub = Subcategory(id=uuid.uuid4(), name="Зимние", slug="zimnie", category_id=cat.id)
    db.add(sub)

    for i in range(3):
        db.add(Product(
            id=uuid.uuid4(),
            name=f"Куртка {i+1}",
            slug=f"kurtka-{i+1}-{uuid.uuid4().hex[:6]}",
            price=3000 + i * 1000,
            category_id=cat.id,
            subcategory_id=sub.id,
            image_url=f"https://example.com/jacket-{i+1}.jpg",
            stock=5,
        ))
    await db.commit()


@pytest.mark.asyncio
async def test_list_products(client: AsyncClient, db: AsyncSession):
    await _seed_catalog(db)

    resp = await client.get("/api/v1/products")
    assert resp.status_code == 200
    data = resp.json()
    assert "items" in data
    assert len(data["items"]) >= 3


@pytest.mark.asyncio
async def test_list_categories(client: AsyncClient, db: AsyncSession):
    await _seed_catalog(db)

    resp = await client.get("/api/v1/products/categories")
    assert resp.status_code == 200
    data = resp.json()
    assert len(data) >= 1


@pytest.mark.asyncio
async def test_product_not_found(client: AsyncClient):
    fake_id = str(uuid.uuid4())
    resp = await client.get(f"/api/v1/products/{fake_id}")
    assert resp.status_code == 404
