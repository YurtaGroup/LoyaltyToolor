import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/loyalty.dart';

class AuthProvider extends ChangeNotifier {
  AppUser? _user;
  LoyaltyAccount? _loyalty;
  bool _isLoggedIn = false;

  AppUser? get user => _user;
  LoyaltyAccount? get loyalty => _loyalty;
  bool get isLoggedIn => _isLoggedIn;

  // Demo login for MVP
  void demoLogin() {
    _user = AppUser(
      id: 'usr_001',
      name: 'Алия Садыкова',
      phone: '+996 555 123 456',
      email: 'aliya@example.com',
      birthDate: DateTime(1995, 6, 15),
    );

    _loyalty = LoyaltyAccount(
      id: 'loy_001',
      qrCode: 'TOOLOR-USR001-2026',
      tier: LoyaltyTier.silver,
      points: 2450,
      totalSpent: 78500,
      transactions: [
        LoyaltyTransaction(
          id: 'txn_001',
          date: DateTime(2026, 3, 20),
          amount: 8990,
          pointsEarned: 450,
          description: 'Куртка женская TOOLOR Wind',
          type: TransactionType.purchase,
        ),
        LoyaltyTransaction(
          id: 'txn_002',
          date: DateTime(2026, 3, 15),
          amount: 5490,
          pointsEarned: 275,
          description: 'Худи мужская TOOLOR Urban',
          type: TransactionType.purchase,
        ),
        LoyaltyTransaction(
          id: 'txn_003',
          date: DateTime(2026, 3, 10),
          amount: 3990,
          pointsEarned: 200,
          description: 'Футболка женская TOOLOR Basic',
          type: TransactionType.purchase,
        ),
        LoyaltyTransaction(
          id: 'txn_004',
          date: DateTime(2026, 3, 5),
          amount: 0,
          pointsEarned: 500,
          description: 'Бонус за регистрацию',
          type: TransactionType.bonus,
        ),
        LoyaltyTransaction(
          id: 'txn_005',
          date: DateTime(2026, 2, 28),
          amount: 12990,
          pointsEarned: 650,
          description: 'Пуховик TOOLOR Nomad',
          type: TransactionType.purchase,
        ),
        LoyaltyTransaction(
          id: 'txn_006',
          date: DateTime(2026, 2, 20),
          amount: -1500,
          pointsEarned: -300,
          description: 'Списание баллов',
          type: TransactionType.pointsRedeemed,
        ),
        LoyaltyTransaction(
          id: 'txn_007',
          date: DateTime(2026, 2, 14),
          amount: 0,
          pointsEarned: 200,
          description: 'Реферальный бонус',
          type: TransactionType.referral,
        ),
      ],
    );

    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _user = null;
    _loyalty = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}
