import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

/// Shown once after first OTP login when the user profile is incomplete.
/// Collects first name, last name, and date of birth, then patches /users/me.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  DateTime? _birthDate;
  bool _isSaving = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1920),
      lastDate: now,
      locale: const Locale('ru'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xFF0033A0),
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _save() async {
    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();

    if (firstName.isEmpty) {
      _showError('Введите имя');
      return;
    }
    if (lastName.isEmpty) {
      _showError('Введите фамилию');
      return;
    }
    if (_birthDate == null) {
      _showError('Укажите дату рождения');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final fullName = '$firstName $lastName';
      final birthStr = _birthDate!.toIso8601String().split('T').first;

      // 1. Save name
      await ApiService.dio.patch('/api/v1/users/me', data: {
        'full_name': fullName,
      });

      // 2. Set birthday via dedicated endpoint → awards 1000 bonus points
      await ApiService.dio.patch('/api/v1/users/me/birthday', data: {
        'birth_date': birthStr,
      });

      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      await auth.fetchProfile();
      await auth.fetchLoyalty();

      if (!mounted) return;
      Navigator.of(context).pop(); // back to home
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showError('Ошибка сохранения: $e');
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/toolor_logo.png', width: 120),
                  const SizedBox(height: 32),

                  Text(
                    'Заполните профиль',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Чтобы начать копить баллы лояльности',
                    style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),

                  // First name
                  _buildLabel('Имя'),
                  const SizedBox(height: 6),
                  _buildTextField(
                    controller: _firstNameCtrl,
                    hint: 'Иван',
                    icon: Icons.person_outline,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 20),

                  // Last name
                  _buildLabel('Фамилия'),
                  const SizedBox(height: 6),
                  _buildTextField(
                    controller: _lastNameCtrl,
                    hint: 'Иванов',
                    icon: Icons.person_outline,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 20),

                  // Date of birth
                  _buildLabel('Дата рождения'),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _pickBirthDate,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.cake_outlined, size: 20, color: AppColors.textTertiary),
                          const SizedBox(width: 12),
                          Text(
                            _birthDate != null
                                ? DateFormat('dd.MM.yyyy').format(_birthDate!)
                                : 'дд.мм.гггг',
                            style: TextStyle(
                              fontSize: 16,
                              color: _birthDate != null
                                  ? AppColors.textPrimary
                                  : AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving
                          ? null
                          : () {
                              HapticFeedback.mediumImpact();
                              _save();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0033A0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 1),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('НАЧАТЬ'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: controller,
      textCapitalization: textCapitalization,
      style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textTertiary),
        prefixIcon: Icon(icon, size: 20, color: AppColors.textTertiary),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
