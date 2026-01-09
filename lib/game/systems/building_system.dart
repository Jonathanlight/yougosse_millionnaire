import 'package:flame/components.dart';
import '../city_game.dart';
import '../components/building.dart';
import '../components/grid_cell.dart';
import '../data/game_state.dart';
import '../../models/building_model.dart';
import '../../utils/constants.dart';

/// Manages building placement and construction
class BuildingSystem {
  final CityGame game;
  final GameState gameState;
  final Map<String, BuildingComponent> _buildingComponents = {};

  GridCellHighlight? _placementHighlight;
  GridTapDetector? _gridTapDetector;

  BuildingSystem({
    required this.game,
    required this.gameState,
  });

  /// Initialize the building system
  Future<void> initialize(Component parentComponent) async {
    // Ensure building images are loaded first
    await BuildingComponent.loadBuildingImages();

    // Create grid tap detector
    _gridTapDetector = GridTapDetector(
      gridWidth: gameState.city.width,
      gridHeight: gameState.city.height,
      cellSize: GameConstants.cellSize,
      onCellTapped: _onCellTapped,
    );
    parentComponent.add(_gridTapDetector!);

    // Load existing buildings
    for (final building in gameState.city.buildings) {
      await _addBuildingComponent(building, parentComponent);
    }
  }

  /// Update building system (check construction completion, etc.)
  void update(double dt) {
    // Check for completed constructions
    for (final building in gameState.city.buildings) {
      if (building.isUnderConstruction) {
        // Building still under construction, component will handle animation
      }
    }

    // Update placement/move highlight
    if ((gameState.isPlacementMode || gameState.isMoveMode) && _placementHighlight == null) {
      _createPlacementHighlight();
    } else if (!gameState.isPlacementMode && !gameState.isMoveMode && _placementHighlight != null) {
      _removePlacementHighlight();
    }
  }

  void _onCellTapped(int x, int y) {
    if (gameState.isMoveMode) {
      // Try to move the building to this position
      gameState.updateHoveredCell(x, y);
      if (gameState.isMoveValid) {
        _moveBuilding(x, y);
      }
    } else if (gameState.isPlacementMode) {
      // Update hovered cell and try to place
      gameState.updateHoveredCell(x, y);
      if (gameState.isPlacementValid) {
        _placeBuilding(x, y);
      }
    } else {
      // Check if there's a building at this position
      final building = gameState.getBuildingAt(x, y);
      if (building != null) {
        // Building tap is handled by BuildingComponent
      }
    }
  }

  void _moveBuilding(int x, int y) {
    final buildingId = gameState.buildingToMoveId;
    if (buildingId == null) return;

    // Get old position for component update
    final building = gameState.buildingToMove;
    if (building == null) return;

    if (gameState.tryMoveBuilding()) {
      // Update the building component position
      final component = _buildingComponents[buildingId];
      if (component != null) {
        // Get the updated building model
        final updatedBuilding = gameState.city.getBuildingById(buildingId);
        if (updatedBuilding != null) {
          component.updatePosition(updatedBuilding.gridX, updatedBuilding.gridY);
        }
      }
    }
  }

  void _placeBuilding(int x, int y) {
    final type = gameState.selectedBuildingType;
    if (type == null) return;

    if (gameState.tryPlaceBuilding()) {
      // Find the newly placed building
      final building = gameState.city.buildings.lastOrNull;
      if (building != null) {
        _addBuildingComponent(building, game.world);
      }
    }
  }

  Future<void> _addBuildingComponent(
      BuildingModel building, Component parent) async {
    final component = BuildingComponent(
      model: building,
      cellSize: GameConstants.cellSize,
    );
    _buildingComponents[building.id] = component;
    parent.add(component);
  }

  void removeBuildingComponent(String buildingId) {
    final component = _buildingComponents.remove(buildingId);
    component?.removeFromParent();
    gameState.removeBuilding(buildingId);
  }

  void _createPlacementHighlight() {
    if (gameState.selectedBuildingType == null) return;

    final config = BuildingConfigs.getConfig(gameState.selectedBuildingType!);
    // Use isMoveValid when in move mode, isPlacementValid otherwise
    final isValid = gameState.isMoveMode
        ? gameState.isMoveValid
        : gameState.isPlacementValid;

    _placementHighlight = GridCellHighlight(
      gridX: gameState.hoveredCellX >= 0 ? gameState.hoveredCellX : 0,
      gridY: gameState.hoveredCellY >= 0 ? gameState.hoveredCellY : 0,
      gridWidth: config.width,
      gridHeight: config.height,
      cellSize: GameConstants.cellSize,
      isValid: isValid,
    );
    game.world.add(_placementHighlight!);
  }

  void _removePlacementHighlight() {
    _placementHighlight?.removeFromParent();
    _placementHighlight = null;
  }

  /// Update placement highlight position and validity
  void updatePlacementHighlight(int gridX, int gridY) {
    if (_placementHighlight == null || gameState.selectedBuildingType == null) {
      return;
    }

    gameState.updateHoveredCell(gridX, gridY);
    // Use isMoveValid when in move mode, isPlacementValid otherwise
    final isValid = gameState.isMoveMode
        ? gameState.isMoveValid
        : gameState.isPlacementValid;

    _placementHighlight!.updatePosition(
      gridX,
      gridY,
      isValid,
    );
  }

  /// Enter placement mode for a building type
  void enterPlacementMode(BuildingType type) {
    gameState.enterPlacementMode(type);
    _createPlacementHighlight();
  }

  /// Exit placement mode
  void exitPlacementMode() {
    gameState.exitPlacementMode();
    _removePlacementHighlight();
  }

  /// Enter move mode for a building
  void enterMoveMode(String buildingId) {
    gameState.enterMoveMode(buildingId);
    _createPlacementHighlight();
  }

  /// Exit move mode
  void exitMoveMode() {
    gameState.exitMoveMode();
    _removePlacementHighlight();
  }

  /// Get building component by ID
  BuildingComponent? getBuildingComponent(String id) {
    return _buildingComponents[id];
  }

  /// Get all building components
  Iterable<BuildingComponent> get allBuildingComponents =>
      _buildingComponents.values;
}
