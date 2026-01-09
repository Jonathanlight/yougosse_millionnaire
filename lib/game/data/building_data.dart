import '../../utils/constants.dart';

/// Helper class for building data operations
class BuildingData {
  BuildingData._();

  /// Get all building types as a list
  static List<BuildingType> get allTypes => BuildingType.values;

  /// Get buildings available at a specific level
  static List<BuildingConfig> getAvailableBuildings(int playerLevel) {
    return BuildingConfigs.configs.values
        .where((config) => config.unlockLevel <= playerLevel)
        .toList()
      ..sort((a, b) => a.cost.compareTo(b.cost));
  }

  /// Get buildings by category that are unlocked
  static List<BuildingConfig> getUnlockedByCategory(
      BuildingCategory category, int playerLevel) {
    return BuildingConfigs.configs.values
        .where((config) =>
            config.category == category && config.unlockLevel <= playerLevel)
        .toList()
      ..sort((a, b) => a.cost.compareTo(b.cost));
  }

  /// Get building categories with their names
  static Map<BuildingCategory, String> get categoryNames => {
        BuildingCategory.residential: 'Residentiel',
        BuildingCategory.commercial: 'Commercial',
        BuildingCategory.industrial: 'Industriel',
        BuildingCategory.decoration: 'Decoration',
        BuildingCategory.monument: 'Monuments',
        BuildingCategory.infrastructure: 'Routes',
      };

  /// Get building type display name
  static String getTypeName(BuildingType type) {
    return BuildingConfigs.getConfig(type).name;
  }

  /// Check if a building type is unlocked at level
  static bool isUnlocked(BuildingType type, int level) {
    return BuildingConfigs.getConfig(type).unlockLevel <= level;
  }

  /// Get next locked building
  static BuildingConfig? getNextLockedBuilding(int playerLevel) {
    final locked = BuildingConfigs.configs.values
        .where((config) => config.unlockLevel > playerLevel)
        .toList()
      ..sort((a, b) => a.unlockLevel.compareTo(b.unlockLevel));

    return locked.isNotEmpty ? locked.first : null;
  }

  /// Calculate total cost to build
  static int calculateTotalCost(List<BuildingType> types) {
    return types.fold(
        0, (sum, type) => sum + BuildingConfigs.getConfig(type).cost);
  }
}
