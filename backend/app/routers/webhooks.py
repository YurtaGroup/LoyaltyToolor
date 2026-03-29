import logging
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, Request
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.dependencies import get_db
from app.models.notification import Notification
from app.models.order import Order

logger = logging.getLogger(__name__)

router = APIRouter()


@router.post("/finik")
async def finik_webhook(request: Request, db: AsyncSession = Depends(get_db)):
    """Server-to-server webhook called by Finik after payment completes."""
    body = await request.json()
    logger.info("Finik webhook received: %s", body)

    status = body.get("status")
    fields = body.get("fields", {})
    order_id = fields.get("order_id")
    transaction_id = body.get("transactionId")

    if not order_id or status != "SUCCEEDED":
        return {"ok": True, "action": "ignored"}

    result = await db.execute(
        select(Order)
        .options(selectinload(Order.items))
        .where(Order.id == order_id)
    )
    order = result.scalar_one_or_none()
    if not order:
        logger.warning("Finik webhook: order %s not found", order_id)
        return {"ok": True, "action": "order_not_found"}

    if order.status in ("payment_confirmed", "processing", "shipped", "delivered"):
        return {"ok": True, "action": "already_confirmed"}

    order.status = "payment_confirmed"
    order.payment_transaction_id = transaction_id
    order.payment_provider = "finik"
    order.confirmed_at = datetime.now(timezone.utc)

    notification = Notification(
        user_id=order.user_id,
        type="order_status",
        title=f"Заказ #{order.order_number}",
        body="Оплата подтверждена",
        data={"order_id": str(order.id), "status": "payment_confirmed"},
    )
    db.add(notification)

    await db.commit()
    logger.info("Finik webhook: order %s confirmed via webhook", order_id)
    return {"ok": True, "action": "confirmed"}
