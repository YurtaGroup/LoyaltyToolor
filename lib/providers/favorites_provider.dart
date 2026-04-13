import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';

class FavoritesProvider extends ChangeNotifier {
  static const _idsKey = 'favorite_ids';
  static const _productsKey = 'favorite_products';
  final Set<String> _favoriteIds = {};
  final List<Product> _favorites = [];

  FavoritesProvider() {
    _load();
  }

  List<Product> get favorites => List.unmodifiable(_favorites);

  bool isFavorite(String productId) => _favoriteIds.contains(productId);

  void toggleFavorite(Product product) {
    if (_favoriteIds.contains(product.id)) {
      _favoriteIds.remove(product.id);
      _favorites.removeWhere((p) => p.id == product.id);
    } else {
      _favoriteIds.add(product.id);
      _favorites.add(product);
    }
    notifyListeners();
    _save();
  }

  // ── Local persistence ─────────────────────────────────────────────────

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_idsKey, _favoriteIds.toList());
      // Persist full product objects so we don't depend on toolor products list
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
      // Silently fail — persistence is best-effort
    }
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Try loading full product objects first
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
          } catch (_) {
            // Skip corrupt entries
          }
        }
        notifyListeners();
        return;
      }

      // Fallback: load just IDs (backwards compat with old data)
      final ids = prefs.getStringList(_idsKey);
      if (ids == null || ids.isEmpty) return;
      _favoriteIds.addAll(ids);
      notifyListeners();
    } catch (_) {
      // Corrupt data — start fresh
    }
  }
}
