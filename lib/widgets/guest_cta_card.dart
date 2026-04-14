import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/auth_screen.dart';
import '../theme/app_theme.dart';

/// Shown to guest users in place of the personal loyalty card.
///
/// A compact card with a single call to action — tapping "ВОЙТИ" pushes
/// the existing [AuthScreen]. We intentionally don't advertise a specific
/// cashback percentage here because that would require fetching tier
/// config and we want the guest home to render with zero authenticated
/// requests.
class GuestCtaCard extends StatelessWidget {
  const GuestCtaCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: S.x16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(S.x20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.accent.withValues(alpha: 0.12),
              AppColors.accent.withValues(alpha: 0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(R.lg),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TOOLOR LOYALTY',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 2,
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: S.x8),
            Text(
              'Войдите и получайте бонусы за покупки',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
            const SizedBox(height: S.x16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(R.md),
                  ),
                ),
                child: const Text('ВОЙТИ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
