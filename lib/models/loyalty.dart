enum LoyaltyTier { bronze, silver, gold, platinum }

class LoyaltyAccount {
  final String id;
  final String qrCode;
  final LoyaltyTier tier;
  final int points;
  final double totalSpent;
  final List<LoyaltyTransaction> transactions;

  LoyaltyAccount({
    required this.id,
    required this.qrCode,
    required this.tier,
    required this.points,
    required this.totalSpent,
    required this.transactions,
  });

  String get tierName {
    switch (tier) {
      case LoyaltyTier.bronze:
        return 'Bronze';
      case LoyaltyTier.silver:
        return 'Silver';
      case LoyaltyTier.gold:
        return 'Gold';
      case LoyaltyTier.platinum:
        return 'Platinum';
    }
  }

  int get cashbackPercent {
    switch (tier) {
      case LoyaltyTier.bronze:
        return 3;
      case LoyaltyTier.silver:
        return 5;
      case LoyaltyTier.gold:
        return 8;
      case LoyaltyTier.platinum:
        return 12;
    }
  }

  double get nextTierThreshold {
    switch (tier) {
      case LoyaltyTier.bronze:
        return 50000;
      case LoyaltyTier.silver:
        return 150000;
      case LoyaltyTier.gold:
        return 300000;
      case LoyaltyTier.platinum:
        return double.infinity;
    }
  }

  double get progressToNextTier {
    if (tier == LoyaltyTier.platinum) return 1.0;
    double prevThreshold = 0;
    switch (tier) {
      case LoyaltyTier.silver:
        prevThreshold = 50000;
        break;
      case LoyaltyTier.gold:
        prevThreshold = 150000;
        break;
      default:
        prevThreshold = 0;
    }
    return (totalSpent - prevThreshold) / (nextTierThreshold - prevThreshold);
  }
}

class LoyaltyTransaction {
  final String id;
  final DateTime date;
  final double amount;
  final int pointsEarned;
  final String description;
  final TransactionType type;

  LoyaltyTransaction({
    required this.id,
    required this.date,
    required this.amount,
    required this.pointsEarned,
    required this.description,
    required this.type,
  });
}

enum TransactionType { purchase, pointsRedeemed, bonus, referral }
