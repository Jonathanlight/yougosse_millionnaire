import '../data/game_state.dart';
import '../../utils/constants.dart';

/// Manages the economic aspects of the game
class EconomySystem {
  final GameState gameState;
  double _revenueAccumulator = 0;

  EconomySystem({required this.gameState});

  /// Update the economy (called every frame)
  void update(double dt) {
    _revenueAccumulator += dt;

    // Generate passive revenue every configured interval
    if (_revenueAccumulator >= GameConstants.revenueIntervalSeconds) {
      _revenueAccumulator = 0;
      _generatePassiveRevenue();
    }
  }

  /// Generate passive revenue for all buildings
  void _generatePassiveRevenue() {
    for (final building in gameState.city.buildings) {
      if (building.isUnderConstruction) continue;
      if (building.config.revenuePerMinute <= 0) continue;

      // Add to pending revenue (requires manual collection)
      building.pendingRevenue += building.config.revenuePerMinute;
    }
  }

  /// Get total potential revenue from all buildings
  int get totalPotentialRevenue {
    return gameState.city.buildings
        .where((b) => !b.isUnderConstruction)
        .fold(0, (sum, b) => sum + b.config.revenuePerMinute);
  }

  /// Get revenue with happiness multiplier
  int getAdjustedRevenue(int baseRevenue) {
    return (baseRevenue * gameState.city.happinessMultiplier).round();
  }

  /// Calculate how much a building would earn per minute with current multipliers
  int getEffectiveRevenue(BuildingType type) {
    final config = BuildingConfigs.getConfig(type);
    return (config.revenuePerMinute * gameState.city.happinessMultiplier)
        .round();
  }

  /// Get ROI (return on investment) for a building type in minutes
  double getROI(BuildingType type) {
    final config = BuildingConfigs.getConfig(type);
    if (config.revenuePerMinute <= 0) return double.infinity;

    final effectiveRevenue = getEffectiveRevenue(type);
    if (effectiveRevenue <= 0) return double.infinity;

    return config.cost / effectiveRevenue;
  }

  /// Check if player can afford a building
  bool canAfford(BuildingType type) {
    return gameState.player.canAfford(BuildingConfigs.getConfig(type).cost);
  }

  /// Get formatted cost string
  String getFormattedCost(BuildingType type) {
    return '\$${BuildingConfigs.getConfig(type).cost}';
  }
}
