import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

/// Full-screen "My Card" — shows the customer's loyalty QR code,
/// tier badge, and points balance. Designed for the cashier-scan flow:
/// customer opens this tab and shows the QR to the cashier.
class MyCardScreen extends StatefulWidget {
  const MyCardScreen({super.key});

  @override
  State<MyCardScreen> createState() => _MyCardScreenState();
}

class _MyCardScreenState extends State<MyCardScreen> {
  String? _qrCode;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchQr();
  }

  Future<void> _fetchQr() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resp = await ApiService.dio.get('/api/v1/loyalty/me/qr');
      final data = resp.data as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _qrCode = data['qr_code'] as String?;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось загрузить QR';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final loyalty = auth.loyalty;
    final user = auth.user;
    final isLoggedIn = auth.isLoggedIn;

    if (!isLoggedIn) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.qr_code_2_rounded, size: 64, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text(
                'Войдите чтобы получить карту',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final String tierStr = (loyalty?.tier ?? 'kulun').toString();
    final tierName = _tierLabel(tierStr);
    final tierColor = _tierColor(tierStr);
    final points = loyalty?.points ?? 0;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await auth.fetchLoyalty();
            await _fetchQr();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  // ── Name + tier ────────────────────────────
                  Text(
                    user?.name ?? 'Клиент',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: tierColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tierName,
                      style: TextStyle(
                        color: tierColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── QR Card ────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Покажите кассиру',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_loading)
                          const SizedBox(
                            height: 200,
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (_error != null)
                          SizedBox(
                            height: 200,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.error_outline,
                                      color: AppColors.textSecondary),
                                  const SizedBox(height: 8),
                                  Text(_error!,
                                      style: TextStyle(
                                          color: AppColors.textSecondary)),
                                  const SizedBox(height: 12),
                                  TextButton(
                                    onPressed: _fetchQr,
                                    child: const Text('Повторить'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (_qrCode != null)
                          QrImageView(
                            data: _qrCode!,
                            version: QrVersions.auto,
                            size: 220,
                            eyeStyle: QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: AppColors.textPrimary,
                            ),
                            dataModuleStyle: QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: AppColors.textPrimary,
                            ),
                            backgroundColor: Colors.transparent,
                          ),
                        const SizedBox(height: 16),
                        if (_qrCode != null)
                          Text(
                            _qrCode!.length > 30
                                ? '${_qrCode!.substring(0, 30)}...'
                                : _qrCode!,
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                              fontFamily: 'monospace',
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Points card ────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [tierColor, tierColor.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Доступно баллов',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$points',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '= $points сом',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Hint ───────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 20, color: AppColors.textSecondary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Баллами можно оплатить часть покупки. '
                            'Покажите QR код кассиру перед оплатой.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _tierLabel(String tier) {
    switch (tier) {
      case 'tai':
        return 'Тай';
      case 'kunan':
        return 'Кунан';
      case 'at':
        return 'Ат';
      default:
        return 'Кулун';
    }
  }

  Color _tierColor(String tier) {
    switch (tier) {
      case 'tai':
        return const Color(0xFF6C63FF);
      case 'kunan':
        return const Color(0xFFFF9800);
      case 'at':
        return const Color(0xFFE91E63);
      default:
        return const Color(0xFF4CAF50);
    }
  }
}
