# Guest Mode + Anonymous Tracking — Design

**Date:** 2026-04-14
**Project:** LoyaltyToolor (Flutter app) + cool group backend
**Status:** Approved for planning

## Goal

Allow unauthenticated users to browse the app (home, catalog, products), while gating personal/transactional actions (loyalty QR, checkout, favorites, promo codes, profile) behind login. Track guest activity on the backend under an anonymous device-bound identity, and merge the activity into the real customer record when the guest registers.

## Non-goals

- Server-side guest cart or guest favorites.
- GDPR-style guest data deletion endpoints.
- Refresh tokens for guests (long TTL is enough).
- Anonymizing already-merged guest sessions.

## Backend changes (cool group)

### New tables

**`guest_sessions`** (new module file `app/customers/guest_models.py` or appended to `app/customers/models.py`):

| column                  | type            | notes                                            |
|-------------------------|-----------------|--------------------------------------------------|
| id                      | uuid pk         | default uuid4                                    |
| device_id               | varchar(64)     | unique, not null — generated client-side         |
| platform                | varchar(20)     | `ios` / `android` / `macos`                      |
| app_version             | varchar(20)     | nullable                                         |
| locale                  | varchar(5)      | nullable                                         |
| first_seen_at           | timestamptz     | server_default now()                             |
| last_seen_at            | timestamptz     | onupdate now()                                   |
| merged_to_customer_id   | uuid fk         | nullable, → customers.id ON DELETE SET NULL      |
| merged_at               | timestamptz     | nullable                                         |

Index: `ix_guest_sessions_device_id` (unique), `ix_guest_sessions_merged_to_customer_id`.

**`customer_events`** (same module, single table for both guest and registered actors):

| column        | type          | notes                                                                       |
|---------------|---------------|-----------------------------------------------------------------------------|
| id            | uuid pk       | default uuid4                                                                |
| actor_type    | varchar(10)   | `guest` or `customer` — current owner of the row                             |
| actor_id      | uuid          | guest_session_id or customer_id; no FK (would require polymorphic constraint)|
| session_id    | uuid          | always the originating guest_session_id (preserved through merge)            |
| event_type    | varchar(50)   | `view_product`, `view_category`, `view_banner`, `add_to_cart`, `share_product`, `search`, `view_promo`, `open_qr_gate`, `register_started`, `register_completed` |
| payload       | jsonb         | `{}` if no payload                                                           |
| created_at    | timestamptz   | server_default now()                                                         |

Indexes: `(actor_id, created_at desc)`, `(event_type, created_at desc)`, `(session_id)`.

### Alembic migration

One migration file: creates both tables with the indexes above. No data backfill needed.

### Auth changes

**`app/auth/security.py`** — add:
- `create_guest_token(guest_session_id: UUID) -> str` — JWT with `sub=<guest_session_id>`, `type="guest"`, exp = now + 90 days.
- `decode_guest_token(token: str) -> dict | None`.

**`app/auth/dependencies.py`** — add:
- `get_current_guest(...)` — extracts and validates a guest token. Raises 401 on invalid/missing.
- `get_current_actor(...)` — accepts either guest or customer token, returns a small dataclass `Actor(type: Literal["guest","customer"], id: UUID)`. Raises 401 if neither valid.

`get_current_customer` stays unchanged — guest tokens never authorize customer-only endpoints.

### New endpoints

**`POST /api/me/guest/init`** (in `app/auth/customer_router.py` or a new `app/customers/guest_router.py`):

Body:
```json
{ "device_id": "uuid-v4-string", "platform": "ios", "app_version": "1.0.0", "locale": "ru" }
```

Response:
```json
{ "guest_id": "uuid", "guest_token": "jwt", "expires_in": 7776000 }
```

Behavior:
- Idempotent on `device_id`. If a row exists, update `last_seen_at`, `platform`, `app_version`, `locale` and return the existing `guest_id`. Otherwise insert a new row.
- If the existing row has `merged_to_customer_id IS NOT NULL`, still return its `guest_id` and `guest_token` — the device can still post events as a guest *until* the user logs in again on this device. (The events will land under `actor_type=guest` and a future login will merge again into the same customer.) The simpler alternative is to refuse re-issuing guest tokens for merged sessions; we deliberately go with the permissive option to keep client logic dumb.
- Rate limit: per-IP, 30 requests/hour, fail-open.

**`POST /api/me/events`** (new router `app/customers/events_router.py`):

Body:
```json
{
  "events": [
    { "type": "view_product", "payload": { "product_id": "uuid", "source": "home_new" }, "occurred_at": "2026-04-14T12:00:00Z" }
  ]
}
```

Auth: `Depends(get_current_actor)` — accepts both token types.

Behavior:
- Validate batch (max 50 events per request).
- For each event, insert into `customer_events` with `actor_type=actor.type`, `actor_id=actor.id`, `session_id` resolved as:
  - If `actor.type == 'guest'`, `session_id = actor.id`.
  - If `actor.type == 'customer'`, look up the most recent `guest_session.id WHERE merged_to_customer_id = actor.id`, fall back to a freshly generated UUID if none (rare — customer who never had a guest session).
- Returns `{ "accepted": <count> }`. Never 5xx on individual event errors — log and skip.
- Rate limit: per-actor, 200 events/minute, fail-open.

### `verify-otp` extension

`POST /api/me/auth/verify-otp` — extend `VerifyOtpBody` with optional `guest_id: str | None = None`.

After successful customer auth, call `merge_guest_into_customer(db, guest_id, customer.id)` (in a new `app/customers/merge_service.py`) using the same `AsyncSession` as the verify-otp endpoint, so the merge commits atomically with the customer creation:

```
async def merge_guest_into_customer(db, guest_id, customer_id):
    guest = await db.get(GuestSession, guest_id)
    if guest is None or guest.merged_to_customer_id is not None:
        return  # idempotent
    # Update customer_events: rewrite actor pointer; preserve session_id
    await db.execute(
        update(CustomerEvent)
        .where(CustomerEvent.actor_type == 'guest')
        .where(CustomerEvent.actor_id == guest_id)
        .values(actor_type='customer', actor_id=customer_id)
    )
    guest.merged_to_customer_id = customer_id
    guest.merged_at = func.now()
    # Insert audit event
    db.add(CustomerEvent(
        actor_type='customer', actor_id=customer_id, session_id=guest_id,
        event_type='register_completed', payload={}
    ))
```

If `guest_id` is missing or invalid, verify-otp still succeeds — the merge is best-effort. The endpoint never returns an error because of merge problems; it logs them.

### `app/main.py`

Wire two new routers: guest router (or extension to customer_router) and events router.

## Frontend changes (LoyaltyToolor)

### New files

**`lib/services/device_id_service.dart`** — generate-or-load a UUID v4 in SharedPreferences under `device_id`. Idempotent. Pure Dart, no platform code.

**`lib/services/analytics_service.dart`** — singleton with:
- `track(String type, {Map<String, dynamic>? payload})` — appends to in-memory queue with `occurredAt = DateTime.now().toUtc()`.
- Auto-flush every 10 seconds OR when queue length ≥ 20, whichever first.
- `flush()` — POST `/api/me/events` with up to 50 events. On success, drop them. On failure, keep them and retry on the next tick. Max queue size: 200 (oldest dropped if exceeded).
- `init()` — schedules the periodic timer. Called once from `ApiService.init()`.
- Authenticated automatically because the request goes through `ApiService.dio` (interceptor attaches whichever token is current).

### Modified files

**`lib/services/api_service.dart`**

- New constants: `_kGuestAccessToken = 'guest_access_token'`.
- New method `bootstrapGuest()`:
  - Called from `init()` after token load.
  - If `customer_token` is present, do nothing.
  - Else if `guest_token` is present and not expired (decode locally), do nothing.
  - Else: read device_id from `DeviceIdService`, POST to `/api/me/guest/init`, store the returned `guest_token` securely.
- Update Dio request interceptor: prefer `customer_access_token`; if absent, attach `guest_access_token`. Logout flow keeps `guest_token` (we want the same anonymous identity after logout).
- 401 interceptor: if request was made with `guest_token` and got 401 → call `bootstrapGuest()` and retry once. If with `customer_token` → existing behavior (clear customer tokens, drop to guest).

**`lib/providers/auth_provider.dart`**

- `verifyOtp(phone, otp)` — read `guest_id` from local storage (decoded from `guest_token` payload, or stored separately during `bootstrapGuest`), and pass it to `ApiService.verifyOtp`.
- After successful login, the on-device `guest_token` stays untouched. The interceptor will start preferring `customer_token` automatically.
- `logout()` — clears customer tokens but keeps `guest_token` and device_id. Same anonymous identity remains.

**`lib/providers/cart_provider.dart`**

- Add SharedPreferences persistence for the `!isLoggedIn` branch (key `guest_cart_v1`, JSON-encoded list of items).
- New method `Future<void> syncLocalCartToServer()` — pushes each local item via existing add-to-cart endpoint, clears local on success.
- Hook in `main.dart`: when `auth.isLoggedIn` flips false→true, after `fetchProfile/fetchLoyalty`, call `cart.syncLocalCartToServer()` (parallel with favorites sync).

**`lib/screens/home_screen.dart`**

- Delete `_welcome()` method.
- `build()`: remove the `if (!auth.isLoggedIn) return _welcome(...)` short-circuit. Always render `_home(...)`.
- `_home()`: where the loyalty card currently sits, render either:
  - `auth.isLoggedIn && loyalty != null` → existing loyalty card.
  - else → compact CTA banner with copy "Войти и получать бонусы" and a single button that pushes `AuthScreen`. (No specific cashback percent — keep static so we don't have to fetch tier config for a guest banner.)
- Greeting line: if guest, show `"Добро пожаловать"` instead of `"Привет, {name}"`.
- Drop loading-spinner branch tied to `auth.isLoading && !auth.isLoggedIn` — guests don't have a loading state.
- Loyalty-retry block (`_loyaltyRetried`) should run only when `auth.isLoggedIn`.

**`lib/main.dart`**

- Remove the welcome-screen path.
- Bottom nav `onTap`:
  ```dart
  onTap: (i) async {
    HapticFeedback.selectionClick();
    if (i == 2 && !auth.isLoggedIn) {
      final ok = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
      if (ok == true && mounted) setState(() => _tab = 2);
      return;
    }
    setState(() => _tab = i);
  }
  ```
- `LoyaltyQrScreen` widget instance stays in the IndexedStack — it's just unreachable for guests. (Or replace with a placeholder; either works because nav guards entry. We choose the simpler "leave it" option.)
- Add `await ApiService.bootstrapGuest()` after `ApiService.init()` in `main()`, before `runApp`.

**`lib/screens/auth_screen.dart`**

- After successful `verifyOtp` and any onboarding completion: `Navigator.of(context).pop(true)` so callers can detect a successful login. Existing flows that just dismiss without a result still work — `pop()` without args returns null.

**`lib/screens/cart_screen.dart`**

- "Оформить" button: if `!auth.isLoggedIn`, push `AuthScreen` and bail. After `pop(true)`, retry checkout.

**`lib/widgets/product_card.dart`** (or wherever the favorites button lives — verify during implementation)

- Favorite icon `onTap`: if `!auth.isLoggedIn`, push `AuthScreen` and return. Don't call `toggleFavorite`.

**`lib/screens/product_detail_screen.dart`**

- `initState`: `AnalyticsService.track('view_product', payload: {'product_id': widget.product.id})`.
- Favorites button: same gate as ProductCard.

**`lib/screens/promo_codes_screen.dart`**

- Top-level `build`: if `!auth.isLoggedIn`, show a CTA "Войти" → AuthScreen, then on `pop(true)` the user lands on the now-functional promo screen. (PromoCodesScreen is reachable only from Profile today, but the in-screen guard makes it robust to future entry points.)

### Tracking call sites

These are the events to fire and where:

| event_type        | site                                                |
|-------------------|-----------------------------------------------------|
| view_product      | `ProductDetailScreen.initState`                     |
| view_category     | `CatalogScreen` when a category becomes the active filter |
| view_banner       | `HomeScreen` editorial banner appears (via VisibilityDetector or onTap — **simpler: track on tap only**) |
| share_product     | `ProductDetailScreen` share button — **only if a share button exists today**; if not, drop this event from v1 |
| add_to_cart       | `CartProvider.addItem`                              |
| search            | `CatalogScreen` debounced search query (≥3 chars)   |
| open_qr_gate      | `main.dart` bottom-nav handler when guest taps QR   |
| register_started  | `AuthScreen` when user submits phone                |
| register_completed| backend (in `merge_guest_into_customer`) — frontend does **not** also send this |

## Data flow narrative

1. App launches → `ApiService.init()` loads stored tokens. If no customer token AND no valid guest token → `bootstrapGuest()` POSTs `/api/me/guest/init` with the device_id. Server returns `guest_token`, stored locally.
2. User browses freely. `AnalyticsService` flushes events to `/api/me/events`, authorized with `guest_token`, recording rows with `actor_type='guest'`.
3. User taps QR tab (or favorite, or checkout). Client gates → pushes `AuthScreen`.
4. User completes OTP. Client sends `guest_id` along with the verify-otp call. Server creates/finds the customer, returns `customer_access_token + customer_refresh_token`, runs `merge_guest_into_customer` in the same transaction.
5. After merge, all of the user's previous `customer_events` rows are now `actor_type='customer'`, `actor_id=customer.id`, with `session_id` preserved.
6. Client stores customer tokens. Interceptor now attaches `customer_token`. AuthScreen `pop(true)`. Caller (e.g., bottom nav) finishes its action: switches tab to QR, retries checkout, etc.
7. Logout drops customer tokens but **keeps** the guest token. The user is back to a tracked guest with the same device_id.

## Error handling

- `/guest/init` failure on app launch: app continues without a guest token. Analytics queue grows until either next launch retries successfully or the user logs in. Acceptable.
- `/me/events` failure: events stay in queue, retried next tick. After 200 backlog → drop oldest. Never blocks UI.
- merge service failure: verify-otp still returns 200 with tokens; merge error is logged. A background job (out of scope for this spec) could retry the merge nightly. Acceptable for v1.
- Guest token expired (>90 days): 401 interceptor calls `bootstrapGuest()`, retries once. Same device_id → same `guest_session.id` → no analytics gap.

## Testing strategy

**Backend:**
- Unit tests for `merge_guest_into_customer`: empty merge (no events), normal merge (10 events), idempotent re-call.
- Integration tests for `/guest/init` (idempotency on device_id), `/me/events` (auth modes, batch limit), `/auth/verify-otp` with `guest_id`.

**Frontend:**
- Manual smoke: fresh install → browse → tap QR → AuthScreen → verify OTP → return lands on QR screen with loaded loyalty card.
- Manual smoke: cart → add items as guest → checkout → AuthScreen → after login the cart syncs and checkout proceeds.
- Manual smoke: logout → still see same browse experience, analytics still flowing under guest token.

## Open implementation questions

(To be resolved during the implementation plan, not now.)

- Exact location of the `customer_events` model file: `app/customers/event_models.py` vs `app/customers/models.py`. Pick during implementation based on file size.
- Whether `AnalyticsService.flush` should fire-and-forget or await — recommend fire-and-forget but cap concurrency at 1.

## Estimated effort

- Backend foundation (migration, models, guest_token, `/guest/init`): ~3h
- Backend events router + merge service + verify-otp wiring: ~2h
- Frontend bootstrap (device_id, guest init, interceptor): ~1h
- Frontend gating (welcome removal, gates on actions): ~2h
- Frontend analytics (service + call sites): ~1.5h
- Frontend cart sync at login: ~1h
- Manual QA pass: ~1h

**Total: ~11h**, mergeable in ~6 independent chunks.
