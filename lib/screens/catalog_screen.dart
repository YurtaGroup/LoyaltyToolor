import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';

/// Flat category item returned by GET /api/v1/products/categories.
class CategoryItem {
  final String id;
  final String name;
  final int count;

  CategoryItem({required this.id, required this.name, required this.count});

  factory CategoryItem.fromJson(Map<String, dynamic> json) => CategoryItem(
        id: json['id'] as String,
        name: json['name'] as String,
        count: (json['count'] ?? 0) as int,
      );

  static CategoryItem all() => CategoryItem(id: 'all', name: 'ВСЕ', count: 0);
}

/// Catalog following ZARA/SSENSE pattern:
/// - Full-width search → category tabs → product grid
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

  List<CategoryItem> _categories = [CategoryItem.all()];
  CategoryItem _selectedCategory = CategoryItem.all();

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
      final raw = response.data as List;
      setState(() {
        _categories = [
          CategoryItem.all(),
          ...raw.map((c) => CategoryItem.fromJson(c as Map<String, dynamic>)),
        ];
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
      final params = <String, dynamic>{
        'page': _currentPage,
        'size': 20,
        if (_query.isNotEmpty) 'search': _query,
        if (_selectedCategory.id != 'all') 'category': _selectedCategory.id,
      };

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

  void _onCategoryTap(CategoryItem category) {
    if (_selectedCategory.id == category.id) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedCategory = category;
      _currentPage = 1;
      _products = [];
    });
    _fetchProducts(reset: true);
  }

  @override
  Widget build(BuildContext context) {
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
                        onTap: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                          _fetchProducts(reset: true);
                        },
                        child: Icon(Icons.close_rounded, color: AppColors.textTertiary, size: 18),
                      )
                    : null,
              ),
            ),
          ),

          // Category tabs — horizontal scrollable row, flat list from API
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(S.x12, S.x8, S.x12, 0),
              itemCount: _categories.length,
              itemBuilder: (_, i) {
                final category = _categories[i];
                final isSelected = _selectedCategory.id == category.id;
                return GestureDetector(
                  onTap: () => _onCategoryTap(category),
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
                      category.name.toUpperCase(),
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

          const SizedBox(height: S.x4),

          // Product count
          Padding(
            padding: const EdgeInsets.fromLTRB(S.x16, S.x8, S.x16, S.x4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_products.length} товаров',
                style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
              ),
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
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p, heroTag: 'cat_${p.id}')),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
