import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _ctrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  bool _isProcessing = false;
  _ScanResult? _result;
  String? _lastScannedToken;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || _result != null) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    try {
      final resp = await ApiService.dio.post(
        '/api/v1/loyalty/scan',
        data: {'qr_token': code},
      );
      final data = resp.data;
      if (!mounted) return;
      setState(() {
        _lastScannedToken = code;
        _result = _ScanResult(
          valid: data['valid'] == true,
          reason: data['reason'],
          customer: data['valid'] == true && data['customer'] != null
              ? _Customer.fromJson(data['customer'])
              : null,
        );
        _isProcessing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _result = _ScanResult(valid: false, reason: 'network_error');
        _isProcessing = false;
      });
    }
  }

  void _reset() {
    setState(() {
      _result = null;
      _lastScannedToken = null;
      _isProcessing = false;
    });
  }

  /// Extract user_id from QR token (first part before the first dot).
  String? _extractUserId(String? token) {
    if (token == null || !token.contains('.')) return null;
    return token.split('.').first;
  }

  Future<void> _showAwardPointsDialog(_Customer customer) async {
    final amountController = TextEditingController();
    final userId = _extractUserId(_lastScannedToken);
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось определить ID пользователя')),
        );
      }
      return;
    }

    final cashbackPercent = customer.cashbackPercent;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final amountText = amountController.text;
            final amount = double.tryParse(amountText) ?? 0;
            final points = (amount * cashbackPercent / 100).round();

            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: Text('Начислить баллы',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Клиент: ${customer.name}',
                      style: TextStyle(
                          fontSize: 14, color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Сумма покупки (сом)',
                      labelStyle: TextStyle(color: AppColors.textTertiary),
                      suffixText: 'сом',
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  if (amount > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Покупка ${amount.toStringAsFixed(0)} сом \u2192 +$points баллов ($cashbackPercent%)',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.accent,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Отмена',
                      style: TextStyle(color: AppColors.textTertiary)),
                ),
                TextButton(
                  onPressed: amount > 0 && points > 0
                      ? () => Navigator.pop(ctx, {
                            'amount': amount,
                            'points': points,
                          })
                      : null,
                  child: Text('Начислить',
                      style: TextStyle(
                          color: amount > 0 && points > 0
                              ? AppColors.accent
                              : AppColors.textTertiary)),
                ),
              ],
            );
          },
        );
      },
    ).then((result) async {
      if (result == null || result is! Map) return;
      final amount = result['amount'] as double;
      final points = result['points'] as int;

      try {
        await ApiService.dio.post(
          '/api/v1/admin/users/$userId/loyalty/adjust',
          data: {
            'points_change': points,
            'description': 'Покупка в магазине: ${amount.toStringAsFixed(0)} сом',
          },
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Начислено $points баллов для ${customer.name}'),
          ),
        );
        _reset();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка начисления: $e')),
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Сканер QR', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _result != null ? _resultView() : _cameraView(),
    );
  }

  Widget _cameraView() {
    return Stack(
      children: [
        MobileScanner(controller: _ctrl, onDetect: _onDetect),
        // Scan overlay
        Center(
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 2),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        // Instructions
        Positioned(
          bottom: 80,
          left: 0,
          right: 0,
          child: Text(
            _isProcessing ? 'Проверка...' : 'Наведите на QR код клиента',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        if (_isProcessing)
          const Center(child: CircularProgressIndicator(color: Colors.white)),
      ],
    );
  }

  Widget _resultView() {
    final r = _result!;
    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              if (r.valid && r.customer != null) _validCard(r.customer!) else _invalidCard(r.reason),
              if (r.valid && r.customer != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () => _showAwardPointsDialog(r.customer!),
                    icon: const Icon(Icons.star_rounded),
                    label: const Text('Начислить баллы', style: TextStyle(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('Сканировать снова', style: TextStyle(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _validCard(_Customer c) {
    final tierColors = {
      'kulun': Colors.orange,
      'tai': Colors.grey,
      'kunan': Colors.amber,
      'at': Colors.purple,
    };
    final tierNames = {
      'kulun': 'Кулун',
      'tai': 'Тай',
      'kunan': 'Кунан',
      'at': 'Ат',
    };
    final color = tierColors[c.tier] ?? Colors.grey;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: Colors.green.withValues(alpha: 0.1), blurRadius: 20)],
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 56),
          const SizedBox(height: 16),
          Text(c.name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(c.phone, style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              tierNames[c.tier] ?? c.tier,
              style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 14),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _stat('Баллы', '${c.points}'),
              _stat('Потрачено', '${c.totalSpent.toStringAsFixed(0)} сом'),
              _stat('Кешбэк', '${c.cashbackPercent}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
        ],
      ),
    );
  }

  Widget _invalidCard(String? reason) {
    final messages = {
      'expired': 'QR код истёк.\nПопросите клиента обновить.',
      'invalid_signature': 'QR код поддельный.',
      'invalid_format': 'Неверный формат QR кода.',
      'user_not_found': 'Пользователь не найден.',
      'network_error': 'Ошибка сети. Проверьте интернет.',
    };
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.cancel_rounded, color: Colors.red, size: 56),
          const SizedBox(height: 16),
          Text('Недействителен', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(
            messages[reason] ?? 'Неизвестная ошибка',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ScanResult {
  final bool valid;
  final String? reason;
  final _Customer? customer;
  _ScanResult({required this.valid, this.reason, this.customer});
}

class _Customer {
  final String name;
  final String phone;
  final String tier;
  final int points;
  final double totalSpent;
  final int cashbackPercent;

  _Customer({
    required this.name,
    required this.phone,
    required this.tier,
    required this.points,
    required this.totalSpent,
    required this.cashbackPercent,
  });

  factory _Customer.fromJson(Map<String, dynamic> json) {
    return _Customer(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      tier: json['tier'] ?? 'bronze',
      points: json['points'] ?? 0,
      totalSpent: double.tryParse(json['total_spent']?.toString() ?? '0') ?? 0,
      cashbackPercent: json['cashback_percent'] ?? 3,
    );
  }
}
