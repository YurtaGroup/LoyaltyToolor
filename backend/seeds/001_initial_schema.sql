-- ============================================================
-- TOOLOR Loyalty + Store — Initial Database Schema
-- ============================================================
-- Run this in the Supabase SQL Editor after creating the project.
-- Requires: Supabase Auth enabled, pgcrypto extension (default).
-- ============================================================

-- ── Profiles ─────────────────────────────────────────────────
-- Extends auth.users. Created automatically via trigger on signup.
CREATE TABLE profiles (
  id              uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  phone           text UNIQUE,
  full_name       text DEFAULT '',
  email           text,
  avatar_url      text,
  birth_date      date,
  language        text DEFAULT 'ru' CHECK (language IN ('ru', 'ky', 'en')),
  is_admin        boolean DEFAULT false,
  referral_code   text UNIQUE,
  referred_by     uuid REFERENCES profiles(id),
  fcm_token       text,
  created_at      timestamptz DEFAULT now(),
  updated_at      timestamptz DEFAULT now()
);

-- ── Loyalty Accounts ─────────────────────────────────────────
-- One per user, tracks tier / points / spend.
CREATE TABLE loyalty_accounts (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         uuid UNIQUE NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  qr_code         text UNIQUE NOT NULL,
  tier            text DEFAULT 'bronze' CHECK (tier IN ('bronze', 'silver', 'gold', 'platinum')),
  points          integer DEFAULT 0,
  total_spent     numeric(12,2) DEFAULT 0,
  created_at      timestamptz DEFAULT now(),
  updated_at      timestamptz DEFAULT now()
);

-- ── Categories ───────────────────────────────────────────────
CREATE TABLE categories (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name            text NOT NULL,
  slug            text UNIQUE NOT NULL,
  sort_order      integer DEFAULT 0,
  created_at      timestamptz DEFAULT now()
);

-- ── Subcategories ────────────────────────────────────────────
CREATE TABLE subcategories (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id     uuid NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
  name            text NOT NULL,
  slug            text UNIQUE NOT NULL,
  sort_order      integer DEFAULT 0,
  created_at      timestamptz DEFAULT now()
);

-- ── Products ─────────────────────────────────────────────────
-- Dynamic catalog replacing lib/data/toolor_products.dart.
CREATE TABLE products (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sku             text UNIQUE,
  name            text NOT NULL,
  slug            text UNIQUE NOT NULL,
  description     text DEFAULT '',
  price           numeric(10,2) NOT NULL,
  original_price  numeric(10,2),
  category_id     uuid NOT NULL REFERENCES categories(id),
  subcategory_id  uuid NOT NULL REFERENCES subcategories(id),
  image_url       text NOT NULL,
  images          jsonb DEFAULT '[]',
  sizes           jsonb DEFAULT '[]',
  colors          jsonb DEFAULT '[]',
  stock           integer,
  is_active       boolean DEFAULT true,
  is_featured     boolean DEFAULT false,
  sort_order      integer DEFAULT 0,
  metadata        jsonb DEFAULT '{}',
  created_at      timestamptz DEFAULT now(),
  updated_at      timestamptz DEFAULT now()
);

-- ── Orders ───────────────────────────────────────────────────
CREATE SEQUENCE IF NOT EXISTS order_number_seq START 1;

CREATE TABLE orders (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         uuid NOT NULL REFERENCES profiles(id),
  order_number    text UNIQUE NOT NULL DEFAULT '',
  status          text DEFAULT 'pending' CHECK (status IN (
    'pending', 'payment_uploaded', 'payment_confirmed', 'processing',
    'shipped', 'delivered', 'cancelled', 'refunded'
  )),
  subtotal        numeric(10,2) NOT NULL,
  discount_amount numeric(10,2) DEFAULT 0,
  points_used     integer DEFAULT 0,
  points_discount numeric(10,2) DEFAULT 0,
  total           numeric(10,2) NOT NULL,
  currency        text DEFAULT 'KGS',
  payment_method  text CHECK (payment_method IN ('mbank_qr', 'card', 'cash_on_delivery')),
  payment_proof_url text,
  delivery_address text,
  delivery_type   text DEFAULT 'pickup' CHECK (delivery_type IN ('pickup', 'delivery')),
  delivery_notes  text,
  try_at_home     boolean DEFAULT false,
  admin_notes     text,
  confirmed_by    uuid REFERENCES profiles(id),
  confirmed_at    timestamptz,
  shipped_at      timestamptz,
  delivered_at    timestamptz,
  created_at      timestamptz DEFAULT now(),
  updated_at      timestamptz DEFAULT now()
);

-- ── Order Items ──────────────────────────────────────────────
CREATE TABLE order_items (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id        uuid NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id      uuid NOT NULL REFERENCES products(id),
  product_name    text NOT NULL,
  product_price   numeric(10,2) NOT NULL,
  selected_size   text,
  selected_color  text,
  quantity        integer NOT NULL DEFAULT 1,
  line_total      numeric(10,2) NOT NULL
);

-- ── Loyalty Transactions ─────────────────────────────────────
CREATE TABLE loyalty_transactions (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  loyalty_id      uuid NOT NULL REFERENCES loyalty_accounts(id) ON DELETE CASCADE,
  user_id         uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  order_id        uuid REFERENCES orders(id),
  type            text NOT NULL CHECK (type IN ('purchase', 'points_redeemed', 'bonus', 'referral', 'admin_adjustment')),
  amount          numeric(12,2) DEFAULT 0,
  points_change   integer NOT NULL,
  description     text NOT NULL,
  created_at      timestamptz DEFAULT now()
);

-- ── Cart Items ───────────────────────────────────────────────
-- Server-side cart for cross-device sync.
CREATE TABLE cart_items (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  product_id      uuid NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  selected_size   text,
  selected_color  text,
  quantity        integer NOT NULL DEFAULT 1,
  created_at      timestamptz DEFAULT now(),
  updated_at      timestamptz DEFAULT now(),
  UNIQUE (user_id, product_id, selected_size, selected_color)
);

-- ── Favorites ────────────────────────────────────────────────
CREATE TABLE favorites (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  product_id      uuid NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  created_at      timestamptz DEFAULT now(),
  UNIQUE (user_id, product_id)
);

-- ── Chat Sessions ────────────────────────────────────────────
CREATE TABLE chat_sessions (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title           text,
  created_at      timestamptz DEFAULT now(),
  updated_at      timestamptz DEFAULT now()
);

-- ── Chat Messages ────────────────────────────────────────────
CREATE TABLE chat_messages (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id      uuid NOT NULL REFERENCES chat_sessions(id) ON DELETE CASCADE,
  role            text NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
  content         text NOT NULL,
  products        jsonb DEFAULT '[]',
  metadata        jsonb DEFAULT '{}',
  created_at      timestamptz DEFAULT now()
);

-- ── Notifications ────────────────────────────────────────────
CREATE TABLE notifications (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type            text NOT NULL,
  title           text NOT NULL,
  body            text,
  data            jsonb DEFAULT '{}',
  read            boolean DEFAULT false,
  created_at      timestamptz DEFAULT now()
);

-- ── Referrals ────────────────────────────────────────────────
CREATE TABLE referrals (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  referrer_id     uuid NOT NULL REFERENCES profiles(id),
  referred_id     uuid NOT NULL REFERENCES profiles(id),
  bonus_awarded   boolean DEFAULT false,
  referrer_points integer DEFAULT 0,
  referred_points integer DEFAULT 0,
  created_at      timestamptz DEFAULT now(),
  UNIQUE (referred_id)
);

-- ── Promo Codes ──────────────────────────────────────────────
CREATE TABLE promo_codes (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code            text UNIQUE NOT NULL,
  discount_type   text CHECK (discount_type IN ('percent', 'fixed')),
  discount_value  numeric(10,2) NOT NULL,
  min_order       numeric(10,2) DEFAULT 0,
  max_uses        integer,
  uses_count      integer DEFAULT 0,
  valid_from      timestamptz DEFAULT now(),
  valid_until     timestamptz,
  is_active       boolean DEFAULT true,
  created_at      timestamptz DEFAULT now()
);

-- ── Locations ────────────────────────────────────────────────
CREATE TABLE locations (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name            text NOT NULL,
  address         text NOT NULL,
  type            text NOT NULL CHECK (type IN ('store', 'store_soon', 'vending', 'bus')),
  hours           text,
  note            text,
  latitude        numeric(10,7),
  longitude       numeric(10,7),
  is_active       boolean DEFAULT true,
  sort_order      integer DEFAULT 0,
  created_at      timestamptz DEFAULT now()
);


-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX idx_products_category     ON products(category_id) WHERE is_active = true;
CREATE INDEX idx_products_subcategory  ON products(subcategory_id) WHERE is_active = true;
CREATE INDEX idx_products_price        ON products(price) WHERE is_active = true;
CREATE INDEX idx_products_featured     ON products(is_featured) WHERE is_active = true AND is_featured = true;
CREATE INDEX idx_products_sale         ON products(original_price) WHERE is_active = true AND original_price IS NOT NULL;
CREATE INDEX idx_products_search       ON products USING gin(to_tsvector('russian', name || ' ' || coalesce(description, '')));

CREATE INDEX idx_orders_user           ON orders(user_id);
CREATE INDEX idx_orders_status         ON orders(status);
CREATE INDEX idx_orders_created        ON orders(created_at DESC);
CREATE INDEX idx_order_items_order     ON order_items(order_id);

CREATE INDEX idx_loyalty_accounts_user ON loyalty_accounts(user_id);
CREATE INDEX idx_loyalty_txn_user      ON loyalty_transactions(user_id);
CREATE INDEX idx_loyalty_txn_loyalty   ON loyalty_transactions(loyalty_id);
CREATE INDEX idx_loyalty_txn_created   ON loyalty_transactions(created_at DESC);

CREATE INDEX idx_cart_items_user       ON cart_items(user_id);
CREATE INDEX idx_favorites_user        ON favorites(user_id);

CREATE INDEX idx_chat_sessions_user    ON chat_sessions(user_id);
CREATE INDEX idx_chat_messages_session ON chat_messages(session_id);

CREATE INDEX idx_notifications_user    ON notifications(user_id);
CREATE INDEX idx_notifications_unread  ON notifications(user_id) WHERE read = false;

CREATE INDEX idx_referrals_referrer    ON referrals(referrer_id);


-- ============================================================
-- TRIGGERS & FUNCTIONS
-- ============================================================

-- Auto-create profile + loyalty account on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  ref_code text;
BEGIN
  ref_code := 'TOOLOR-' || UPPER(SUBSTRING(NEW.id::text FROM 1 FOR 8));

  INSERT INTO public.profiles (id, phone, full_name, referral_code)
  VALUES (
    NEW.id,
    NEW.phone,
    COALESCE(NEW.raw_user_meta_data ->> 'full_name', ''),
    ref_code
  );

  INSERT INTO public.loyalty_accounts (user_id, qr_code, tier, points, total_spent)
  VALUES (
    NEW.id,
    'TOOLOR-' || UPPER(SUBSTRING(NEW.id::text FROM 1 FOR 12)),
    'bronze',
    0,
    0
  );

  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Auto-recalculate loyalty tier when total_spent changes
CREATE OR REPLACE FUNCTION public.recalculate_tier()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  NEW.tier := CASE
    WHEN NEW.total_spent >= 300000 THEN 'platinum'
    WHEN NEW.total_spent >= 150000 THEN 'gold'
    WHEN NEW.total_spent >= 50000  THEN 'silver'
    ELSE 'bronze'
  END;
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_loyalty_update
  BEFORE UPDATE ON loyalty_accounts
  FOR EACH ROW EXECUTE FUNCTION public.recalculate_tier();

-- Generate sequential order number (TOOLOR-YYYY-00001)
CREATE OR REPLACE FUNCTION public.generate_order_number()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.order_number := 'TOOLOR-' || TO_CHAR(NOW(), 'YYYY') || '-' || LPAD(NEXTVAL('order_number_seq')::text, 5, '0');
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_order_create
  BEFORE INSERT ON orders
  FOR EACH ROW EXECUTE FUNCTION public.generate_order_number();

-- Auto-update updated_at on profiles
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER orders_updated_at
  BEFORE UPDATE ON orders
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER cart_items_updated_at
  BEFORE UPDATE ON cart_items
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER chat_sessions_updated_at
  BEFORE UPDATE ON chat_sessions
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

-- ── Profiles ─────────────────────────────────────────────────
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Profiles viewable by everyone"
  ON profiles FOR SELECT USING (true);

CREATE POLICY "Users update own profile"
  ON profiles FOR UPDATE USING (auth.uid() = id);

-- ── Loyalty Accounts ─────────────────────────────────────────
ALTER TABLE loyalty_accounts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own loyalty"
  ON loyalty_accounts FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Admins view all loyalty"
  ON loyalty_accounts FOR SELECT
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true));

-- ── Loyalty Transactions ─────────────────────────────────────
ALTER TABLE loyalty_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own transactions"
  ON loyalty_transactions FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Admins view all transactions"
  ON loyalty_transactions FOR SELECT
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true));

-- ── Categories ───────────────────────────────────────────────
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Categories viewable by everyone"
  ON categories FOR SELECT USING (true);

CREATE POLICY "Admins manage categories"
  ON categories FOR ALL
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true));

-- ── Subcategories ────────────────────────────────────────────
ALTER TABLE subcategories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Subcategories viewable by everyone"
  ON subcategories FOR SELECT USING (true);

CREATE POLICY "Admins manage subcategories"
  ON subcategories FOR ALL
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true));

-- ── Products ─────────────────────────────────────────────────
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Active products viewable by everyone"
  ON products FOR SELECT USING (is_active = true);

CREATE POLICY "Admins see all products"
  ON products FOR SELECT
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true));

CREATE POLICY "Admins manage products"
  ON products FOR ALL
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true));

-- ── Orders ───────────────────────────────────────────────────
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own orders"
  ON orders FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users create own orders"
  ON orders FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins view all orders"
  ON orders FOR SELECT
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true));

CREATE POLICY "Admins update orders"
  ON orders FOR UPDATE
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true));

-- ── Order Items ──────────────────────────────────────────────
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own order items"
  ON order_items FOR SELECT
  USING (EXISTS (SELECT 1 FROM orders WHERE orders.id = order_items.order_id AND orders.user_id = auth.uid()));

CREATE POLICY "Users insert own order items"
  ON order_items FOR INSERT
  WITH CHECK (EXISTS (SELECT 1 FROM orders WHERE orders.id = order_items.order_id AND orders.user_id = auth.uid()));

CREATE POLICY "Admins view all order items"
  ON order_items FOR SELECT
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true));

-- ── Cart Items ───────────────────────────────────────────────
ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own cart"
  ON cart_items FOR ALL USING (auth.uid() = user_id);

-- ── Favorites ────────────────────────────────────────────────
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own favorites"
  ON favorites FOR ALL USING (auth.uid() = user_id);

-- ── Chat Sessions ────────────────────────────────────────────
ALTER TABLE chat_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own chat sessions"
  ON chat_sessions FOR ALL USING (auth.uid() = user_id);

-- ── Chat Messages ────────────────────────────────────────────
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own chat messages"
  ON chat_messages FOR SELECT
  USING (EXISTS (SELECT 1 FROM chat_sessions WHERE chat_sessions.id = chat_messages.session_id AND chat_sessions.user_id = auth.uid()));

CREATE POLICY "Users insert own chat messages"
  ON chat_messages FOR INSERT
  WITH CHECK (EXISTS (SELECT 1 FROM chat_sessions WHERE chat_sessions.id = chat_messages.session_id AND chat_sessions.user_id = auth.uid()));

-- ── Notifications ────────────────────────────────────────────
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own notifications"
  ON notifications FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users update own notifications"
  ON notifications FOR UPDATE USING (auth.uid() = user_id);

-- ── Referrals ────────────────────────────────────────────────
ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own referrals"
  ON referrals FOR SELECT
  USING (auth.uid() = referrer_id OR auth.uid() = referred_id);

-- ── Promo Codes ──────────────────────────────────────────────
ALTER TABLE promo_codes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Active promos viewable by authenticated"
  ON promo_codes FOR SELECT
  USING (is_active = true AND auth.uid() IS NOT NULL);

CREATE POLICY "Admins manage promos"
  ON promo_codes FOR ALL
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true));

-- ── Locations ────────────────────────────────────────────────
ALTER TABLE locations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Locations viewable by everyone"
  ON locations FOR SELECT USING (is_active = true);

CREATE POLICY "Admins manage locations"
  ON locations FOR ALL
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true));


-- ============================================================
-- STORAGE BUCKETS (run in Supabase Dashboard or via API)
-- ============================================================
-- These need to be created via the Supabase Dashboard:
--
-- 1. payment-proofs  (private) — payment screenshots
-- 2. product-images  (public)  — product photos
-- 3. avatars         (public)  — user profile photos
-- ============================================================
