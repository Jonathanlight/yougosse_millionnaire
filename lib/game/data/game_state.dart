import 'package:flutter/foundation.dart';
import '../../models/building_model.dart';
import '../../models/city_model.dart';
import '../../models/player_model.dart';
import '../../utils/constants.dart';

/// Global game state that combines all models
class GameState extends ChangeNotifier {
  PlayerModel _player;
  CityModel _city;
  String _cityName;
  BuildingType? _selectedBuildingType;
  bool _isPlacementMode = false;
  int _hoveredCellX = -1;
  int _hoveredCellY = -1;

  // Move mode state
  bool _isMoveMode = false;
  String? _buildingToMoveId;

  GameState({
    PlayerModel? player,
    CityModel? city,
    String? cityName,
  })  : _player = player ?? PlayerModel(),
        _city = city ?? CityModel(),
        _cityName = cityName ?? 'Ma Ville';

  // Getters
  PlayerModel get player => _player;
  CityModel get city => _city;
  String get cityName => _cityName;
  BuildingType? get selectedBuildingType => _selectedBuildingType;
  bool get isPlacementMode => _isPlacementMode;
  int get hoveredCellX => _hoveredCellX;
  int get hoveredCellY => _hoveredCellY;

  // Move mode getters
  bool get isMoveMode => _isMoveMode;
  String? get buildingToMoveId => _buildingToMoveId;
  BuildingModel? get buildingToMove =>
      _buildingToMoveId != null ? _city.getBuildingById(_buildingToMoveId!) : null;

  // Computed properties
  int get money => _player.money;
  int get level => _player.level;
  int get population => _city.totalPopulation;
  double get happiness => _city.happiness;
  double get revenuePerMinute => _city.totalRevenuePerMinute;
  int get revenuePerCycle => _city.totalRevenuePerCycle;

  /// Set city name
  void setCityName(String name) {
    _cityName = name;
    notifyListeners();
  }

  /// Enter placement mode for a building type
  void enterPlacementMode(BuildingType type) {
    if (!_player.canAfford(BuildingConfigs.getConfig(type).cost)) {
      return;
    }
    _selectedBuildingType = type;
    _isPlacementMode = true;
    notifyListeners();
  }

  /// Exit placement mode
  void exitPlacementMode() {
    _selectedBuildingType = null;
    _isPlacementMode = false;
    _hoveredCellX = -1;
    _hoveredCellY = -1;
    notifyListeners();
  }

  // ==================== MOVE MODE ====================

  /// Enter move mode for a building
  void enterMoveMode(String buildingId) {
    final building = _city.getBuildingById(buildingId);
    if (building == null) return;

    _buildingToMoveId = buildingId;
    _isMoveMode = true;
    _isPlacementMode = false;
    _selectedBuildingType = building.type;
    notifyListeners();
  }

  /// Exit move mode
  void exitMoveMode() {
    _buildingToMoveId = null;
    _isMoveMode = false;
    _selectedBuildingType = null;
    _hoveredCellX = -1;
    _hoveredCellY = -1;
    notifyListeners();
  }

  /// Check if current move position is valid
  bool get isMoveValid {
    if (!_isMoveMode || _buildingToMoveId == null) return false;
    if (_hoveredCellX < 0 || _hoveredCellY < 0) return false;
    return _city.canMoveBuilding(_buildingToMoveId!, _hoveredCellX, _hoveredCellY);
  }

  /// Try to move the building to hovered position
  bool tryMoveBuilding() {
    if (!_isMoveMode || _buildingToMoveId == null) return false;
    if (_hoveredCellX < 0 || _hoveredCellY < 0) return false;

    if (!_city.canMoveBuilding(_buildingToMoveId!, _hoveredCellX, _hoveredCellY)) {
      return false;
    }

    _city.moveBuilding(_buildingToMoveId!, _hoveredCellX, _hoveredCellY);
    exitMoveMode();
    notifyListeners();
    return true;
  }

  /// Update hovered cell during placement
  void updateHoveredCell(int x, int y) {
    if (_hoveredCellX != x || _hoveredCellY != y) {
      _hoveredCellX = x;
      _hoveredCellY = y;
      notifyListeners();
    }
  }

  /// Check if current placement is valid
  bool get isPlacementValid {
    if (!_isPlacementMode || _selectedBuildingType == null) return false;
    if (_hoveredCellX < 0 || _hoveredCellY < 0) return false;
    return _city.canPlaceBuilding(
        _selectedBuildingType!, _hoveredCellX, _hoveredCellY);
  }

  /// Try to place the selected building at hovered position
  bool tryPlaceBuilding() {
    if (!_isPlacementMode || _selectedBuildingType == null) return false;
    if (_hoveredCellX < 0 || _hoveredCellY < 0) return false;

    final config = BuildingConfigs.getConfig(_selectedBuildingType!);

    if (!_player.canAfford(config.cost)) {
      return false;
    }

    if (!_city.canPlaceBuilding(
        _selectedBuildingType!, _hoveredCellX, _hoveredCellY)) {
      return false;
    }

    // Spend money and place building
    _player.trySpend(config.cost);
    _city.placeBuilding(_selectedBuildingType!, _hoveredCellX, _hoveredCellY);
    _player.addXp(GameConstants.xpPerBuilding);
    _player.buildingsPlaced++;

    // Exit placement mode
    exitPlacementMode();
    notifyListeners();
    return true;
  }

  /// Try to place a building at specific position
  bool placeBuilding(BuildingType type, int x, int y) {
    final config = BuildingConfigs.getConfig(type);

    if (!_player.canAfford(config.cost)) {
      return false;
    }

    if (!_city.canPlaceBuilding(type, x, y)) {
      return false;
    }

    _player.trySpend(config.cost);
    _city.placeBuilding(type, x, y);
    _player.addXp(GameConstants.xpPerBuilding);
    _player.buildingsPlaced++;

    notifyListeners();
    return true;
  }

  /// Collect revenue from a building
  int collectRevenue(String buildingId) {
    final building = _city.getBuildingById(buildingId);
    if (building == null) return 0;

    final revenue =
        (building.collectRevenue() * _city.happinessMultiplier).round();
    _player.addMoney(revenue);
    notifyListeners();
    return revenue;
  }

  /// Collect all pending revenue
  int collectAllRevenue() {
    int total = 0;
    for (final building in _city.buildingsWithRevenue) {
      final revenue =
          (building.collectRevenue() * _city.happinessMultiplier).round();
      total += revenue;
    }
    _player.addMoney(total);
    notifyListeners();
    return total;
  }

  /// Add money directly (for offline earnings, etc.)
  void addMoney(int amount) {
    _player.addMoney(amount);
    notifyListeners();
  }

  /// Add XP directly (for objective rewards, etc.)
  void addXp(int amount) {
    _player.addXp(amount);
    notifyListeners();
  }

  /// Remove a building
  bool removeBuilding(String buildingId) {
    final result = _city.removeBuilding(buildingId);
    if (result) {
      notifyListeners();
    }
    return result;
  }

  /// Get building at grid position
  BuildingModel? getBuildingAt(int x, int y) {
    return _city.getBuildingAt(x, y);
  }

  /// Update session time
  void updateSessionTime() {
    _player.updateSessionTime();
    notifyListeners();
  }

  /// Calculate and claim offline earnings
  int claimOfflineEarnings() {
    final earnings = _player.calculateOfflineEarnings(_city.totalRevenuePerMinute);
    if (earnings > 0) {
      _player.addMoney(earnings);
      _player.updateSessionTime();
      notifyListeners();
    }
    return earnings;
  }

  // ==================== BANK CREDIT SYSTEM ====================

  /// Check if player can take a credit
  bool get canTakeCredit => _player.canTakeCredit;

  /// Check if player has already taken a credit
  bool get hasTakenCredit => _player.hasTakenCredit;

  /// Check if player is in debt (negative balance)
  bool get isInDebt => _player.isInDebt;

  /// Get remaining credit debt
  int get remainingDebt => _player.remainingDebt;

  /// Request a bank credit
  bool takeCredit(int amount) {
    final success = _player.takeCredit(amount);
    if (success) {
      notifyListeners();
    }
    return success;
  }

  /// Process daily credit payment (call this on app start/resume)
  int processCreditPayment() {
    final deducted = _player.processDailyCreditPayment();
    if (deducted > 0) {
      notifyListeners();
    }
    return deducted;
  }

  /// Reset to new game
  void reset() {
    _player = PlayerModel();
    _city = CityModel();
    _cityName = 'Ma Ville';
    _selectedBuildingType = null;
    _isPlacementMode = false;
    _hoveredCellX = -1;
    _hoveredCellY = -1;
    notifyListeners();
  }

  /// Load state from saved data
  void loadFromSave(PlayerModel player, CityModel city, String? cityName) {
    _player = player;
    _city = city;
    _cityName = cityName ?? 'Ma Ville';
    _selectedBuildingType = null;
    _isPlacementMode = false;
    notifyListeners();
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'player': _player.toJson(),
      'city': _city.toJson(),
      'cityName': _cityName,
    };
  }

  /// Create from JSON
  factory GameState.fromJson(Map<String, dynamic> json) {
    return GameState(
      player: PlayerModel.fromJson(json['player'] as Map<String, dynamic>),
      city: CityModel.fromJson(json['city'] as Map<String, dynamic>),
      cityName: json['cityName'] as String? ?? 'Ma Ville',
    );
  }
}
