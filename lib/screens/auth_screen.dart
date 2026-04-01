import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'onboarding_screen.dart';

const _brandBlue = Color(0xFF0033A0);
const _brandBlueLight = Color(0xFF1A5EC7);

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  // ── Controllers ──
  final _phoneCtrl = TextEditingController();
  final _phoneMask = MaskTextInputFormatter(
    mask: '+996 ### ### ###',
    filter: {'#': RegExp(r'[0-9]')},
    initialText: '+996 ',
  );
  final List<TextEditingController> _otpCtrls =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());

  // ── State ──
  bool _otpSent = false;
  String _phone = '';
  Timer? _resendTimer;
  int _resendSeconds = 0;
  bool _success = false;

  // ── Animations ──
  late final AnimationController _entranceCtrl;
  late final AnimationController _pageCtrl;
  late final AnimationController _successCtrl;
  late final AnimationController _pulseCtrl;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<Offset> _formSlide;
  late final Animation<double> _formOpacity;
  late final Animation<double> _successScale;
  late final Animation<double> _checkOpacity;

  @override
  void initState() {
    super.initState();
    _phoneCtrl.text = '+996 ';
    _phoneCtrl.selection = TextSelection.fromPosition(
      TextPosition(offset: _phoneCtrl.text.length),
    );

    // Entrance animation
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScale = Tween(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack)),
    );
    _logoOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.0, 0.35, curve: Curves.easeOut)),
    );
    _formSlide = Tween(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic)),
    );
    _formOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.3, 0.7, curve: Curves.easeOut)),
    );
    _entranceCtrl.forward();

    // Page transition (phone → OTP)
    _pageCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    // Success animation
    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successScale = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut),
    );
    _checkOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successCtrl, curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
    );

    // Subtle pulse on logo
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

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
    _entranceCtrl.dispose();
    _pageCtrl.dispose();
    _successCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Resend timer ──
  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendSeconds = 60;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _resendSeconds--;
        if (_resendSeconds <= 0) timer.cancel();
      });
    });
  }

  String _formatPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return '';
    return '+$digits';
  }

  // ── Send OTP ──
  Future<void> _sendOtp() async {
    final phone = _formatPhone(_phoneCtrl.text);
    if (phone.length != 13 || !phone.startsWith('+996')) {
      _showError('Введите полный номер телефона');
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
    _pageCtrl.forward();
    _startResendTimer();

    // Auto-fill OTP (dev mode)
    if (otpCode != null && otpCode.length == 4) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      for (int i = 0; i < 4; i++) {
        await Future.delayed(Duration(milliseconds: 80 * i));
        if (!mounted) return;
        _otpCtrls[i].text = otpCode[i];
      }
      _verifyOtp();
    }
  }

  // ── Resend OTP ──
  Future<void> _resendOtp() async {
    if (_resendSeconds > 0) return;
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

    if (otpCode != null && otpCode.length == 4) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      for (int i = 0; i < 4; i++) {
        await Future.delayed(Duration(milliseconds: 80 * i));
        if (!mounted) return;
        _otpCtrls[i].text = otpCode[i];
      }
      _verifyOtp();
    }
  }

  // ── Verify OTP ──
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
      for (final c in _otpCtrls) {
        c.clear();
      }
      _otpFocusNodes[0].requestFocus();
      HapticFeedback.heavyImpact();
    } else if (auth.isLoggedIn) {
      HapticFeedback.mediumImpact();
      setState(() => _success = true);
      _successCtrl.forward();

      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;

      final needsOnboarding = auth.user != null &&
          (auth.user!.name.isEmpty || auth.user!.birthDate == null);
      if (needsOnboarding) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Build ──
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background gradient
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.5),
                radius: 1.4,
                colors: [
                  isDark ? const Color(0xFF0A1628) : const Color(0xFFE2ECF8),
                  isDark ? const Color(0xFF060C16) : const Color(0xFFF0F0EE),
                  AppColors.background,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: const SizedBox.expand(),
          ),

          // Decorative circles
          Positioned(
            top: -80,
            right: -60,
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, _) => Opacity(
                opacity: 0.04 + _pulseCtrl.value * 0.02,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _brandBlue,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: Opacity(
              opacity: 0.03,
              child: Container(
                width: 300,
                height: 300,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _brandBlue,
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: AnimatedBuilder(
                  animation: _entranceCtrl,
                  builder: (_, child) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      FadeTransition(
                        opacity: _logoOpacity,
                        child: ScaleTransition(
                          scale: _logoScale,
                          child: Image.asset('assets/images/toolor_logo.png', width: _otpSent ? 100 : 160),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        height: _otpSent ? 4 : 6,
                      ),
                      FadeTransition(
                        opacity: _logoOpacity,
                        child: AnimatedOpacity(
                          opacity: _otpSent ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 300),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: _otpSent ? 0 : 16,
                            child: Text(
                              'LOYALTY  &  STORE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 6,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ),
                        ),
                      ),

                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        height: _otpSent ? 28 : 44,
                      ),

                      // Form content
                      SlideTransition(
                        position: _formSlide,
                        child: FadeTransition(
                          opacity: _formOpacity,
                          child: _success
                              ? _buildSuccessView()
                              : AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 400),
                                  switchInCurve: Curves.easeOutCubic,
                                  switchOutCurve: Curves.easeInCubic,
                                  transitionBuilder: (child, anim) {
                                    final slide = Tween(
                                      begin: const Offset(0.08, 0),
                                      end: Offset.zero,
                                    ).animate(anim);
                                    return SlideTransition(
                                      position: slide,
                                      child: FadeTransition(opacity: anim, child: child),
                                    );
                                  },
                                  child: _otpSent
                                      ? _buildOtpPage(auth)
                                      : _buildPhonePage(auth),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Back button
          if (_otpSent && !_success)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              child: FadeTransition(
                opacity: _formOpacity,
                child: IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _pageCtrl.reverse();
                    setState(() {
                      _otpSent = false;
                      for (final c in _otpCtrls) {
                        c.clear();
                      }
                      _resendTimer?.cancel();
                      _resendSeconds = 0;
                    });
                  },
                  icon: Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textSecondary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Phone Page ──
  Widget _buildPhonePage(AuthProvider auth) {
    return Column(
      key: const ValueKey('phone'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Войти по номеру',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Мы отправим SMS с кодом подтверждения',
          style: TextStyle(fontSize: 14, color: AppColors.textTertiary, height: 1.4),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 36),

        // Phone field
        _buildFieldLabel('Номер телефона'),
        const SizedBox(height: 8),
        _buildPhoneField(),
        const SizedBox(height: 32),

        // Continue button
        _buildPrimaryButton(
          label: 'ПРОДОЛЖИТЬ',
          loading: auth.isLoading,
          onPressed: _sendOtp,
        ),
        const SizedBox(height: 20),

        // Skip
        TextButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text(
            'Пропустить',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  // ── OTP Page ──
  Widget _buildOtpPage(AuthProvider auth) {
    return Column(
      key: const ValueKey('otp'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Код подтверждения',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(fontSize: 14, color: AppColors.textTertiary, height: 1.4),
            children: [
              const TextSpan(text: 'Отправлен на '),
              TextSpan(
                text: _phone,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),

        // OTP fields
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            return TweenAnimationBuilder<double>(
              key: ValueKey('otp_field_$i'),
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 300 + i * 80),
              curve: Curves.easeOutBack,
              builder: (_, val, child) => Transform.scale(
                scale: val,
                child: Opacity(opacity: val.clamp(0, 1), child: child),
              ),
              child: _buildOtpField(i),
            );
          }),
        ),
        const SizedBox(height: 32),

        // Verify button
        _buildPrimaryButton(
          label: 'ПОДТВЕРДИТЬ',
          loading: auth.isLoading,
          onPressed: _verifyOtp,
        ),
        const SizedBox(height: 24),

        // Resend / timer
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _resendSeconds > 0
              ? Row(
                  key: ValueKey('timer_$_resendSeconds'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        value: _resendSeconds / 60,
                        strokeWidth: 2,
                        color: AppColors.textTertiary.withValues(alpha: 0.5),
                        backgroundColor: AppColors.textTertiary.withValues(alpha: 0.1),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Повторно через $_resendSeconds с',
                      style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
                    ),
                  ],
                )
              : TextButton(
                  key: const ValueKey('resend'),
                  onPressed: auth.isLoading ? null : _resendOtp,
                  child: Text(
                    'Отправить код повторно',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _brandBlue,
                    ),
                  ),
                ),
        ),

        const SizedBox(height: 8),

        // Change number
        TextButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            _pageCtrl.reverse();
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

  // ── Success View ──
  Widget _buildSuccessView() {
    return AnimatedBuilder(
      animation: _successCtrl,
      builder: (_, _) => Column(
        children: [
          ScaleTransition(
            scale: _successScale,
            child: FadeTransition(
              opacity: _checkOpacity,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                ),
                child: const Icon(Icons.check_rounded, size: 44, color: Color(0xFF2E7D32)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FadeTransition(
            opacity: _checkOpacity,
            child: Text(
              'Добро пожаловать!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared Widgets ──

  Widget _buildFieldLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _brandBlue.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _phoneCtrl,
        keyboardType: TextInputType.phone,
        inputFormatters: [_phoneMask],
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
        decoration: InputDecoration(
          hintText: '+996 700 123 456',
          hintStyle: TextStyle(color: AppColors.textTertiary, fontWeight: FontWeight.w400),
          prefixIcon: Container(
            width: 48,
            alignment: Alignment.center,
            child: Text('🇰🇬', style: const TextStyle(fontSize: 22)),
          ),
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _brandBlue, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildOtpField(int index) {
    final hasValue = _otpCtrls[index].text.isNotEmpty;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 58,
      height: 68,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: hasValue
            ? [BoxShadow(color: _brandBlue.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 3))]
            : null,
      ),
      child: TextField(
        controller: _otpCtrls[index],
        focusNode: _otpFocusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: hasValue ? _brandBlue.withValues(alpha: 0.3) : AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _brandBlue, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
        onChanged: (value) {
          setState(() {}); // rebuild for shadow/border
          if (value.isNotEmpty && index < 3) {
            _otpFocusNodes[index + 1].requestFocus();
          }
          if (index == 3 && value.isNotEmpty) {
            final code = _otpCtrls.map((c) => c.text).join();
            if (code.length == 4) _verifyOtp();
          }
          if (value.isEmpty && index > 0) {
            _otpFocusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required bool loading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [_brandBlue, _brandBlueLight],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: _brandBlue.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: loading ? null : () {
            HapticFeedback.mediumImpact();
            onPressed();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 1.2),
          ),
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : Text(label),
        ),
      ),
    );
  }
}
