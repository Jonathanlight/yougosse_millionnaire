import '../utils/constants.dart';
import 'building_model.dart';

/// Represents the city grid and all placed buildings
class CityModel {
  final int width;
  final int height;
  final List<BuildingModel> buildings;

  CityModel({
    this.width = GameConstants.gridWidth,
    this.height = GameConstants.gridHeight,
    List<BuildingModel>? buildings,
  }) : buildings = buildings ?? [];

  /// Get building at a specific cell
  BuildingModel? getBuildingAt(int x, int y) {
    for (final building in buildings) {
      if (building.containsCell(x, y)) {
        return building;
      }
    }
    return null;
  }

  /// Get building by ID
  BuildingModel? getBuildingById(String id) {
    for (final building in buildings) {
      if (building.id == id) {
        return building;
      }
    }
    return null;
  }

  /// Check if a cell is occupied
  bool isCellOccupied(int x, int y) {
    return getBuildingAt(x, y) != null;
  }

  /// Check if a building can be placed at position
  bool canPlaceBuilding(BuildingType type, int x, int y) {
    final config = BuildingConfigs.getConfig(type);

    // Check if within grid bounds
    if (x < 0 || y < 0) return false;
    if (x + config.width > width) return false;
    if (y + config.height > height) return false;

    // Check if all cells are free
    for (int dx = 0; dx < config.width; dx++) {
      for (int dy = 0; dy < config.height; dy++) {
        if (isCellOccupied(x + dx, y + dy)) {
          return false;
        }
      }
    }

    return true;
  }

  /// Place a building at position
  BuildingModel? placeBuilding(BuildingType type, int x, int y) {
    if (!canPlaceBuilding(type, x, y)) return null;

    final config = BuildingConfigs.getConfig(type);
    final constructionEndTime = config.constructionTimeSeconds > 0
        ? DateTime.now().add(Duration(seconds: config.constructionTimeSeconds))
        : null;

    final building = BuildingModel(
      type: type,
      gridX: x,
      gridY: y,
      constructionEndTime: constructionEndTime,
    );

    buildings.add(building);
    return building;
  }

  /// Remove a building
  bool removeBuilding(String id) {
    final initialLength = buildings.length;
    buildings.removeWhere((b) => b.id == id);
    return buildings.length < initialLength;
  }

  /// Check if a building can be moved to a new position
  bool canMoveBuilding(String id, int newX, int newY) {
    final building = getBuildingById(id);
    if (building == null) return false;

    final config = building.config;

    // Check if within grid bounds
    if (newX < 0 || newY < 0) return false;
    if (newX + config.width > width) return false;
    if (newY + config.height > height) return false;

    // Check if all cells are free (excluding the building being moved)
    for (int dx = 0; dx < config.width; dx++) {
      for (int dy = 0; dy < config.height; dy++) {
        final existingBuilding = getBuildingAt(newX + dx, newY + dy);
        if (existingBuilding != null && existingBuilding.id != id) {
          return false;
        }
      }
    }

    return true;
  }

  /// Move a building to a new position
  bool moveBuilding(String id, int newX, int newY) {
    if (!canMoveBuilding(id, newX, newY)) return false;

    final buildingIndex = buildings.indexWhere((b) => b.id == id);
    if (buildingIndex == -1) return false;

    final building = buildings[buildingIndex];
    buildings[buildingIndex] = building.copyWith(gridX: newX, gridY: newY);
    return true;
  }

  /// Get total population
  int get totalPopulation {
    return buildings
        .where((b) => !b.isUnderConstruction)
        .fold(0, (sum, b) => sum + b.config.population);
  }

  /// Get total revenue per minute (calculated from cycle data)
  double get totalRevenuePerMinute {
    return buildings
        .where((b) => !b.isUnderConstruction && b.config.hasRevenue)
        .fold(0.0, (sum, b) => sum + b.config.revenuePerMinute);
  }

  /// Get total revenue per cycle for display
  int get totalRevenuePerCycle {
    return buildings
        .where((b) => !b.isUnderConstruction && b.config.hasRevenue)
        .fold(0, (sum, b) => sum + b.config.revenuePerCycle);
  }

  /// Get happiness (0.0 to 1.0+)
  double get happiness {
    if (buildings.isEmpty) return 1.0;

    final completedBuildings =
        buildings.where((b) => !b.isUnderConstruction).toList();
    if (completedBuildings.isEmpty) return 1.0;

    // Base happiness starts at 0.5
    double baseHappiness = 0.5;

    // Add happiness bonuses from buildings
    for (final building in completedBuildings) {
      baseHappiness += building.config.happinessBonus;
    }

    // Decorations provide bonus based on ratio to other buildings
    final decorationCount = completedBuildings
        .where((b) => b.config.category == BuildingCategory.decoration)
        .length;
    final otherCount = completedBuildings.length - decorationCount;

    if (otherCount > 0) {
      baseHappiness += (decorationCount / otherCount) * 0.3;
    }

    return baseHappiness.clamp(0.0, GameConstants.happinessMultiplierMax);
  }

  /// Get happiness multiplier for revenue
  double get happinessMultiplier {
    return 0.5 + (happiness * 0.5);
  }

  /// Get buildings with revenue to collect
  List<BuildingModel> get buildingsWithRevenue {
    return buildings.where((b) => b.hasRevenueToCollect).toList();
  }

  /// Get buildings by type
  List<BuildingModel> getBuildingsByType(BuildingType type) {
    return buildings.where((b) => b.type == type).toList();
  }

  /// Get count of buildings by category
  Map<BuildingCategory, int> get buildingCountByCategory {
    final counts = <BuildingCategory, int>{};
    for (final category in BuildingCategory.values) {
      counts[category] = 0;
    }
    for (final building in buildings) {
      counts[building.config.category] =
          (counts[building.config.category] ?? 0) + 1;
    }
    return counts;
  }

  /// Create a copy with updated fields
  CityModel copyWith({
    int? width,
    int? height,
    List<BuildingModel>? buildings,
  }) {
    return CityModel(
      width: width ?? this.width,
      height: height ?? this.height,
      buildings: buildings ?? List.from(this.buildings),
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'width': width,
      'height': height,
      'buildings': buildings.map((b) => b.toJson()).toList(),
    };
  }

  /// Create from JSON
  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      width: json['width'] as int? ?? GameConstants.gridWidth,
      height: json['height'] as int? ?? GameConstants.gridHeight,
      buildings: (json['buildings'] as List<dynamic>?)
              ?.map((b) => BuildingModel.fromJson(b as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  String toString() {
    return 'CityModel(${width}x$height, ${buildings.length} buildings)';
  }
}
