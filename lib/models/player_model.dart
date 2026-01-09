import '../utils/constants.dart';

/// Represents the player's progress and resources
class PlayerModel {
  int money;
  int xp;
  int totalMoneyEarned;
  int buildingsPlaced;
  DateTime lastSessionTime;

  // Bank credit system
  bool hasTakenCredit;
  int creditAmount;
  DateTime? lastCreditPaymentDate;

  PlayerModel({
    this.money = GameConstants.startingMoney,
    this.xp = 0,
    this.totalMoneyEarned = 0,
    this.buildingsPlaced = 0,
    DateTime? lastSessionTime,
    this.hasTakenCredit = false,
    this.creditAmount = 0,
    this.lastCreditPaymentDate,
  }) : lastSessionTime = lastSessionTime ?? DateTime.now();

  /// Calculate player level from XP
  int get level {
    return (xp / GameConstants.xpPerLevel).floor() + 1;
  }

  /// Get XP progress towards next level (0.0 to 1.0)
  double get levelProgress {
    final xpInCurrentLevel = xp % GameConstants.xpPerLevel;
    return xpInCurrentLevel / GameConstants.xpPerLevel;
  }

  /// Get XP needed for next level
  int get xpToNextLevel {
    return GameConstants.xpPerLevel - (xp % GameConstants.xpPerLevel);
  }

  /// Add money to player
  void addMoney(int amount) {
    money += amount;
    if (amount > 0) {
      totalMoneyEarned += amount;
    }
  }

  /// Try to spend money, returns true if successful
  bool trySpend(int amount) {
    if (money >= amount) {
      money -= amount;
      return true;
    }
    return false;
  }

  /// Check if player can afford an amount
  bool canAfford(int amount) {
    return money >= amount;
  }

  /// Add XP to player
  void addXp(int amount) {
    xp += amount;
  }

  /// Update last session time
  void updateSessionTime() {
    lastSessionTime = DateTime.now();
  }

  /// Calculate offline earnings
  int calculateOfflineEarnings(int revenuePerMinute) {
    final minutesOffline =
        DateTime.now().difference(lastSessionTime).inMinutes;
    // Cap offline earnings to 24 hours
    final cappedMinutes = minutesOffline.clamp(0, 24 * 60);
    return cappedMinutes * revenuePerMinute;
  }

  /// Check if player can take a bank credit
  bool get canTakeCredit => !hasTakenCredit;

  /// Check if player is in debt (negative balance)
  bool get isInDebt => money < 0;

  /// Get remaining credit debt
  int get remainingDebt => creditAmount;

  /// Take a bank credit (only once)
  bool takeCredit(int amount) {
    if (hasTakenCredit) return false;
    if (amount < GameConstants.minCredit || amount > GameConstants.maxCredit) {
      return false;
    }

    hasTakenCredit = true;
    creditAmount = amount;
    money += amount;
    lastCreditPaymentDate = DateTime.now();
    return true;
  }

  /// Process daily credit payment (-500€/day)
  /// Returns the amount deducted
  int processDailyCreditPayment() {
    if (!hasTakenCredit || creditAmount <= 0) return 0;

    final now = DateTime.now();
    if (lastCreditPaymentDate == null) {
      lastCreditPaymentDate = now;
      return 0;
    }

    // Calculate days since last payment
    final daysSinceLastPayment = now.difference(lastCreditPaymentDate!).inDays;
    if (daysSinceLastPayment < 1) return 0;

    // Process payments for each day
    int totalDeducted = 0;
    for (int i = 0; i < daysSinceLastPayment; i++) {
      final payment = GameConstants.dailyCreditPayment.clamp(0, creditAmount);
      money -= payment;
      creditAmount -= payment;
      totalDeducted += payment;

      // Credit fully repaid
      if (creditAmount <= 0) {
        creditAmount = 0;
        break;
      }
    }

    lastCreditPaymentDate = now;
    return totalDeducted;
  }

  /// Create a copy with updated fields
  PlayerModel copyWith({
    int? money,
    int? xp,
    int? totalMoneyEarned,
    int? buildingsPlaced,
    DateTime? lastSessionTime,
    bool? hasTakenCredit,
    int? creditAmount,
    DateTime? lastCreditPaymentDate,
  }) {
    return PlayerModel(
      money: money ?? this.money,
      xp: xp ?? this.xp,
      totalMoneyEarned: totalMoneyEarned ?? this.totalMoneyEarned,
      buildingsPlaced: buildingsPlaced ?? this.buildingsPlaced,
      lastSessionTime: lastSessionTime ?? this.lastSessionTime,
      hasTakenCredit: hasTakenCredit ?? this.hasTakenCredit,
      creditAmount: creditAmount ?? this.creditAmount,
      lastCreditPaymentDate: lastCreditPaymentDate ?? this.lastCreditPaymentDate,
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'money': money,
      'xp': xp,
      'totalMoneyEarned': totalMoneyEarned,
      'buildingsPlaced': buildingsPlaced,
      'lastSessionTime': lastSessionTime.toIso8601String(),
      'hasTakenCredit': hasTakenCredit,
      'creditAmount': creditAmount,
      'lastCreditPaymentDate': lastCreditPaymentDate?.toIso8601String(),
    };
  }

  /// Create from JSON
  factory PlayerModel.fromJson(Map<String, dynamic> json) {
    return PlayerModel(
      money: json['money'] as int? ?? GameConstants.startingMoney,
      xp: json['xp'] as int? ?? 0,
      totalMoneyEarned: json['totalMoneyEarned'] as int? ?? 0,
      buildingsPlaced: json['buildingsPlaced'] as int? ?? 0,
      lastSessionTime: json['lastSessionTime'] != null
          ? DateTime.parse(json['lastSessionTime'] as String)
          : DateTime.now(),
      hasTakenCredit: json['hasTakenCredit'] as bool? ?? false,
      creditAmount: json['creditAmount'] as int? ?? 0,
      lastCreditPaymentDate: json['lastCreditPaymentDate'] != null
          ? DateTime.parse(json['lastCreditPaymentDate'] as String)
          : null,
    );
  }

  @override
  String toString() {
    return 'PlayerModel(money: $money, level: $level, xp: $xp)';
  }
}
