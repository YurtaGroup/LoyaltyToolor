import 'package:flutter/material.dart';

/// Home-screen marketing banner fetched from GET /api/v1/banners.
///
/// All visual fields (colors, image) are optional — when missing, the UI
/// falls back to the app theme so a half-configured banner still renders
/// without exceptions.
class AppBanner {
  final String id;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final Color backgroundColor;
  final Color textColor;
  final String? linkType;
  final String? linkValue;
  final int sortOrder;

  const AppBanner({
    required this.id,
    required this.title,
    this.subtitle,
    this.imageUrl,
    required this.backgroundColor,
    required this.textColor,
    this.linkType,
    this.linkValue,
    required this.sortOrder,
  });

  factory AppBanner.fromJson(
    Map<String, dynamic> json, {
    required Color fallbackBackground,
    required Color fallbackText,
  }) {
    return AppBanner(
      id: json['id']?.toString() ?? '',
      title: (json['title'] as String? ?? '').trim(),
      subtitle: (json['subtitle'] as String?)?.trim(),
      imageUrl: json['image_url'] as String?,
      backgroundColor:
          _parseHex(json['background_color'] as String?) ?? fallbackBackground,
      textColor: _parseHex(json['text_color'] as String?) ?? fallbackText,
      linkType: json['link_type'] as String?,
      linkValue: json['link_value'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  static Color? _parseHex(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    var hex = raw.trim().replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    if (hex.length != 8) return null;
    final parsed = int.tryParse(hex, radix: 16);
    return parsed == null ? null : Color(parsed);
  }
}
