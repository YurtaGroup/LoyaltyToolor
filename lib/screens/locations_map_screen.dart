import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/locations_sheet.dart';

/// Map screen showing pickup locations (store / mobile / showroom) as pins.
/// Tapping a pin opens a bottom sheet with details and a "Построить маршрут" button.
class LocationsMapScreen extends StatefulWidget {
  const LocationsMapScreen({super.key});

  @override
  State<LocationsMapScreen> createState() => _LocationsMapScreenState();
}

class _LocationsMapScreenState extends State<LocationsMapScreen> {
  static const LatLng _bishkekCenter = LatLng(42.8746, 74.5698);

  List<ToolorLocation> _locations = [];
  bool _isLoading = true;
  bool _loadError = false;

  @override
  void initState() {
    super.initState();
    _fetchLocations();
  }

  Future<void> _fetchLocations() async {
    try {
      final response = await ApiService.dio.get('/api/v1/locations');
      final data = response.data;
      final List<dynamic> items =
          data is List ? data : (data['items'] as List? ?? data as List);
      if (!mounted) return;
      setState(() {
        _locations = items
            .map((json) => ToolorLocation.fromJson(json as Map<String, dynamic>))
            .where((loc) =>
                loc.isActive &&
                loc.latitude != null &&
                loc.longitude != null &&
                (loc.type == LocationType.store ||
                    loc.type == LocationType.mobile ||
                    loc.type == LocationType.showroom))
            .toList();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = true;
      });
    }
  }

  Future<void> _openRoute(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Silently ignore — no maps app available.
    }
  }

  void _showLocationSheet(BuildContext context, ToolorLocation loc) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _LocationDetailSheet(
        location: loc,
        onRoute: () {
          if (loc.latitude != null && loc.longitude != null) {
            _openRoute(loc.latitude!, loc.longitude!);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Точки самовывоза',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.textTertiary.withValues(alpha: 0.4)),
                      const SizedBox(height: S.x12),
                      Text('Не удалось загрузить точки', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    ],
                  ),
                )
              : FlutterMap(
                  options: const MapOptions(
                    initialCenter: _bishkekCenter,
                    initialZoom: 12,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'kg.toolor.loyalty',
                    ),
                    MarkerLayer(
                      markers: _locations
                          .map(
                            (loc) => Marker(
                              point: LatLng(loc.latitude!, loc.longitude!),
                              width: 44,
                              height: 44,
                              child: GestureDetector(
                                onTap: () => _showLocationSheet(context, loc),
                                child: Icon(
                                  Icons.location_on,
                                  size: 44,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
    );
  }
}

class _LocationDetailSheet extends StatelessWidget {
  final ToolorLocation location;
  final VoidCallback onRoute;

  const _LocationDetailSheet({
    required this.location,
    required this.onRoute,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = location.photoUrl != null && location.photoUrl!.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(R.xl)),
      ),
      padding: const EdgeInsets.fromLTRB(S.x16, S.x12, S.x16, S.x24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 32,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.surfaceBright,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: S.x16),
            if (hasPhoto) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(R.md),
                child: CachedNetworkImage(
                  imageUrl: location.photoUrl!,
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(
                    height: 160,
                    color: AppColors.surfaceElevated,
                  ),
                  errorWidget: (_, _, _) => Container(
                    height: 160,
                    color: AppColors.surfaceElevated,
                    child: Icon(Icons.broken_image_outlined, color: AppColors.textTertiary),
                  ),
                ),
              ),
              const SizedBox(height: S.x16),
            ],
            Text(
              location.name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: S.x8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.place_outlined, size: 16, color: AppColors.textTertiary),
                const SizedBox(width: S.x6),
                Expanded(
                  child: Text(
                    location.address,
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            if (location.phone != null && location.phone!.isNotEmpty) ...[
              const SizedBox(height: S.x6),
              Row(
                children: [
                  Icon(Icons.phone_outlined, size: 16, color: AppColors.textTertiary),
                  const SizedBox(width: S.x6),
                  Expanded(
                    child: Text(
                      location.phone!,
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ],
            if (location.hours != null && location.hours!.isNotEmpty) ...[
              const SizedBox(height: S.x6),
              Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 16, color: AppColors.textTertiary),
                  const SizedBox(width: S.x6),
                  Expanded(
                    child: Text(
                      location.hours!,
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: S.x20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onRoute,
                icon: const Icon(Icons.directions_rounded, size: 18),
                label: const Text('Построить маршрут'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: S.x12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(R.md),
                  ),
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
