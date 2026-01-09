import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/building_model.dart';
import '../services/weather_service.dart';
import '../utils/constants.dart';
import 'components/person.dart';
import 'components/terrain.dart';
import 'components/weather_effects.dart';
import 'data/game_state.dart';
import 'systems/building_system.dart';
import 'systems/economy_system.dart';
import 'systems/time_system.dart';

/// Main game class for the city builder
class CityGame extends FlameGame
    with
        HasKeyboardHandlerComponents,
        PanDetector,
        ScaleDetector,
        ScrollDetector,
        MouseMovementDetector,
        TapCallbacks {
  final GameState gameState;
  final WeatherService weatherService;
  final void Function()? onSaveRequested;
  final void Function(BuildingModel building)? onBuildingInfoRequested;

  late BuildingSystem buildingSystem;
  late EconomySystem economySystem;
  late TimeSystem timeSystem;
  late WeatherEffectsComponent weatherEffects;

  // Camera control
  double _currentZoom = GameConstants.defaultZoom;
  Vector2 _cameraTarget = Vector2.zero();

  // Mouse position for placement highlight
  Vector2? _lastMousePosition;

  CityGame({
    required this.gameState,
    required this.weatherService,
    this.onSaveRequested,
    this.onBuildingInfoRequested,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Setup camera - use GameConstants for consistent world size
    final worldSize = Vector2(
      GameConstants.gridWidth * GameConstants.cellSize,
      GameConstants.gridHeight * GameConstants.cellSize,
    );

    camera = CameraComponent(
      world: world,
      viewport: MaxViewport(),
    );

    camera.viewfinder.zoom = _currentZoom;
    _cameraTarget = worldSize / 2;
    camera.viewfinder.position = _cameraTarget;

    // Add terrain - use GameConstants for grid dimensions
    world.add(TerrainComponent(
      gridWidth: GameConstants.gridWidth,
      gridHeight: GameConstants.gridHeight,
      cellSize: GameConstants.cellSize,
    ));

    // Initialize systems
    economySystem = EconomySystem(gameState: gameState);
    timeSystem = TimeSystem(
      gameState: gameState,
      onAutoSave: onSaveRequested,
    );
    buildingSystem = BuildingSystem(
      game: this,
      gameState: gameState,
    );

    await buildingSystem.initialize(world);

    // Add people walking around the city
    world.add(PeopleManager(
      cellSize: GameConstants.cellSize,
      gridWidth: gameState.city.width,
      gridHeight: gameState.city.height,
      city: gameState.city,
      maxPeople: 15,
    ));

    // Add weather effects (rendered on top of everything)
    weatherEffects = WeatherEffectsComponent(
      weatherService: weatherService,
      worldWidth: GameConstants.gridWidth * GameConstants.cellSize,
      worldHeight: GameConstants.gridHeight * GameConstants.cellSize,
    );
    world.add(weatherEffects);

    // Note: Camera bounds are managed manually via _clampCameraTarget()
  }

  @override
  void update(double dt) {
    super.update(dt);

    economySystem.update(dt);
    timeSystem.update(dt);
    buildingSystem.update(dt);

    // Smooth camera movement
    final diff = _cameraTarget - camera.viewfinder.position;
    if (diff.length > 0.1) {
      camera.viewfinder.position += diff * 0.1;
    }
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    // Pan the camera
    _cameraTarget -= info.delta.global / _currentZoom;
    _clampCameraTarget();
  }

  @override
  void onScaleUpdate(ScaleUpdateInfo info) {
    // Zoom with pinch gesture
    final scaleDelta = info.scale.global.y;
    if (scaleDelta != 1.0) {
      _currentZoom = (_currentZoom * scaleDelta).clamp(
        GameConstants.minZoom,
        GameConstants.maxZoom,
      );
      camera.viewfinder.zoom = _currentZoom;
    }

    // Also handle pan during scale
    _cameraTarget -= info.delta.global / _currentZoom;
    _clampCameraTarget();
  }

  @override
  void onTapDown(TapDownEvent event) {
    // Convert screen position to world position
    final screenPos = event.localPosition;
    final viewportCenter = size / 2;
    final worldPos = (screenPos - viewportCenter) / _currentZoom + camera.viewfinder.position;

    // Calculate grid position
    final gridX = (worldPos.x / GameConstants.cellSize).floor();
    final gridY = (worldPos.y / GameConstants.cellSize).floor();

    if (gameState.isPlacementMode || gameState.isMoveMode) {
      buildingSystem.updatePlacementHighlight(gridX, gridY);
    }
  }

  /// Handle mouse scroll for zoom
  @override
  void onScroll(PointerScrollInfo info) {
    // Scroll up = zoom in, scroll down = zoom out
    final scrollDelta = info.scrollDelta.global.y;
    if (scrollDelta < 0) {
      // Scroll up - zoom in
      _currentZoom = (_currentZoom * 1.1).clamp(
        GameConstants.minZoom,
        GameConstants.maxZoom,
      );
    } else if (scrollDelta > 0) {
      // Scroll down - zoom out
      _currentZoom = (_currentZoom / 1.1).clamp(
        GameConstants.minZoom,
        GameConstants.maxZoom,
      );
    }
    camera.viewfinder.zoom = _currentZoom;
  }

  /// Handle mouse movement for placement highlight
  @override
  void onMouseMove(PointerHoverInfo info) {
    _lastMousePosition = info.eventPosition.global;

    // Update placement highlight when in placement/move mode
    if (gameState.isPlacementMode || gameState.isMoveMode) {
      // Convert screen position to world position
      final screenPos = info.eventPosition.global;
      final viewportCenter = size / 2;
      final worldPos = (screenPos - viewportCenter) / _currentZoom + camera.viewfinder.position;

      // Calculate grid position
      final gridX = (worldPos.x / GameConstants.cellSize).floor();
      final gridY = (worldPos.y / GameConstants.cellSize).floor();

      // Update highlight position
      if (gridX >= 0 && gridX < gameState.city.width &&
          gridY >= 0 && gridY < gameState.city.height) {
        buildingSystem.updatePlacementHighlight(gridX, gridY);
      }
    }
  }

  void _clampCameraTarget() {
    final worldWidth = GameConstants.gridWidth * GameConstants.cellSize;
    final worldHeight = GameConstants.gridHeight * GameConstants.cellSize;

    // Calculate visible area based on zoom
    final visibleWidth = size.x / _currentZoom;
    final visibleHeight = size.y / _currentZoom;

    // Calculate clamp bounds
    final minX = visibleWidth / 2;
    final maxX = worldWidth - visibleWidth / 2;
    final minY = visibleHeight / 2;
    final maxY = worldHeight - visibleHeight / 2;

    // Only clamp if world is larger than visible area, otherwise center
    if (maxX > minX) {
      _cameraTarget.x = _cameraTarget.x.clamp(minX, maxX);
    } else {
      _cameraTarget.x = worldWidth / 2;
    }

    if (maxY > minY) {
      _cameraTarget.y = _cameraTarget.y.clamp(minY, maxY);
    } else {
      _cameraTarget.y = worldHeight / 2;
    }
  }

  /// Zoom in
  void zoomIn() {
    _currentZoom = (_currentZoom * 1.2).clamp(
      GameConstants.minZoom,
      GameConstants.maxZoom,
    );
    camera.viewfinder.zoom = _currentZoom;
  }

  /// Zoom out
  void zoomOut() {
    _currentZoom = (_currentZoom / 1.2).clamp(
      GameConstants.minZoom,
      GameConstants.maxZoom,
    );
    camera.viewfinder.zoom = _currentZoom;
  }

  /// Reset zoom to default
  void resetZoom() {
    _currentZoom = GameConstants.defaultZoom;
    camera.viewfinder.zoom = _currentZoom;
  }

  /// Center camera on a specific grid position
  void centerOn(int gridX, int gridY) {
    _cameraTarget = Vector2(
      (gridX + 0.5) * GameConstants.cellSize,
      (gridY + 0.5) * GameConstants.cellSize,
    );
    _clampCameraTarget();
  }

  /// Center camera on the world center
  void centerOnWorld() {
    _cameraTarget = Vector2(
      gameState.city.width * GameConstants.cellSize / 2,
      gameState.city.height * GameConstants.cellSize / 2,
    );
  }

  /// Enter placement mode for a building type
  void enterPlacementMode(BuildingType type) {
    buildingSystem.enterPlacementMode(type);
  }

  /// Exit placement mode
  void exitPlacementMode() {
    buildingSystem.exitPlacementMode();
  }

  /// Enter move mode for a building
  void enterMoveMode(String buildingId) {
    buildingSystem.enterMoveMode(buildingId);
  }

  /// Show building info dialog
  void showBuildingInfo(BuildingModel building) {
    onBuildingInfoRequested?.call(building);
  }

  /// Request a save
  void requestSave() {
    onSaveRequested?.call();
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    // Call super first as required by @mustCallSuper
    final superResult = super.onKeyEvent(event, keysPressed);
    if (superResult == KeyEventResult.handled) {
      return superResult;
    }

    if (event is KeyDownEvent) {
      // Zoom with +/- keys
      if (keysPressed.contains(LogicalKeyboardKey.equal) ||
          keysPressed.contains(LogicalKeyboardKey.add)) {
        zoomIn();
        return KeyEventResult.handled;
      }
      if (keysPressed.contains(LogicalKeyboardKey.minus)) {
        zoomOut();
        return KeyEventResult.handled;
      }

      // Reset zoom with 0
      if (keysPressed.contains(LogicalKeyboardKey.digit0)) {
        resetZoom();
        return KeyEventResult.handled;
      }

      // Cancel placement or move mode with Escape
      if (keysPressed.contains(LogicalKeyboardKey.escape)) {
        if (gameState.isPlacementMode) {
          exitPlacementMode();
          return KeyEventResult.handled;
        }
        if (gameState.isMoveMode) {
          buildingSystem.exitMoveMode();
          return KeyEventResult.handled;
        }
      }
    }

    return KeyEventResult.ignored;
  }
}
