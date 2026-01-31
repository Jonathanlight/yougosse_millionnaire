import '../data/game_state.dart';
import '../../utils/constants.dart';

/// Manages the economic aspects of the game
class EconomySystem {
  final GameState gameState;

  EconomySystem({required this.gameState});

  /// Update the economy (called every frame)
  /// With the new cycle-based system, revenue accumulates automatically
  /// based on each building's cycle duration and is collected when clicked
  void update(double dt) {
    // Revenue is now collected via the cycle-based system directly
    // when players tap on buildings. No interval-based accumulation needed.
    // Buildings track their own cycle progress via lastCollectedAt
  }

  /// Get total potential revenue from all buildings per hour
  double get totalPotentialRevenuePerHour {
    return gameState.city.totalRevenuePerMinute * 60;
  }

  /// Get revenue with happiness multiplier
  int getAdjustedRevenue(int baseRevenue) {
    return (baseRevenue * gameState.city.happinessMultiplier).round();
  }

  /// Calculate how much a building would earn per cycle with current multipliers
  int getEffectiveRevenue(BuildingType type) {
    final config = BuildingConfigs.getConfig(type);
    return (config.revenuePerCycle * gameState.city.happinessMultiplier).round();
  }

  /// Get ROI (return on investment) for a building type in hours
  double getROIHours(BuildingType type) {
    final config = BuildingConfigs.getConfig(type);
    if (!config.hasRevenue) return double.infinity;

    final effectiveRevenue = getEffectiveRevenue(type);
    if (effectiveRevenue <= 0) return double.infinity;

    // Calculate cycles needed to recover cost
    final cyclesNeeded = config.cost / effectiveRevenue;
    // Convert to hours (cycle duration is in minutes)
    return cyclesNeeded * (config.revenueCycleMinutes / 60);
  }

  /// Get ROI in cycles (how many collections to recover cost)
  int getROICycles(BuildingType type) {
    final config = BuildingConfigs.getConfig(type);
    if (!config.hasRevenue) return -1;

    final effectiveRevenue = getEffectiveRevenue(type);
    if (effectiveRevenue <= 0) return -1;

    return (config.cost / effectiveRevenue).ceil();
  }

  /// Check if player can afford a building
  bool canAfford(BuildingType type) {
    return gameState.player.canAfford(BuildingConfigs.getConfig(type).cost);
  }

  /// Get formatted cost string
  String getFormattedCost(BuildingType type) {
    return '\$${BuildingConfigs.getConfig(type).cost}';
  }

  /// Get formatted cycle duration string
  String getFormattedCycleDuration(BuildingType type) {
    final config = BuildingConfigs.getConfig(type);
    if (!config.hasRevenue) return '-';

    final minutes = config.revenueCycleMinutes;
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '${hours}h';
      }
      return '${hours}h ${remainingMinutes}m';
    }
    return '${minutes}m';
  }
}
