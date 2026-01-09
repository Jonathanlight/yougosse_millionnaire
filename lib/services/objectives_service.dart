import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/objective_model.dart';
import '../utils/constants.dart';

/// Service for managing weekly objectives
class ObjectivesService extends ChangeNotifier {
  WeeklyObjectives? _currentWeek;
  final Random _random = Random();

  WeeklyObjectives? get currentWeek => _currentWeek;
  bool get hasNewObjectives => _currentWeek != null && !_currentWeek!.isOpened;
  bool get hasClaimableRewards =>
      _currentWeek != null && _currentWeek!.claimableReward > 0;

  /// Initialize or load objectives
  void initialize(Map<String, dynamic>? savedData) {
    if (savedData != null && savedData.containsKey('currentWeek')) {
      _currentWeek = WeeklyObjectives.fromJson(
        savedData['currentWeek'] as Map<String, dynamic>,
      );

      // Check if week is expired, generate new if so
      if (_currentWeek!.isExpired) {
        _generateNewWeek();
      }
    } else {
      _generateNewWeek();
    }
    notifyListeners();
  }

  /// Generate new weekly objectives
  void _generateNewWeek() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    final weekId = '${now.year}-W${_getWeekNumber(now)}';

    _currentWeek = WeeklyObjectives(
      weekId: weekId,
      startDate: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
      endDate: DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59),
      objectives: _generateObjectives(),
      isOpened: false,
    );
  }

  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysDiff = date.difference(firstDayOfYear).inDays;
    return ((daysDiff + firstDayOfYear.weekday - 1) / 7).ceil();
  }

  List<Objective> _generateObjectives() {
    // Generate 5 random objectives for the week
    final objectives = <Objective>[];
    final usedTypes = <ObjectiveType>{};

    final possibleObjectives = [
      _createCollectMoneyObjective,
      _createBuildBuildingsObjective,
      _createPopulationObjective,
      _createCollectRevenueObjective,
      _createHappinessObjective,
    ];

    // Shuffle and pick 5 objectives
    possibleObjectives.shuffle(_random);

    for (int i = 0; i < 5 && i < possibleObjectives.length; i++) {
      objectives.add(possibleObjectives[i](i));
    }

    return objectives;
  }

  Objective _createCollectMoneyObjective(int index) {
    final targets = [1000, 2500, 5000, 10000, 25000];
    final rewards = [200, 500, 1000, 2000, 5000];
    final level = _random.nextInt(targets.length);

    return Objective(
      id: 'collect_money_$index',
      title: 'Collecteur',
      description: 'Collecter ${targets[level]}€ au total',
      type: ObjectiveType.collectMoney,
      targetValue: targets[level],
      reward: rewards[level],
    );
  }

  Objective _createBuildBuildingsObjective(int index) {
    final target = 2 + _random.nextInt(4); // 2-5 buildings
    final reward = target * 300;

    return Objective(
      id: 'build_buildings_$index',
      title: 'Constructeur',
      description: 'Construire $target batiments',
      type: ObjectiveType.buildBuildings,
      targetValue: target,
      reward: reward,
    );
  }

  Objective _createPopulationObjective(int index) {
    final targets = [50, 100, 200, 500, 1000];
    final rewards = [500, 1000, 2000, 5000, 10000];
    final level = _random.nextInt(targets.length);

    return Objective(
      id: 'population_$index',
      title: 'Maire populaire',
      description: 'Atteindre ${targets[level]} habitants',
      type: ObjectiveType.reachPopulation,
      targetValue: targets[level],
      reward: rewards[level],
    );
  }

  Objective _createCollectRevenueObjective(int index) {
    final target = 5 + _random.nextInt(11); // 5-15 collections
    final reward = target * 100;

    return Objective(
      id: 'collect_revenue_$index',
      title: 'Percepteur',
      description: 'Collecter des revenus $target fois',
      type: ObjectiveType.collectRevenue,
      targetValue: target,
      reward: reward,
    );
  }

  Objective _createHappinessObjective(int index) {
    final targets = [60, 70, 80, 90];
    final rewards = [300, 600, 1000, 2000];
    final level = _random.nextInt(targets.length);

    return Objective(
      id: 'happiness_$index',
      title: 'Ville heureuse',
      description: 'Atteindre ${targets[level]}% de bonheur',
      type: ObjectiveType.reachHappiness,
      targetValue: targets[level],
      reward: rewards[level],
    );
  }

  /// Open the envelope
  void openEnvelope() {
    if (_currentWeek != null) {
      _currentWeek!.isOpened = true;
      notifyListeners();
    }
  }

  /// Update objective progress based on game events
  void updateProgress({
    int? totalMoneyCollected,
    int? buildingsBuilt,
    int? population,
    int? level,
    int? revenueCollections,
    double? happiness,
  }) {
    if (_currentWeek == null) return;

    bool changed = false;

    for (final objective in _currentWeek!.objectives) {
      if (objective.isCompleted) continue;

      switch (objective.type) {
        case ObjectiveType.collectMoney:
          if (totalMoneyCollected != null) {
            objective.updateProgress(totalMoneyCollected);
            changed = true;
          }
          break;
        case ObjectiveType.buildBuildings:
          if (buildingsBuilt != null) {
            objective.updateProgress(buildingsBuilt);
            changed = true;
          }
          break;
        case ObjectiveType.reachPopulation:
          if (population != null) {
            objective.updateProgress(population);
            changed = true;
          }
          break;
        case ObjectiveType.reachLevel:
          if (level != null) {
            objective.updateProgress(level);
            changed = true;
          }
          break;
        case ObjectiveType.collectRevenue:
          if (revenueCollections != null) {
            objective.updateProgress(revenueCollections);
            changed = true;
          }
          break;
        case ObjectiveType.reachHappiness:
          if (happiness != null) {
            objective.updateProgress((happiness * 100).round());
            changed = true;
          }
          break;
        case ObjectiveType.buildSpecific:
          // Handle specific building objectives
          break;
      }
    }

    if (changed) {
      notifyListeners();
    }
  }

  /// Claim reward for a completed objective
  int claimReward(String objectiveId) {
    if (_currentWeek == null) return 0;

    final objective = _currentWeek!.objectives
        .firstWhere((o) => o.id == objectiveId, orElse: () => throw Exception('Objective not found'));

    if (objective.isCompleted && !objective.isRewardClaimed) {
      objective.isRewardClaimed = true;
      notifyListeners();
      return objective.reward;
    }

    return 0;
  }

  /// Claim all available rewards
  int claimAllRewards() {
    if (_currentWeek == null) return 0;

    int totalReward = 0;
    for (final objective in _currentWeek!.objectives) {
      if (objective.isCompleted && !objective.isRewardClaimed) {
        objective.isRewardClaimed = true;
        totalReward += objective.reward;
      }
    }

    if (totalReward > 0) {
      notifyListeners();
    }

    return totalReward;
  }

  /// Export data for saving
  Map<String, dynamic> toJson() {
    return {
      if (_currentWeek != null) 'currentWeek': _currentWeek!.toJson(),
    };
  }
}