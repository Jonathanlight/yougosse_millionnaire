import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../game/data/game_state.dart';
import '../../models/monthly_objectives.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

/// Overlay for displaying and managing monthly objectives
class MonthlyObjectivesOverlay extends StatefulWidget {
  final GameState gameState;
  final VoidCallback onClose;
  final void Function(int money, int xp) onRewardClaimed;

  const MonthlyObjectivesOverlay({
    super.key,
    required this.gameState,
    required this.onClose,
    required this.onRewardClaimed,
  });

  @override
  State<MonthlyObjectivesOverlay> createState() => _MonthlyObjectivesOverlayState();
}

class _MonthlyObjectivesOverlayState extends State<MonthlyObjectivesOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  MonthlyObjectives? _currentMonthObjectives;
  int _currentMonth = 1;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
    _loadCurrentMonth();
  }

  Future<void> _loadCurrentMonth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentMonth = prefs.getInt('current_objective_month') ?? 1;

      // Load saved progress or create new objectives
      final savedObjectives = prefs.getString('monthly_objectives_$_currentMonth');
      if (savedObjectives != null) {
        try {
          final Map<String, dynamic> savedJson =
              Map<String, dynamic>.from(json.decode(savedObjectives) as Map);
          _currentMonthObjectives = MonthlyObjectives.fromJson(savedJson);
          _updateProgress();
          setState(() {
            _isLoading = false;
          });
          return;
        } catch (e) {
          // If parsing fails, create new objectives
        }
      }
    } catch (e) {
      // SharedPreferences may fail - use default month 1
      _currentMonth = 1;
    }

    _initializeObjectives();
  }


  void _initializeObjectives() {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      _currentMonthObjectives = MonthlyObjectives(
        month: _currentMonth,
        monthId: 'month_$_currentMonth',
        startDate: startOfMonth,
        endDate: endOfMonth,
        objectives: MonthlyObjectivesData.getObjectivesForMonth(_currentMonth),
      );

      // Update progress based on current game state
      _updateProgress();
    } catch (e) {
      // If initialization fails, create empty objectives
      _currentMonthObjectives = null;
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _updateProgress() {
    if (_currentMonthObjectives == null) return;

    for (final objective in _currentMonthObjectives!.objectives) {
      int currentValue = 0;

      switch (objective.type) {
        case ObjectiveType.buildCount:
          currentValue = widget.gameState.city.buildings.length;
          break;
        case ObjectiveType.reachPopulation:
          currentValue = widget.gameState.population;
          break;
        case ObjectiveType.earnRevenue:
          currentValue = widget.gameState.player.totalMoneyEarned;
          break;
        case ObjectiveType.buildCategory:
          if (objective.targetCategory != null) {
            currentValue = widget.gameState.city.buildings
                .where((b) => b.config.category == objective.targetCategory)
                .length;
          }
          break;
        case ObjectiveType.reachHappiness:
          currentValue = (widget.gameState.happiness * 100).round();
          break;
        case ObjectiveType.upgradeBuilding:
          // Not implemented yet
          currentValue = 0;
          break;
      }

      objective.updateProgress(currentValue);
    }
  }

  void _claimReward(MonthlyObjective objective) {
    if (objective.isCompleted && !objective.isRewardClaimed) {
      setState(() {
        objective.isRewardClaimed = true;
      });

      widget.onRewardClaimed(objective.rewardMoney, objective.rewardXp);

      // Show reward animation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.celebration, color: Colors.yellow),
              const SizedBox(width: 12),
              Text(
                '+${objective.rewardMoney.toCurrency()} et +${objective.rewardXp} XP!',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // Save progress
      _saveProgress();
    }
  }

  Future<void> _saveProgress() async {
    if (_currentMonthObjectives == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('current_objective_month', _currentMonth);

      // Save detailed objective progress
      final objectivesJson = json.encode(_currentMonthObjectives!.toJson());
      await prefs.setString('monthly_objectives_$_currentMonth', objectivesJson);
    } catch (e) {
      // Ignore save errors
    }
  }

  void _close() async {
    await _animationController.reverse();
    widget.onClose();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _close,
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping content
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  margin: const EdgeInsets.all(24),
                  constraints: const BoxConstraints(maxWidth: 450, maxHeight: 600),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.purple.withValues(alpha: 0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: _isLoading
                      ? _buildLoadingState()
                      : _currentMonthObjectives == null
                          ? _buildErrorState()
                          : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header
                            _buildHeader(),

                            // Objectives list
                            Flexible(
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                shrinkWrap: true,
                                itemCount: _currentMonthObjectives!.objectives.length,
                                itemBuilder: (context, index) {
                                  return _ObjectiveCard(
                                    objective: _currentMonthObjectives!.objectives[index],
                                    onClaimReward: _claimReward,
                                  );
                                },
                              ),
                            ),

                            // Footer with total rewards
                            _buildFooter(),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.all(48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.purple),
          SizedBox(height: 16),
          Text(
            'Chargement des objectifs...',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Impossible de charger les objectifs',
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadCurrentMonth();
            },
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final objectives = _currentMonthObjectives!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade800,
            Colors.purple.shade600,
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Objectifs du Mois $_currentMonth',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${objectives.completedCount}/${objectives.objectives.length} completes',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _close,
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final objectives = _currentMonthObjectives!;
    final claimable = objectives.objectives
        .where((o) => o.isCompleted && !o.isRewardClaimed)
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recompenses totales:',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${objectives.totalRewardMoney.toCurrency()} + ${objectives.totalRewardXp} XP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (claimable.isNotEmpty)
            Flexible(
              child: ElevatedButton(
                onPressed: () {
                  for (final obj in claimable) {
                    _claimReward(obj);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'Reclamer tout (${claimable.length})',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Card displaying a single objective
class _ObjectiveCard extends StatelessWidget {
  final MonthlyObjective objective;
  final void Function(MonthlyObjective) onClaimReward;

  const _ObjectiveCard({
    required this.objective,
    required this.onClaimReward,
  });

  @override
  Widget build(BuildContext context) {
    final isComplete = objective.isCompleted;
    final isClaimed = objective.isRewardClaimed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isClaimed
            ? Colors.green.withValues(alpha: 0.1)
            : isComplete
                ? Colors.yellow.withValues(alpha: 0.1)
                : Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isClaimed
              ? Colors.green.withValues(alpha: 0.5)
              : isComplete
                  ? Colors.yellow.withValues(alpha: 0.5)
                  : Colors.grey.shade700,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Icon(
                _getIcon(),
                color: isComplete ? Colors.yellow : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  objective.title,
                  style: TextStyle(
                    color: isClaimed ? Colors.grey : Colors.white,
                    fontWeight: FontWeight.bold,
                    decoration: isClaimed ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              if (isComplete && !isClaimed)
                TextButton(
                  onPressed: () => onClaimReward(objective),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                  child: const Text('Reclamer'),
                ),
              if (isClaimed)
                const Icon(Icons.check_circle, color: Colors.green, size: 24),
            ],
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            objective.description,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),

          // Progress bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: objective.progress,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade700,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isComplete ? Colors.green : Colors.purple,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${objective.currentValue}/${objective.targetValue}',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Rewards
          Row(
            children: [
              Icon(Icons.monetization_on, color: Colors.amber.shade400, size: 14),
              const SizedBox(width: 4),
              Text(
                '+${objective.rewardMoney}',
                style: TextStyle(
                  color: Colors.amber.shade400,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.star, color: Colors.blue.shade400, size: 14),
              const SizedBox(width: 4),
              Text(
                '+${objective.rewardXp} XP',
                style: TextStyle(
                  color: Colors.blue.shade400,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getIcon() {
    switch (objective.type) {
      case ObjectiveType.buildCount:
        return Icons.construction;
      case ObjectiveType.reachPopulation:
        return Icons.people;
      case ObjectiveType.earnRevenue:
        return Icons.euro;
      case ObjectiveType.buildCategory:
        return _getCategoryIcon();
      case ObjectiveType.reachHappiness:
        return Icons.sentiment_satisfied;
      case ObjectiveType.upgradeBuilding:
        return Icons.upgrade;
    }
  }

  IconData _getCategoryIcon() {
    if (objective.targetCategory == null) return Icons.home;

    switch (objective.targetCategory!) {
      case BuildingCategory.residential:
        return Icons.home;
      case BuildingCategory.commercial:
        return Icons.store;
      case BuildingCategory.industrial:
        return Icons.factory;
      case BuildingCategory.decoration:
        return Icons.park;
      case BuildingCategory.monument:
        return Icons.account_balance;
      case BuildingCategory.infrastructure:
        return Icons.route;
    }
  }
}
