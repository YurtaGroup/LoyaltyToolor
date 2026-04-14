import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';

/// Subcategory inside a category bucket (e.g. "Рубашки" under "Женщинам").
class CategorySubcategory {
  final String id;
  final String name;
  final int count;

  const CategorySubcategory({
    required this.id,
    required this.name,
    required this.count,
  });

  factory CategorySubcategory.fromJson(Map<String, dynamic> json) {
    return CategorySubcategory(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Top-level category bucket returned by GET /api/v1/products/categories.
class CategoryBucket {
  final String id;          // "women" / "men" / "unisex" / "accessories" / "all"
  final String name;        // "Женщинам" / "Мужчинам" / "ВСЕ" / ...
  final String? audience;   // "women" / "men" / "unisex" / "kids" / null
  final int count;
  final List<CategorySubcategory> subcategories;

  const CategoryBucket({
    required this.id,
    required this.name,
    required this.audience,
    required this.count,
    required this.subcategories,
  });

  factory CategoryBucket.fromJson(Map<String, dynamic> json) {
    final subs = (json['subcategories'] as List?) ?? const [];
    return CategoryBucket(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      audience: json['audience'] as String?,
      count: (json['count'] as num?)?.toInt() ?? 0,
      subcategories: subs
          .map((s) => CategorySubcategory.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Synthetic "ВСЕ" bucket used as the first tab — passes no filter.
  factory CategoryBucket.all(int totalCount) => CategoryBucket(
        id: 'all',
        name: 'ВСЕ',
        audience: null,
        count: totalCount,
        subcategories: const [],
      );
}

/// Catalog following ZARA/SSENSE pattern:
/// - Full-width search → category pills → product grid
/// - Product count shown for context
/// - Clean 2-col grid with generous image space
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  String _query = '';

  List<CategoryBucket> _buckets = [CategoryBucket.all(0)];
  CategoryBucket? _selectedBucket;         // null = ВСЕ (no filter)
  CategorySubcategory? _selectedSub;       // null = "Все" within a bucket

  List<Product> _products = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _loadError = false;
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _fetchCategories();
    _fetchProducts(reset: true);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await ApiService.dio.get('/api/v1/products/categories');
      if (!mounted) return;
      final raw = (response.data as List).cast<Map<String, dynamic>>();
      final parsed = raw.map(CategoryBucket.fromJson).toList();
      final total = parsed.fold<int>(0, (sum, b) => sum + b.count);
      setState(() {
        _buckets = [CategoryBucket.all(total), ...parsed];
      });
    } catch (_) {
      // Categories fetch failed — keep the single "ВСЕ" tab as fallback.
    }
  }

  Future<void> _fetchProducts({bool reset = false}) async {
    if (reset) {
      setState(() {
        _currentPage = 1;
        _isLoading = true;
      });
    }

    try {
      final Map<String, dynamic> params = {
        'per_page': 20,
        'page': _currentPage,
      };

      if (_query.isNotEmpty) {
        params['search'] = _query;
      }

      // Apply audience filter when a concrete bucket (not "ВСЕ") is selected.
      final bucket = _selectedBucket;
      if (bucket != null && bucket.id != 'all') {
        params['audience'] = bucket.audience ?? bucket.id;
      }

      // Apply subcategory filter when a concrete chip (not "Все") is selected.
      final sub = _selectedSub;
      if (sub != null) {
        params['category'] = sub.id;
      }

      final response = await ApiService.dio.get(
        '/api/v1/products',
        queryParameters: params,
      );

      final data = response.data;
      final items = (data['items'] as List)
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .where((p) => p.price > 0)
          .toList();

      if (!mounted) return;
      setState(() {
        if (reset) {
          _products = items;
        } else {
          _products.addAll(items);
        }
        _totalPages = data['pages'] as int? ?? 1;
        _isLoading = false;
        _isLoadingMore = false;
        _loadError = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _loadError = _products.isEmpty;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || _currentPage >= _totalPages) return;
    _isLoadingMore = true;
    _currentPage++;
    await _fetchProducts();
  }

  void _onBucketTap(CategoryBucket bucket) {
    if (_selectedBucket?.id == bucket.id) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedBucket = bucket.id == 'all' ? null : bucket;
      _selectedSub = null;
    });
    _fetchProducts(reset: true);
  }

  void _onSubTap(CategorySubcategory? sub) {
    if (_selectedSub?.id == sub?.id) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedSub = sub);
    _fetchProducts(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final activeBucket = _selectedBucket;
    final showChips = activeBucket != null && activeBucket.subcategories.isNotEmpty;

    return SafeArea(
      child: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(S.x16, S.x8, S.x16, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) {
                setState(() => _query = v);
                _fetchProducts(reset: true);
              },
              style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Поиск',
                prefixIcon: Icon(Icons.search_rounded, color: AppColors.textTertiary, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? GestureDetector(
                        onTap: () { _searchCtrl.clear(); setState(() => _query = ''); _fetchProducts(reset: true); },
                        child: Icon(Icons.close_rounded, color: AppColors.textTertiary, size: 18),
                      )
                    : null,
              ),
            ),
          ),

          // Category tabs — horizontal scrollable row, dynamic from API
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(S.x12, S.x8, S.x12, 0),
              itemCount: _buckets.length,
              itemBuilder: (_, i) {
                final bucket = _buckets[i];
                final isSelected = bucket.id == 'all'
                    ? _selectedBucket == null
                    : _selectedBucket?.id == bucket.id;
                return GestureDetector(
                  onTap: () => _onBucketTap(bucket),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: S.x12, vertical: S.x8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected ? AppColors.textPrimary : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: Text(
                      bucket.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 1,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? AppColors.textPrimary : AppColors.textTertiary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Subcategory chips — only when a bucket (not ВСЕ) is selected
          if (showChips)
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(S.x16, S.x4, S.x16, S.x4),
                itemCount: activeBucket.subcategories.length + 1,
                itemBuilder: (_, i) {
                  final isAll = i == 0;
                  final sub = isAll ? null : activeBucket.subcategories[i - 1];
                  final label = isAll ? 'Все' : sub!.name;
                  final selected = isAll ? _selectedSub == null : _selectedSub?.id == sub!.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: S.x6),
                    child: GestureDetector(
                      onTap: () => _onSubTap(sub),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: S.x12, vertical: S.x6),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.textPrimary : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(R.pill),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            color: selected ? AppColors.textInverse : AppColors.textSecondary,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          else
            const SizedBox(height: S.x4),

          // Product count
          Padding(
            padding: const EdgeInsets.fromLTRB(S.x16, S.x8, S.x16, S.x4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('${_products.length} товаров', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
            ),
          ),

          // Grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _loadError
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.textTertiary.withValues(alpha: 0.4)),
                            const SizedBox(height: S.x12),
                            Text('Не удалось загрузить товары', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                            const SizedBox(height: S.x16),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() { _isLoading = true; _loadError = false; });
                                _fetchProducts(reset: true);
                              },
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Повторить'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.md)),
                              ),
                            ),
                          ],
                        ),
                      )
                    : _products.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search_off_rounded, size: 40, color: AppColors.textTertiary.withValues(alpha: 0.4)),
                                const SizedBox(height: S.x12),
                                Text('Ничего не найдено', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                              ],
                            ),
                          )
                        : GridView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(S.x16, S.x8, S.x16, S.x24),
                        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.56,
                          crossAxisSpacing: S.x12,
                          mainAxisSpacing: S.x20,
                        ),
                        itemCount: _products.length + (_isLoadingMore ? 2 : 0),
                        itemBuilder: (_, i) {
                          if (i >= _products.length) {
                            return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2)));
                          }
                          final p = _products[i];
                          return ProductCard(
                            product: p,
                            heroTag: 'cat_${p.id}',
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p, heroTag: 'cat_${p.id}'))),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
