import 'package:uuid/uuid.dart';
import '../utils/constants.dart';

/// Represents a placed building in the city
class BuildingModel {
  final String id;
  final BuildingType type;
  final int gridX;
  final int gridY;
  final DateTime placedAt;
  final DateTime? constructionEndTime;
  DateTime lastCollectedAt;
  int pendingRevenue;

  BuildingModel({
    String? id,
    required this.type,
    required this.gridX,
    required this.gridY,
    DateTime? placedAt,
    this.constructionEndTime,
    DateTime? lastCollectedAt,
    this.pendingRevenue = 0,
  })  : id = id ?? const Uuid().v4(),
        placedAt = placedAt ?? DateTime.now(),
        lastCollectedAt = lastCollectedAt ?? DateTime.now();

  /// Get the building configuration
  BuildingConfig get config => BuildingConfigs.getConfig(type);

  /// Check if building is under construction
  bool get isUnderConstruction {
    if (constructionEndTime == null) return false;
    return DateTime.now().isBefore(constructionEndTime!);
  }

  /// Get construction progress (0.0 to 1.0)
  double get constructionProgress {
    if (constructionEndTime == null) return 1.0;
    if (!isUnderConstruction) return 1.0;

    final totalSeconds = config.constructionTimeSeconds;
    if (totalSeconds == 0) return 1.0;

    final elapsed = DateTime.now().difference(placedAt).inSeconds;
    return (elapsed / totalSeconds).clamp(0.0, 1.0);
  }

  /// Get remaining construction time
  Duration get remainingConstructionTime {
    if (constructionEndTime == null) return Duration.zero;
    if (!isUnderConstruction) return Duration.zero;

    return constructionEndTime!.difference(DateTime.now());
  }

  /// Calculate uncollected revenue
  int calculatePendingRevenue() {
    if (isUnderConstruction) return 0;
    if (config.revenuePerMinute == 0) return 0;

    final minutesSinceLastCollection =
        DateTime.now().difference(lastCollectedAt).inMinutes;
    return minutesSinceLastCollection * config.revenuePerMinute;
  }

  /// Check if there's revenue to collect
  bool get hasRevenueToCollect {
    return calculatePendingRevenue() > 0 || pendingRevenue > 0;
  }

  /// Collect revenue and return amount
  int collectRevenue() {
    final revenue = calculatePendingRevenue() + pendingRevenue;
    lastCollectedAt = DateTime.now();
    pendingRevenue = 0;
    return revenue;
  }

  /// Get cells occupied by this building
  List<(int, int)> get occupiedCells {
    final cells = <(int, int)>[];
    for (int dx = 0; dx < config.width; dx++) {
      for (int dy = 0; dy < config.height; dy++) {
        cells.add((gridX + dx, gridY + dy));
      }
    }
    return cells;
  }

  /// Check if a grid position is within this building
  bool containsCell(int x, int y) {
    return x >= gridX &&
        x < gridX + config.width &&
        y >= gridY &&
        y < gridY + config.height;
  }

  /// Create a copy with updated fields
  BuildingModel copyWith({
    String? id,
    BuildingType? type,
    int? gridX,
    int? gridY,
    DateTime? placedAt,
    DateTime? constructionEndTime,
    DateTime? lastCollectedAt,
    int? pendingRevenue,
  }) {
    return BuildingModel(
      id: id ?? this.id,
      type: type ?? this.type,
      gridX: gridX ?? this.gridX,
      gridY: gridY ?? this.gridY,
      placedAt: placedAt ?? this.placedAt,
      constructionEndTime: constructionEndTime ?? this.constructionEndTime,
      lastCollectedAt: lastCollectedAt ?? this.lastCollectedAt,
      pendingRevenue: pendingRevenue ?? this.pendingRevenue,
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'gridX': gridX,
      'gridY': gridY,
      'placedAt': placedAt.toIso8601String(),
      'constructionEndTime': constructionEndTime?.toIso8601String(),
      'lastCollectedAt': lastCollectedAt.toIso8601String(),
      'pendingRevenue': pendingRevenue,
    };
  }

  /// Create from JSON
  factory BuildingModel.fromJson(Map<String, dynamic> json) {
    return BuildingModel(
      id: json['id'] as String,
      type: BuildingType.values[json['type'] as int],
      gridX: json['gridX'] as int,
      gridY: json['gridY'] as int,
      placedAt: DateTime.parse(json['placedAt'] as String),
      constructionEndTime: json['constructionEndTime'] != null
          ? DateTime.parse(json['constructionEndTime'] as String)
          : null,
      lastCollectedAt: DateTime.parse(json['lastCollectedAt'] as String),
      pendingRevenue: json['pendingRevenue'] as int? ?? 0,
    );
  }

  @override
  String toString() {
    return 'BuildingModel(id: $id, type: $type, position: ($gridX, $gridY))';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BuildingModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
