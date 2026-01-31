import '../utils/constants.dart';

/// Types of monthly objectives
enum ObjectiveType {
  buildCount,        // Build X buildings
  reachPopulation,   // Reach X inhabitants
  earnRevenue,       // Earn X total revenue
  buildCategory,     // Build X buildings of a category
  reachHappiness,    // Reach X% happiness
  upgradeBuilding,   // Upgrade X buildings
}

/// A single monthly objective
class MonthlyObjective {
  final String id;
  final String title;
  final String description;
  final ObjectiveType type;
  final int targetValue;
  final int rewardMoney;
  final int rewardXp;
  final BuildingCategory? targetCategory; // For buildCategory type
  int currentValue;
  bool isCompleted;
  bool isRewardClaimed;

  MonthlyObjective({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.targetValue,
    required this.rewardMoney,
    required this.rewardXp,
    this.targetCategory,
    this.currentValue = 0,
    this.isCompleted = false,
    this.isRewardClaimed = false,
  });

  double get progress => (currentValue / targetValue).clamp(0.0, 1.0);

  void updateProgress(int value) {
    currentValue = value;
    if (currentValue >= targetValue && !isCompleted) {
      isCompleted = true;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.index,
      'targetValue': targetValue,
      'rewardMoney': rewardMoney,
      'rewardXp': rewardXp,
      'targetCategory': targetCategory?.index,
      'currentValue': currentValue,
      'isCompleted': isCompleted,
      'isRewardClaimed': isRewardClaimed,
    };
  }

  factory MonthlyObjective.fromJson(Map<String, dynamic> json) {
    return MonthlyObjective(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: ObjectiveType.values[json['type'] as int],
      targetValue: json['targetValue'] as int,
      rewardMoney: json['rewardMoney'] as int,
      rewardXp: json['rewardXp'] as int,
      targetCategory: json['targetCategory'] != null
          ? BuildingCategory.values[json['targetCategory'] as int]
          : null,
      currentValue: json['currentValue'] as int? ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isRewardClaimed: json['isRewardClaimed'] as bool? ?? false,
    );
  }
}

/// Monthly objectives container
class MonthlyObjectives {
  final int month; // 1-based (1 = first month of play)
  final String monthId;
  final DateTime startDate;
  final DateTime endDate;
  final List<MonthlyObjective> objectives;
  bool isOpened;

  MonthlyObjectives({
    required this.month,
    required this.monthId,
    required this.startDate,
    required this.endDate,
    required this.objectives,
    this.isOpened = false,
  });

  bool get allCompleted => objectives.every((o) => o.isCompleted);
  bool get allRewardsClaimed => objectives.every((o) => o.isRewardClaimed);
  int get completedCount => objectives.where((o) => o.isCompleted).length;
  int get totalRewardMoney => objectives.fold(0, (sum, o) => sum + o.rewardMoney);
  int get totalRewardXp => objectives.fold(0, (sum, o) => sum + o.rewardXp);
  int get claimableRewardMoney => objectives
      .where((o) => o.isCompleted && !o.isRewardClaimed)
      .fold(0, (sum, o) => sum + o.rewardMoney);
  int get claimableRewardXp => objectives
      .where((o) => o.isCompleted && !o.isRewardClaimed)
      .fold(0, (sum, o) => sum + o.rewardXp);

  Duration get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return Duration.zero;
    return endDate.difference(now);
  }

  bool get isExpired => DateTime.now().isAfter(endDate);

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'monthId': monthId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'objectives': objectives.map((o) => o.toJson()).toList(),
      'isOpened': isOpened,
    };
  }

  factory MonthlyObjectives.fromJson(Map<String, dynamic> json) {
    return MonthlyObjectives(
      month: json['month'] as int,
      monthId: json['monthId'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      objectives: (json['objectives'] as List)
          .map((o) => MonthlyObjective.fromJson(o as Map<String, dynamic>))
          .toList(),
      isOpened: json['isOpened'] as bool? ?? false,
    );
  }
}

/// Predefined monthly objectives data
class MonthlyObjectivesData {
  MonthlyObjectivesData._();

  /// Get objectives for a specific month (1-based)
  static List<MonthlyObjective> getObjectivesForMonth(int month) {
    if (month <= 0) return [];

    switch (month) {
      case 1:
        return _month1Objectives;
      case 2:
        return _month2Objectives;
      default:
        // For month 3+, scale objectives
        return _generateScaledObjectives(month);
    }
  }

  // ============ MONTH 1 - Beginner (First days) ============
  static final List<MonthlyObjective> _month1Objectives = [
    MonthlyObjective(
      id: 'm1_first_steps',
      title: 'Premier pas',
      description: 'Construire 3 maisons',
      type: ObjectiveType.buildCount,
      targetValue: 3,
      rewardMoney: 300,
      rewardXp: 20,
    ),
    MonthlyObjective(
      id: 'm1_small_community',
      title: 'Petite communaute',
      description: 'Atteindre 20 habitants',
      type: ObjectiveType.reachPopulation,
      targetValue: 20,
      rewardMoney: 500,
      rewardXp: 30,
    ),
    MonthlyObjective(
      id: 'm1_merchant',
      title: 'Commercant',
      description: 'Construire 1 commerce',
      type: ObjectiveType.buildCategory,
      targetValue: 1,
      targetCategory: BuildingCategory.commercial,
      rewardMoney: 400,
      rewardXp: 25,
    ),
    MonthlyObjective(
      id: 'm1_green_space',
      title: 'Espace vert',
      description: 'Placer 2 decorations',
      type: ObjectiveType.buildCategory,
      targetValue: 2,
      targetCategory: BuildingCategory.decoration,
      rewardMoney: 200,
      rewardXp: 15,
    ),
    MonthlyObjective(
      id: 'm1_saver',
      title: 'Econome',
      description: 'Collecter 1 000€ de revenus cumules',
      type: ObjectiveType.earnRevenue,
      targetValue: 1000,
      rewardMoney: 500,
      rewardXp: 30,
    ),
  ];

  // ============ MONTH 2 ============
  static final List<MonthlyObjective> _month2Objectives = [
    MonthlyObjective(
      id: 'm2_urbanist',
      title: 'Urbaniste',
      description: 'Construire 10 batiments au total',
      type: ObjectiveType.buildCount,
      targetValue: 10,
      rewardMoney: 1000,
      rewardXp: 50,
    ),
    MonthlyObjective(
      id: 'm2_100_souls',
      title: '100 ames',
      description: 'Atteindre 100 habitants',
      type: ObjectiveType.reachPopulation,
      targetValue: 100,
      rewardMoney: 1500,
      rewardXp: 80,
    ),
    MonthlyObjective(
      id: 'm2_downtown',
      title: 'Centre-ville',
      description: 'Avoir 3 commerces',
      type: ObjectiveType.buildCategory,
      targetValue: 3,
      targetCategory: BuildingCategory.commercial,
      rewardMoney: 800,
      rewardXp: 40,
    ),
    MonthlyObjective(
      id: 'm2_citizen_happiness',
      title: 'Bonheur citoyen',
      description: 'Atteindre 30% de bonheur',
      type: ObjectiveType.reachHappiness,
      targetValue: 30,
      rewardMoney: 1000,
      rewardXp: 60,
    ),
    MonthlyObjective(
      id: 'm2_first_million',
      title: 'Premier million',
      description: 'Gagner 10 000€ cumules',
      type: ObjectiveType.earnRevenue,
      targetValue: 10000,
      rewardMoney: 2000,
      rewardXp: 100,
    ),
  ];

  // ============ SCALED OBJECTIVES FOR MONTH 3+ ============
  static List<MonthlyObjective> _generateScaledObjectives(int month) {
    // Scale factor: 2x per month after month 2
    final scaleFactor = 1 << (month - 2); // 2^(month-2)

    return [
      MonthlyObjective(
        id: 'm${month}_builder',
        title: 'Grand Batisseur',
        description: 'Construire ${10 * scaleFactor} batiments',
        type: ObjectiveType.buildCount,
        targetValue: 10 * scaleFactor,
        rewardMoney: 1000 * scaleFactor,
        rewardXp: 50 * scaleFactor,
      ),
      MonthlyObjective(
        id: 'm${month}_population',
        title: 'Metropole',
        description: 'Atteindre ${100 * scaleFactor} habitants',
        type: ObjectiveType.reachPopulation,
        targetValue: 100 * scaleFactor,
        rewardMoney: 1500 * scaleFactor,
        rewardXp: 80 * scaleFactor,
      ),
      MonthlyObjective(
        id: 'm${month}_commerce',
        title: 'Centre commercial',
        description: 'Avoir ${3 * scaleFactor} commerces',
        type: ObjectiveType.buildCategory,
        targetValue: 3 * scaleFactor,
        targetCategory: BuildingCategory.commercial,
        rewardMoney: 800 * scaleFactor,
        rewardXp: 40 * scaleFactor,
      ),
      MonthlyObjective(
        id: 'm${month}_happiness',
        title: 'Ville heureuse',
        description: 'Atteindre ${(30 + month * 5).clamp(30, 90)}% de bonheur',
        type: ObjectiveType.reachHappiness,
        targetValue: (30 + month * 5).clamp(30, 90),
        rewardMoney: 1000 * scaleFactor,
        rewardXp: 60 * scaleFactor,
      ),
      MonthlyObjective(
        id: 'm${month}_revenue',
        title: 'Magnat',
        description: 'Gagner ${10000 * scaleFactor}€ cumules',
        type: ObjectiveType.earnRevenue,
        targetValue: 10000 * scaleFactor,
        rewardMoney: 2000 * scaleFactor,
        rewardXp: 100 * scaleFactor,
      ),
    ];
  }
}
