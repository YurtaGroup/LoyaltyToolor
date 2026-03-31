enum LoyaltyTier { kulun, tai, kunan, at }

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
    this.transactions = const [],
  });

  /// Create a LoyaltyAccount from the FastAPI backend JSON response.
  /// Transactions are fetched separately, so they default to empty.
  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  factory LoyaltyAccount.fromJson(Map<String, dynamic> json) {
    return LoyaltyAccount(
      id: json['id'] as String? ?? '',
      qrCode: json['qr_code'] as String? ?? '',
      tier: _parseTier(json['tier'] as String? ?? 'kulun'),
      points: (json['points'] as num?)?.toInt() ?? 0,
      totalSpent: _toDouble(json['total_spent']),
    );
  }

  static LoyaltyTier _parseTier(String value) {
    switch (value.toLowerCase()) {
      case 'tai':
        return LoyaltyTier.tai;
      case 'kunan':
        return LoyaltyTier.kunan;
      case 'at':
        return LoyaltyTier.at;
      case 'kulun':
      default:
        return LoyaltyTier.kulun;
    }
  }

  String get tierName {
    switch (tier) {
      case LoyaltyTier.kulun:
        return 'Кулун';
      case LoyaltyTier.tai:
        return 'Тай';
      case LoyaltyTier.kunan:
        return 'Кунан';
      case LoyaltyTier.at:
        return 'Ат';
    }
  }

  String get tierSubtitle {
    switch (tier) {
      case LoyaltyTier.kulun:
        return 'Жеребёнок';
      case LoyaltyTier.tai:
        return 'Стригунок';
      case LoyaltyTier.kunan:
        return 'Молодой конь';
      case LoyaltyTier.at:
        return 'Скакун';
    }
  }

  int get cashbackPercent {
    switch (tier) {
      case LoyaltyTier.kulun:
        return 3;
      case LoyaltyTier.tai:
        return 5;
      case LoyaltyTier.kunan:
        return 8;
      case LoyaltyTier.at:
        return 12;
    }
  }

  double get nextTierThreshold {
    switch (tier) {
      case LoyaltyTier.kulun:
        return 50000;
      case LoyaltyTier.tai:
        return 150000;
      case LoyaltyTier.kunan:
        return 300000;
      case LoyaltyTier.at:
        return double.infinity;
    }
  }

  double get progressToNextTier {
    if (tier == LoyaltyTier.at) return 1.0;
    double prevThreshold = 0;
    switch (tier) {
      case LoyaltyTier.tai:
        prevThreshold = 50000;
        break;
      case LoyaltyTier.kunan:
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

  /// Create a LoyaltyTransaction from the FastAPI backend JSON response.
  factory LoyaltyTransaction.fromJson(Map<String, dynamic> json) {
    return LoyaltyTransaction(
      id: json['id'] as String? ?? '',
      date: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      amount: LoyaltyAccount._toDouble(json['amount']),
      pointsEarned: (json['points_change'] is String
          ? int.tryParse(json['points_change']) ?? 0
          : (json['points_change'] as num?)?.toInt() ?? 0),
      description: json['description'] as String? ?? '',
      type: _parseTransactionType(json['type'] as String? ?? 'purchase'),
    );
  }

  static TransactionType _parseTransactionType(String value) {
    switch (value.toLowerCase()) {
      case 'points_redeemed':
        return TransactionType.pointsRedeemed;
      case 'bonus':
        return TransactionType.bonus;
      case 'referral':
        return TransactionType.referral;
      case 'purchase':
      default:
        return TransactionType.purchase;
    }
  }
}

enum TransactionType { purchase, pointsRedeemed, bonus, referral }
