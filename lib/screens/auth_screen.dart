import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _phoneCtrl = TextEditingController();

  // OTP page state
  bool _otpSent = false;
  String _phone = '';
  final List<TextEditingController> _otpCtrls =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());

  // Resend timer
  Timer? _resendTimer;
  int _resendSeconds = 0;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    for (final c in _otpCtrls) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendSeconds = 60;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _resendSeconds--;
        if (_resendSeconds <= 0) {
          timer.cancel();
        }
      });
    });
  }

  String _formatPhone(String raw) {
    // Normalize phone: ensure it starts with +
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    if (!trimmed.startsWith('+')) return '+$trimmed';
    return trimmed;
  }

  Future<void> _sendOtp() async {
    final phone = _formatPhone(_phoneCtrl.text);
    if (phone.length < 6) {
      _showError('Введите номер телефона');
      return;
    }

    final auth = context.read<AuthProvider>();
    final otpCode = await auth.sendOtp(phone);

    if (!mounted) return;

    if (auth.error != null) {
      _showError(auth.error!);
      auth.clearError();
      return;
    }

    setState(() {
      _phone = phone;
      _otpSent = true;
    });

    _startResendTimer();

    // Auto-fill OTP from backend response (dev mode)
    if (otpCode != null && otpCode.length == 4) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      for (int i = 0; i < 4; i++) {
        _otpCtrls[i].text = otpCode[i];
      }
      // Auto-submit after fill
      _verifyOtp();
    }
  }

  Future<void> _resendOtp() async {
    if (_resendSeconds > 0) return;

    // Clear old OTP fields
    for (final c in _otpCtrls) {
      c.clear();
    }

    final auth = context.read<AuthProvider>();
    final otpCode = await auth.sendOtp(_phone);

    if (!mounted) return;

    if (auth.error != null) {
      _showError(auth.error!);
      auth.clearError();
      return;
    }

    _startResendTimer();

    // Auto-fill again
    if (otpCode != null && otpCode.length == 4) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      for (int i = 0; i < 4; i++) {
        _otpCtrls[i].text = otpCode[i];
      }
      _verifyOtp();
    }
  }

  Future<void> _verifyOtp() async {
    final code = _otpCtrls.map((c) => c.text).join();
    if (code.length != 4) {
      _showError('Введите 4-значный код');
      return;
    }

    final auth = context.read<AuthProvider>();
    await auth.verifyOtp(_phone, code);

    if (!mounted) return;

    if (auth.error != null) {
      _showError(auth.error!);
      auth.clearError();
      // Clear OTP fields on wrong code
      for (final c in _otpCtrls) {
        c.clear();
      }
      _otpFocusNodes[0].requestFocus();
    } else if (auth.isLoggedIn) {
      Navigator.of(context).pop();
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.3),
            radius: 1.2,
            colors: [
              isDark ? const Color(0xFF0F1620) : const Color(0xFFEAF1F8),
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: _otpSent ? _buildOtpPage(auth) : _buildPhonePage(auth),
            ),
          ),
        ),
      ),
    );
  }

  // ── Phone input page ──────────────────────────────────────────────────

  Widget _buildPhonePage(AuthProvider auth) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/images/toolor_logo.png', width: 180),
        const SizedBox(height: 6),
        Text(
          'LOYALTY  &  STORE',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w400,
            letterSpacing: 6,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 48),

        Text(
          'Войти по номеру телефона',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Мы отправим SMS с кодом подтверждения',
          style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Phone field
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Телефон',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
              decoration: InputDecoration(
                hintText: '+996 ...',
                hintStyle: TextStyle(color: AppColors.textTertiary),
                prefixIcon: Icon(Icons.phone_outlined, size: 20, color: AppColors.textTertiary),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Continue button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: auth.isLoading
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    _sendOtp();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0033A0),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 1),
            ),
            child: auth.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('ПРОДОЛЖИТЬ'),
          ),
        ),

        const SizedBox(height: 16),

        // Skip
        TextButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
          child: Text(
            'Пропустить',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
          ),
        ),
      ],
    );
  }

  // ── OTP verification page ─────────────────────────────────────────────

  Widget _buildOtpPage(AuthProvider auth) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/images/toolor_logo.png', width: 120),
        const SizedBox(height: 40),

        Text(
          'Код подтверждения',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Отправлен на $_phone',
          style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
        ),
        const SizedBox(height: 36),

        // OTP input fields
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) => _buildOtpField(i)),
        ),
        const SizedBox(height: 32),

        // Verify button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: auth.isLoading
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    _verifyOtp();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0033A0),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 1),
            ),
            child: auth.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('ПОДТВЕРДИТЬ'),
          ),
        ),
        const SizedBox(height: 24),

        // Resend / timer
        _resendSeconds > 0
            ? Text(
                'Отправить повторно через ${_resendSeconds}с',
                style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
              )
            : TextButton(
                onPressed: auth.isLoading ? null : _resendOtp,
                child: Text(
                  'Отправить код повторно',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0033A0),
                  ),
                ),
              ),

        const SizedBox(height: 16),

        // Back to phone input
        TextButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            setState(() {
              _otpSent = false;
              for (final c in _otpCtrls) {
                c.clear();
              }
              _resendTimer?.cancel();
              _resendSeconds = 0;
            });
          },
          child: Text(
            'Изменить номер',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpField(int index) {
    return Container(
      width: 56,
      height: 64,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: TextField(
        controller: _otpCtrls[index],
        focusNode: _otpFocusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF0033A0), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 3) {
            _otpFocusNodes[index + 1].requestFocus();
          }
          // Auto-submit when all 4 digits entered
          if (index == 3 && value.isNotEmpty) {
            final code = _otpCtrls.map((c) => c.text).join();
            if (code.length == 4) {
              _verifyOtp();
            }
          }
          // Handle backspace — go to previous field
          if (value.isEmpty && index > 0) {
            _otpFocusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }
}
