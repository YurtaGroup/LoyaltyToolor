import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../services/api_service.dart';

/// Favorites provider backed by the cool-group API.
///
/// The server is the source of truth when the user is authenticated. A
/// local SharedPreferences cache keeps the list visible offline and
/// between app launches before the first sync completes. Mutations are
/// optimistic: we update local state + cache first, hit the server
/// second, and roll back only if the server returns a terminal error.
class FavoritesProvider extends ChangeNotifier {
  static const _idsKey = 'favorite_ids';
  static const _productsKey = 'favorite_products';

  final Set<String> _favoriteIds = {};
  final List<Product> _favorites = [];
  bool _syncing = false;

  FavoritesProvider() {
    _loadCache();
  }

  List<Product> get favorites => List.unmodifiable(_favorites);

  bool get isSyncing => _syncing;

  bool isFavorite(String productId) => _favoriteIds.contains(productId);

  // ── Public API ────────────────────────────────────────────────────────

  /// Load favorites from the server. Call this once the user is logged in
  /// (e.g. from AuthProvider after a successful auth restore / login).
  /// Safe to call repeatedly — only the first successful load flips the
  /// "synced" flag.
  Future<void> syncFromServer() async {
    if (_syncing) return;
    _syncing = true;
    notifyListeners();
    try {
      final response = await ApiService.dio.get('/api/v1/favorites');
      final raw = response.data;
      if (raw is! List) {
        return;
      }
      final fresh = <Product>[];
      final freshIds = <String>{};
      for (final item in raw) {
        if (item is Map<String, dynamic>) {
          try {
            final product = Product.fromJson(item);
            if (product.id.isEmpty) continue;
            fresh.add(product);
            freshIds.add(product.id);
          } catch (_) {
            // Skip items that don't match the expected shape.
          }
        }
      }
      _favorites
        ..clear()
        ..addAll(fresh);
      _favoriteIds
        ..clear()
        ..addAll(freshIds);
      notifyListeners();
      unawaited(_saveCache());
    } catch (e) {
      debugPrint('[FavoritesProvider] syncFromServer failed: $e');
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  /// Clear local state on logout — the next user's favorites will be
  /// fetched fresh via [syncFromServer].
  Future<void> clearOnLogout() async {
    _favoriteIds.clear();
    _favorites.clear();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_idsKey);
      await prefs.remove(_productsKey);
    } catch (_) {}
  }

  Future<void> toggleFavorite(Product product) async {
    final wasFavorite = _favoriteIds.contains(product.id);
    // Optimistic local update so the heart icon flips immediately.
    if (wasFavorite) {
      _favoriteIds.remove(product.id);
      _favorites.removeWhere((p) => p.id == product.id);
    } else {
      _favoriteIds.add(product.id);
      _favorites.add(product);
    }
    notifyListeners();
    unawaited(_saveCache());

    // Fire-and-forget the server write. If it fails we roll back — the
    // UI will briefly show the new state then flip back, which is less
    // confusing than silently losing the change on a flaky connection.
    try {
      if (wasFavorite) {
        await ApiService.dio.delete('/api/v1/favorites/${product.id}');
      } else {
        await ApiService.dio.post('/api/v1/favorites/${product.id}');
      }
    } catch (e) {
      debugPrint('[FavoritesProvider] toggleFavorite failed: $e');
      if (wasFavorite) {
        _favoriteIds.add(product.id);
        if (!_favorites.any((p) => p.id == product.id)) {
          _favorites.add(product);
        }
      } else {
        _favoriteIds.remove(product.id);
        _favorites.removeWhere((p) => p.id == product.id);
      }
      notifyListeners();
      unawaited(_saveCache());
    }
  }

  // ── Local cache persistence ──────────────────────────────────────────

  Future<void> _saveCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_idsKey, _favoriteIds.toList());
      final productJsonList = _favorites
          .map((p) => jsonEncode({
                'id': p.id,
                'name': p.name,
                'price': p.price,
                'originalPrice': p.originalPrice,
                'imageUrl': p.imageUrl,
                'category': p.category,
                'subcategory': p.subcategory,
                'description': p.description,
                'sizes': p.sizes,
                'colors': p.colors,
                'stock': p.stock,
              }))
          .toList();
      await prefs.setStringList(_productsKey, productJsonList);
    } catch (_) {
      // Persistence is best-effort.
    }
  }

  Future<void> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final productJsonList = prefs.getStringList(_productsKey);
      if (productJsonList != null && productJsonList.isNotEmpty) {
        _favoriteIds.clear();
        _favorites.clear();
        for (final raw in productJsonList) {
          try {
            final map = jsonDecode(raw) as Map<String, dynamic>;
            final product = Product.fromMap(map);
            _favoriteIds.add(product.id);
            _favorites.add(product);
          } catch (_) {}
        }
        notifyListeners();
        return;
      }

      final ids = prefs.getStringList(_idsKey);
      if (ids == null || ids.isEmpty) return;
      _favoriteIds.addAll(ids);
      notifyListeners();
    } catch (_) {
      // Corrupt data — start fresh.
    }
  }
}

/// Local stand-in for package:async `unawaited` so we don't pull an extra
/// dependency just for fire-and-forget semantics.
void unawaited(Future<void> future) {}
