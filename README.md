# Toolor Customer App

Flutter customer-facing app for the Toolor loyalty and retail platform.

## Backend

This app connects to the **cool-group** backend (not the legacy LoyaltyToolor backend which has been decommissioned).

- Production API: `https://coolgroup-api.onrender.com`
- Compatibility layer: `/api/v1/*` endpoints on cool-group translate to native endpoints
- Source: [cool-group repo](https://github.com/YurtaGroup/cool-group)

## Build

```bash
# Development (default URL already points to cool-group prod)
flutter run

# Production APK
flutter build apk --release \
  --dart-define=FINIK_API_KEY=<key> \
  --dart-define=FINIK_ACCOUNT_ID=<account_id> \
  --dart-define=FINIK_BETA=false

# Production iOS
flutter build ipa --release \
  --dart-define=FINIK_API_KEY=<key> \
  --dart-define=FINIK_ACCOUNT_ID=<account_id> \
  --dart-define=FINIK_BETA=false
```

To override the API URL (e.g., for staging):
```bash
flutter run --dart-define=API_URL=https://staging-api.example.com
```

## Features

- SMS OTP login (Nikita.kg)
- Product catalog with categories
- Shopping cart + checkout
- Finik payment (QR / APP / VISA)
- Loyalty tiers (Kulun / Tai / Kunan / At) with cashback
- QR code for in-store loyalty scanning
- Order history + cancellation
- Push notifications (Firebase)
