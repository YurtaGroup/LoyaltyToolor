# Finik Payment Integration — Setup Guide

## Current state

TOOLOR accepts payments via Finik SDK (in-app: QR, APP, VISA). The flow has two confirmation paths for redundancy — whichever fires first updates the order.

## Payment flow

```
User → Checkout → Finik SDK (in-app)
                      ↓
                  Finik Gateway
                      ↓
          ┌───────────┴───────────┐
          ↓                       ↓
    Client callback         Server webhook
    (onPayment in            (POST /api/v1/
     Flutter app)             webhooks/finik)
          ↓                       ↓
    POST /orders/{id}/      Direct DB update
    confirm-payment         (server-to-server)
          ↓                       ↓
          └──────────┬────────────┘
                     ↓
            Update order.status=payment_confirmed
            Award loyalty points (idempotent)
            Send notification
            Mark transaction_id to prevent replay
```

## Configuration needed

### 1. In Flutter app (already wired)
Build with these flags:
```bash
flutter build ipa --release \
  --dart-define=FINIK_API_KEY=<key-from-finik> \
  --dart-define=FINIK_ACCOUNT_ID=<account-from-finik> \
  --dart-define=FINIK_BETA=false
```

Current production values are embedded in the TestFlight build 11.

### 2. On Finik side (you must configure)
Tell Finik to POST webhook notifications to:
```
https://loyaltytoolor-xwwj.onrender.com/api/v1/webhooks/finik
```

Method: `POST`
Content-Type: `application/json`

Expected payload format:
```json
{
  "status": "SUCCEEDED" | "FAILED",
  "transactionId": "unique-txn-id",
  "fields": {
    "order_id": "uuid-of-order"
  }
}
```

### 3. On Render (optional but recommended)
Set `FINIK_WEBHOOK_SECRET` env var to enable HMAC-SHA256 signature verification.

Finik must send the signature in header:
```
X-Finik-Signature: <hex-hmac-sha256(body, secret)>
```

Without this env var set, the webhook accepts all requests (logged as warning).

## Webhook behavior

| Scenario | Response | Action |
|---|---|---|
| Valid SUCCEEDED + new txn | `{"ok":true,"action":"confirmed"}` | Order → payment_confirmed, points awarded |
| Same txn already used | `{"ok":true,"action":"duplicate_transaction"}` | Nothing (replay protection) |
| Order already confirmed | `{"ok":true,"action":"already_confirmed"}` | Nothing (idempotent) |
| Order ID not found | `{"ok":true,"action":"order_not_found"}` | Nothing |
| status=FAILED | `{"ok":true,"action":"ignored"}` | Nothing |
| Invalid HMAC signature | `HTTP 403` | Rejected |

All return 200 (except signature failure) so Finik doesn't retry indefinitely.

## Testing the webhook

```bash
# Simulate successful payment
curl -X POST https://loyaltytoolor-xwwj.onrender.com/api/v1/webhooks/finik \
  -H "Content-Type: application/json" \
  -d '{
    "status": "SUCCEEDED",
    "transactionId": "test-123",
    "fields": {"order_id": "<real-order-uuid>"}
  }'
```

## Manual fallback

If Finik webhook fails to fire, admin can manually confirm via admin panel:
Orders page → select order → change status to "Оплата подтверждена"

This path also awards loyalty points (with idempotency — safe to call multiple times).

## Abandoned orders

Orders stuck in `pending` (never confirmed) can be cleaned up by admin:
```
POST /api/v1/admin/orders/cleanup-abandoned?older_than_hours=24
```

Returns inventory held by those orders back to stock.
