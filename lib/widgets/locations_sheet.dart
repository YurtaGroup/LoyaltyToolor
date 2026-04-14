import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../screens/locations_map_screen.dart';

enum LocationType { store, storeSoon, vending, bus, mobile, showroom }

class ToolorLocation {
  final String? id;
  final String name;
  final String address;
  final LocationType type;
  final String? hours;
  final String? note;
  final String? phone;
  final double? latitude;
  final double? longitude;
  final String? photoUrl;
  final bool isActive;

  const ToolorLocation({
    this.id,
    required this.name,
    required this.address,
    required this.type,
    this.hours,
    this.note,
    this.phone,
    this.latitude,
    this.longitude,
    this.photoUrl,
    this.isActive = true,
  });

  /// Parse a location from the API JSON response.
  factory ToolorLocation.fromJson(Map<String, dynamic> json) {
    final typeStr = (json['type'] as String? ?? 'store').toLowerCase();
    final LocationType type;
    switch (typeStr) {
      case 'store':
        type = LocationType.store;
        break;
      case 'store_soon':
        type = LocationType.storeSoon;
        break;
      case 'vending':
        type = LocationType.vending;
        break;
      case 'bus':
        type = LocationType.bus;
        break;
      case 'mobile':
        type = LocationType.mobile;
        break;
      case 'showroom':
        type = LocationType.showroom;
        break;
      default:
        type = LocationType.store;
    }
    return ToolorLocation(
      id: json['id']?.toString(),
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      type: type,
      hours: json['hours'] as String?,
      note: json['note'] as String?,
      phone: json['phone'] as String?,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      photoUrl: json['photo_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

/// Hardcoded fallback locations used when the API is unavailable.
const _fallbackLocations = [
  ToolorLocation(
    name: 'TOOLOR AsiaMall',
    address: 'AsiaMall, 2 этаж, бутик 19(1)',
    type: LocationType.store,
    hours: '10:00–22:00',
  ),
  ToolorLocation(
    name: 'TOOLOR Dordoi Plaza',
    address: 'Dordoi Plaza, 1 этаж',
    type: LocationType.storeSoon,
    note: 'Открытие скоро',
  ),
  ToolorLocation(
    name: 'TOOLOR Bishkek Park',
    address: 'ТРЦ Bishkek Park, 2 этаж',
    type: LocationType.storeSoon,
    note: 'Открытие скоро',
  ),
  ToolorLocation(
    name: 'Вендинг AsiaMall',
    address: 'AsiaMall, 1 этаж, у эскалатора',
    type: LocationType.vending,
    note: 'Аксессуары, шарфы, кепки',
  ),
  ToolorLocation(
    name: 'Вендинг Beta Stores',
    address: 'Beta Stores, центральный вход',
    type: LocationType.vending,
    note: 'Аксессуары, сумки',
  ),
  ToolorLocation(
    name: 'Вендинг Mega Silk Way',
    address: 'Mega Silk Way, 1 этаж',
    type: LocationType.vending,
    note: 'Аксессуары, чехлы',
  ),
  ToolorLocation(
    name: 'TOOLOR Bus',
    address: 'Мобильный шоурум',
    type: LocationType.bus,
    note: 'Маршрут: Бишкек → Иссык-Куль',
    hours: 'По расписанию',
  ),
];

void showLocationsSheet(BuildContext context) {
  HapticFeedback.lightImpact();
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _LocationsSheetContent(height: MediaQuery.of(context).size.height * 0.7),
  );
}

class _LocationsSheetContent extends StatefulWidget {
  final double height;
  const _LocationsSheetContent({required this.height});

  @override
  State<_LocationsSheetContent> createState() => _LocationsSheetContentState();
}

class _LocationsSheetContentState extends State<_LocationsSheetContent> {
  List<ToolorLocation> _locations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLocations();
  }

  Future<void> _fetchLocations() async {
    try {
      final response = await ApiService.dio.get('/api/v1/locations');
      final data = response.data;
      final List<dynamic> items = data is List ? data : (data['items'] as List? ?? data as List);
      if (!mounted) return;
      setState(() {
        _locations = items
            .map((json) => ToolorLocation.fromJson(json as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      // Fallback to hardcoded locations on API failure
      setState(() {
        _locations = _fallbackLocations.toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(R.xl)),
      ),
      child: Column(
        children: [
          const SizedBox(height: S.x12),
          Container(width: 32, height: 3, decoration: BoxDecoration(color: AppColors.surfaceBright, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: S.x16),
          Text('ГДЕ ПРИМЕРИТЬ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 2, color: AppColors.textSecondary)),
          const SizedBox(height: S.x4),
          Text('Магазины, вендинг и мобильный шоурум', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
          const SizedBox(height: S.x12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: S.x16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LocationsMapScreen()),
                  );
                },
                icon: const Icon(Icons.map_rounded, size: 18),
                label: const Text('Показать на карте'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: S.x12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.md)),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          const SizedBox(height: S.x12),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(S.x16, 0, S.x16, S.x24),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _locations.length,
                    separatorBuilder: (_, _) => const SizedBox(height: S.x8),
                    itemBuilder: (_, i) => _LocationTile(location: _locations[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LocationTile extends StatelessWidget {
  final ToolorLocation location;
  const _LocationTile({required this.location});

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color, String badge) = switch (location.type) {
      LocationType.store => (Icons.storefront_rounded, AppColors.accent, 'МАГАЗИН'),
      LocationType.storeSoon => (Icons.storefront_outlined, AppColors.gold, 'СКОРО'),
      LocationType.vending => (Icons.sell_outlined, const Color(0xFF9C7CF4), 'ВЕНДИНГ'),
      LocationType.bus => (Icons.directions_bus_rounded, const Color(0xFFFF8A65), 'BUS'),
      LocationType.mobile => (Icons.directions_bus_rounded, const Color(0xFFFF8A65), 'МОБИЛЬНЫЙ'),
      LocationType.showroom => (Icons.storefront_rounded, AppColors.accent, 'ШОУРУМ'),
    };

    final hasPhoto = location.photoUrl != null && location.photoUrl!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(S.x16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(R.md),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          hasPhoto
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(R.sm),
                  child: CachedNetworkImage(
                    imageUrl: location.photoUrl!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(
                      width: 40,
                      height: 40,
                      color: color.withValues(alpha: 0.1),
                    ),
                    errorWidget: (_, _, _) => Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(R.sm)),
                      child: Icon(icon, size: 18, color: color),
                    ),
                  ),
                )
              : Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(R.sm)),
                  child: Icon(icon, size: 18, color: color),
                ),
          const SizedBox(width: S.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(location.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: S.x6, vertical: 2),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
                      child: Text(badge, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.5)),
                    ),
                  ],
                ),
                const SizedBox(height: S.x2),
                Text(location.address, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                if (location.note != null) ...[
                  const SizedBox(height: S.x2),
                  Text(location.note!, style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7))),
                ],
                if (location.hours != null) ...[
                  const SizedBox(height: S.x2),
                  Text(location.hours!, style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
