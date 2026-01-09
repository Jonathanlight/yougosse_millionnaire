import 'package:flutter/foundation.dart';

/// Types of objectives
enum ObjectiveType {
  collectMoney,      // Collecter X euros
  buildBuildings,    // Construire X batiments
  reachPopulation,   // Atteindre X population
  reachLevel,        // Atteindre niveau X
  buildSpecific,     // Construire un batiment specifique
  collectRevenue,    // Collecter des revenus X fois
  reachHappiness,    // Atteindre X% de bonheur
}

/// A single objective
class Objective {
  final String id;
  final String title;
  final String description;
  final ObjectiveType type;
  final int targetValue;
  final int reward;
  int currentValue;
  bool isCompleted;
  bool isRewardClaimed;

  Objective({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.targetValue,
    required this.reward,
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

  Objective copyWith({
    String? id,
    String? title,
    String? description,
    ObjectiveType? type,
    int? targetValue,
    int? reward,
    int? currentValue,
    bool? isCompleted,
    bool? isRewardClaimed,
  }) {
    return Objective(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      reward: reward ?? this.reward,
      currentValue: currentValue ?? this.currentValue,
      isCompleted: isCompleted ?? this.isCompleted,
      isRewardClaimed: isRewardClaimed ?? this.isRewardClaimed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.index,
      'targetValue': targetValue,
      'reward': reward,
      'currentValue': currentValue,
      'isCompleted': isCompleted,
      'isRewardClaimed': isRewardClaimed,
    };
  }

  factory Objective.fromJson(Map<String, dynamic> json) {
    return Objective(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: ObjectiveType.values[json['type'] as int],
      targetValue: json['targetValue'] as int,
      reward: json['reward'] as int,
      currentValue: json['currentValue'] as int? ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isRewardClaimed: json['isRewardClaimed'] as bool? ?? false,
    );
  }
}

/// Weekly objectives envelope
class WeeklyObjectives {
  final String weekId;
  final DateTime startDate;
  final DateTime endDate;
  final List<Objective> objectives;
  bool isOpened;

  WeeklyObjectives({
    required this.weekId,
    required this.startDate,
    required this.endDate,
    required this.objectives,
    this.isOpened = false,
  });

  bool get allCompleted => objectives.every((o) => o.isCompleted);
  bool get allRewardsClaimed => objectives.every((o) => o.isRewardClaimed);
  int get completedCount => objectives.where((o) => o.isCompleted).length;
  int get totalReward => objectives.fold(0, (sum, o) => sum + o.reward);
  int get claimableReward => objectives
      .where((o) => o.isCompleted && !o.isRewardClaimed)
      .fold(0, (sum, o) => sum + o.reward);

  Duration get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return Duration.zero;
    return endDate.difference(now);
  }

  bool get isExpired => DateTime.now().isAfter(endDate);

  Map<String, dynamic> toJson() {
    return {
      'weekId': weekId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'objectives': objectives.map((o) => o.toJson()).toList(),
      'isOpened': isOpened,
    };
  }

  factory WeeklyObjectives.fromJson(Map<String, dynamic> json) {
    return WeeklyObjectives(
      weekId: json['weekId'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      objectives: (json['objectives'] as List)
          .map((o) => Objective.fromJson(o as Map<String, dynamic>))
          .toList(),
      isOpened: json['isOpened'] as bool? ?? false,
    );
  }
}
