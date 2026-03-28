-- ============================================================
-- TOOLOR — Seed: Store Locations
-- ============================================================
-- Matches the hardcoded data from lib/widgets/locations_sheet.dart
-- ============================================================

BEGIN;

INSERT INTO locations (name, address, type, hours, note, sort_order) VALUES
  ('TOOLOR AsiaMall',      'AsiaMall, 2 этаж, бутик 19(1)',      'store',      '10:00–22:00',    NULL,                              1),
  ('TOOLOR Dordoi Plaza',  'Dordoi Plaza, 1 этаж',               'store_soon', NULL,             'Открытие скоро',                  2),
  ('TOOLOR Bishkek Park',  'ТРЦ Bishkek Park, 2 этаж',           'store_soon', NULL,             'Открытие скоро',                  3),
  ('Вендинг AsiaMall',     'AsiaMall, 1 этаж, у эскалатора',     'vending',    NULL,             'Аксессуары, шарфы, кепки',        4),
  ('Вендинг Beta Stores',  'Beta Stores, центральный вход',      'vending',    NULL,             'Аксессуары, сумки',               5),
  ('Вендинг Mega Silk Way','Mega Silk Way, 1 этаж',              'vending',    NULL,             'Аксессуары, чехлы',               6),
  ('TOOLOR Bus',           'Мобильный шоурум',                   'bus',        'По расписанию',  'Маршрут: Бишкек → Иссык-Куль',   7);

COMMIT;
