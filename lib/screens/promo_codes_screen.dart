import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';

/// "Мои промокоды" screen.
///
/// Reads GET /api/v1/promo-codes, which returns the publicly-available
/// active promo codes for the current customer. Tapping a code copies it
/// to the clipboard — the code gets validated for real on the checkout
/// screen, so this surface stays read-only.
class PromoCodesScreen extends StatefulWidget {
  const PromoCodesScreen({super.key});

  @override
  State<PromoCodesScreen> createState() => _PromoCodesScreenState();
}

class _PromoCodesScreenState extends State<PromoCodesScreen> {
  List<_PromoCode> _codes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Only fetch when the user is already logged in. For guests the
    // build method renders a CTA and _load is postponed until after
    // a successful login (didChangeDependencies picks up the switch).
    ApiService.isLoggedIn().then((loggedIn) {
      if (loggedIn && mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiService.dio.get('/api/v1/promo-codes');
      final raw = response.data;
      if (raw is! List) {
        throw const FormatException('Expected a list of promo codes');
      }
      final codes = raw
          .whereType<Map<String, dynamic>>()
          .map(_PromoCode.fromJson)
          .toList();
      if (!mounted) return;
      setState(() {
        _codes = codes;
        _loading = false;
      });
    } catch (e) {
      debugPrint('[PromoCodesScreen] load failed: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Не удалось загрузить промокоды';
      });
    }
  }

  Future<void> _copy(_PromoCode code) async {
    await Clipboard.setData(ClipboardData(text: code.code));
    HapticFeedback.selectionClick();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Код ${code.code} скопирован'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ПРОМОКОДЫ'),
        titleTextStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
          color: AppColors.textPrimary,
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
      ),
      body: auth.isLoggedIn
          ? RefreshIndicator(
              onRefresh: _load,
              child: _buildBody(),
            )
          : _guestCta(context),
    );
  }

  Widget _guestCta(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(S.x24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_offer_outlined, size: 40, color: AppColors.textTertiary),
            const SizedBox(height: S.x16),
            Text(
              'Войдите, чтобы видеть промокоды',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: S.x24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                ),
                child: const Text('ВОЙТИ'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Center(
            child: Column(
              children: [
                Icon(Icons.cloud_off_outlined, size: 40, color: AppColors.textTertiary),
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 12),
                TextButton(onPressed: _load, child: const Text('Повторить')),
              ],
            ),
          ),
        ],
      );
    }
    if (_codes.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 140),
          Center(
            child: Column(
              children: [
                Icon(Icons.local_offer_outlined, size: 40, color: AppColors.textTertiary),
                const SizedBox(height: 12),
                Text(
                  'Нет доступных промокодов',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'Загляните позже — мы регулярно добавляем новые',
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.all(S.x16),
      itemCount: _codes.length,
      separatorBuilder: (_, _) => const SizedBox(height: S.x12),
      itemBuilder: (_, i) => _PromoCodeCard(
        code: _codes[i],
        onCopy: () => _copy(_codes[i]),
      ),
    );
  }
}

class _PromoCodeCard extends StatelessWidget {
  final _PromoCode code;
  final VoidCallback onCopy;

  const _PromoCodeCard({required this.code, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCopy,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(S.x16),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(R.md),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: S.x12, vertical: S.x8),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(R.sm),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
              ),
              child: Text(
                code.code,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.gold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: S.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    code.discountLabel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (code.description != null && code.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      code.description!,
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (code.validUntilLabel != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Действует до ${code.validUntilLabel}',
                      style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                    ),
                  ],
                  if (code.minOrderLabel != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Мин. заказ: ${code.minOrderLabel}',
                      style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.copy_rounded, size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _PromoCode {
  final String id;
  final String code;
  final String? description;
  final String discountType;
  final double discountValue;
  final double? minOrderAmount;
  final DateTime? validUntil;

  const _PromoCode({
    required this.id,
    required this.code,
    this.description,
    required this.discountType,
    required this.discountValue,
    this.minOrderAmount,
    this.validUntil,
  });

  factory _PromoCode.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    DateTime? toDate(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    return _PromoCode(
      id: json['id']?.toString() ?? '',
      code: (json['code'] as String? ?? '').toUpperCase(),
      description: json['description'] as String?,
      discountType: json['discount_type'] as String? ?? 'percent',
      discountValue: toDouble(json['discount_value']) ?? 0,
      minOrderAmount: toDouble(json['min_order_amount']),
      validUntil: toDate(json['valid_until']),
    );
  }

  String get discountLabel {
    if (discountType == 'percent') {
      return 'Скидка ${discountValue.toStringAsFixed(0)}%';
    }
    if (discountType == 'fixed') {
      return 'Скидка ${_formatMoney(discountValue)} сом';
    }
    if (discountType == 'free_shipping') {
      return 'Бесплатная доставка';
    }
    return 'Скидка';
  }

  String? get minOrderLabel =>
      minOrderAmount == null ? null : '${_formatMoney(minOrderAmount!)} сом';

  String? get validUntilLabel =>
      validUntil == null ? null : DateFormat('dd.MM.yyyy').format(validUntil!);

  static String _formatMoney(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('\u{00A0}');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
