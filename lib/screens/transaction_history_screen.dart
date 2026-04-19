import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/loyalty.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd.MM.yyyy');
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('История баллов'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final transactions = auth.loyalty?.transactions ?? const <LoyaltyTransaction>[];
          if (transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 56, color: AppColors.textTertiary),
                  const SizedBox(height: 12),
                  Text(
                    'Пока пусто',
                    style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => auth.fetchLoyalty(),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: transactions.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                thickness: 0.5,
                color: AppColors.divider,
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (_, i) {
                final tx = transactions[i];
                final (IconData ic, Color c) = switch (tx.type) {
                  TransactionType.purchase => (Icons.shopping_bag_rounded, AppColors.accent),
                  TransactionType.pointsRedeemed => (Icons.redeem_rounded, AppColors.sale),
                  TransactionType.bonus => (Icons.card_giftcard_rounded, AppColors.gold),
                  TransactionType.referral => (Icons.people_rounded, Colors.blueAccent),
                };
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: c.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(ic, size: 18, color: c),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.description,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              fmt.format(tx.date),
                              style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${tx.pointsEarned > 0 ? '+' : ''}${tx.pointsEarned}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: tx.pointsEarned >= 0 ? AppColors.accent : AppColors.sale,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
