import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/city_model.dart';
import '../../utils/constants.dart';

/// A simple person that walks around the city avoiding buildings
class PersonComponent extends PositionComponent {
  final double cellSize;
  final int gridWidth;
  final int gridHeight;
  final CityModel city;

  Vector2 _targetPosition = Vector2.zero();
  double _speed = 30.0;
  double _walkCycle = 0;
  Color _shirtColor;
  Color _pantsColor;
  bool _facingRight = true;
  double _stuckTimer = 0;

  static final _random = math.Random();

  PersonComponent({
    required this.cellSize,
    required this.gridWidth,
    required this.gridHeight,
    required this.city,
    required Vector2 startPosition,
  }) : _shirtColor = _randomColor(),
       _pantsColor = _randomColor(),
       super(
         position: startPosition,
         size: Vector2(12, 20),
         anchor: Anchor.center,
       ) {
    _targetPosition = startPosition.clone();
    _speed = 20 + _random.nextDouble() * 30;
  }

  static Color _randomColor() {
    final colors = [
      Colors.red.shade400,
      Colors.blue.shade400,
      Colors.green.shade400,
      Colors.purple.shade400,
      Colors.orange.shade400,
      Colors.pink.shade400,
      Colors.teal.shade400,
      Colors.indigo.shade400,
      Colors.amber.shade400,
    ];
    return colors[_random.nextInt(colors.length)];
  }

  /// Check if a grid position is occupied by a building
  bool _isCellOccupied(int gridX, int gridY) {
    return city.getBuildingAt(gridX, gridY) != null;
  }

  /// Convert world position to grid coordinates
  (int, int) _worldToGrid(Vector2 worldPos) {
    return (
      (worldPos.x / cellSize).floor(),
      (worldPos.y / cellSize).floor(),
    );
  }

  /// Check if a world position collides with a building
  bool _collidesWithBuilding(Vector2 worldPos) {
    final (gridX, gridY) = _worldToGrid(worldPos);

    // Check the cell and adjacent cells for safety
    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        final checkX = gridX + dx;
        final checkY = gridY + dy;
        if (checkX >= 0 && checkX < gridWidth && checkY >= 0 && checkY < gridHeight) {
          final building = city.getBuildingAt(checkX, checkY);
          if (building != null) {
            // Check if the person's position overlaps with the building bounds
            final buildingLeft = building.gridX * cellSize;
            final buildingTop = building.gridY * cellSize;
            final buildingRight = (building.gridX + building.config.width) * cellSize;
            final buildingBottom = (building.gridY + building.config.height) * cellSize;

            // Add some margin for the person
            final margin = 5.0;
            if (worldPos.x > buildingLeft - margin &&
                worldPos.x < buildingRight + margin &&
                worldPos.y > buildingTop - margin &&
                worldPos.y < buildingBottom + margin) {
              return true;
            }
          }
        }
      }
    }
    return false;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Update walk cycle for animation
    _walkCycle += dt * 8;

    // Check if we need a new target
    final distanceToTarget = position.distanceTo(_targetPosition);
    if (distanceToTarget < 5) {
      _chooseNewTarget();
      _stuckTimer = 0;
    }

    // Calculate next position
    final direction = (_targetPosition - position);
    if (direction.length > 0) {
      direction.normalize();
    }
    final nextPosition = position + direction * _speed * dt;

    // Check for collision with building
    if (!_collidesWithBuilding(nextPosition)) {
      position.setFrom(nextPosition);
      _stuckTimer = 0;
    } else {
      // If stuck, try to find a new path
      _stuckTimer += dt;
      if (_stuckTimer > 0.5) {
        _chooseNewTarget();
        _stuckTimer = 0;
      } else {
        // Try to move around the obstacle
        _tryAlternativeMove(dt);
      }
    }

    // Update facing direction
    _facingRight = direction.x >= 0;

    // Keep within bounds
    position.x = position.x.clamp(cellSize, (gridWidth - 1) * cellSize);
    position.y = position.y.clamp(cellSize, (gridHeight - 1) * cellSize);
  }

  void _tryAlternativeMove(double dt) {
    // Try moving perpendicular to the target direction
    final direction = (_targetPosition - position);
    if (direction.length > 0) {
      direction.normalize();
    }

    // Try left perpendicular
    final leftPerp = Vector2(-direction.y, direction.x);
    final leftPos = position + leftPerp * _speed * dt;
    if (!_collidesWithBuilding(leftPos)) {
      position.setFrom(leftPos);
      return;
    }

    // Try right perpendicular
    final rightPerp = Vector2(direction.y, -direction.x);
    final rightPos = position + rightPerp * _speed * dt;
    if (!_collidesWithBuilding(rightPos)) {
      position.setFrom(rightPos);
      return;
    }
  }

  void _chooseNewTarget() {
    // Try to find a valid target position that doesn't collide with buildings
    for (int attempts = 0; attempts < 20; attempts++) {
      final targetX = cellSize + _random.nextDouble() * (gridWidth - 2) * cellSize;
      final targetY = cellSize + _random.nextDouble() * (gridHeight - 2) * cellSize;
      final potentialTarget = Vector2(targetX, targetY);

      if (!_collidesWithBuilding(potentialTarget)) {
        _targetPosition = potentialTarget;
        return;
      }
    }

    // If we couldn't find a valid position, just stay in place
    _targetPosition = position.clone();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final bounce = math.sin(_walkCycle) * 1.5;

    canvas.save();

    // Flip horizontally if facing left
    if (!_facingRight) {
      canvas.translate(size.x, 0);
      canvas.scale(-1, 1);
    }

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(50);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x / 2, size.y - 2),
        width: 10,
        height: 4,
      ),
      shadowPaint,
    );

    // Legs (animated)
    final legPaint = Paint()..color = _pantsColor;
    final legOffset = math.sin(_walkCycle) * 3;

    // Left leg
    canvas.drawRect(
      Rect.fromLTWH(
        size.x / 2 - 4,
        size.y - 10 + bounce + legOffset,
        3,
        8,
      ),
      legPaint,
    );

    // Right leg
    canvas.drawRect(
      Rect.fromLTWH(
        size.x / 2 + 1,
        size.y - 10 + bounce - legOffset,
        3,
        8,
      ),
      legPaint,
    );

    // Body
    final bodyPaint = Paint()..color = _shirtColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.x / 2 - 5,
          size.y - 16 + bounce,
          10,
          10,
        ),
        const Radius.circular(2),
      ),
      bodyPaint,
    );

    // Head
    final headPaint = Paint()..color = const Color(0xFFFFDDB4);
    canvas.drawCircle(
      Offset(size.x / 2, size.y - 18 + bounce),
      5,
      headPaint,
    );

    // Hair
    final hairPaint = Paint()..color = Colors.brown.shade800;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.x / 2, size.y - 19 + bounce),
        width: 10,
        height: 8,
      ),
      math.pi,
      math.pi,
      true,
      hairPaint,
    );

    canvas.restore();
  }
}

/// Manager for spawning and managing people in the city
class PeopleManager extends Component {
  final double cellSize;
  final int gridWidth;
  final int gridHeight;
  final int maxPeople;
  final CityModel city;

  final List<PersonComponent> _people = [];
  static final _random = math.Random();

  PeopleManager({
    required this.cellSize,
    required this.gridWidth,
    required this.gridHeight,
    required this.city,
    this.maxPeople = 10,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Spawn initial people
    for (int i = 0; i < maxPeople; i++) {
      _spawnPerson();
    }
  }

  void _spawnPerson() {
    // Try to find a valid spawn position
    for (int attempts = 0; attempts < 50; attempts++) {
      final x = cellSize + _random.nextDouble() * (gridWidth - 2) * cellSize;
      final y = cellSize + _random.nextDouble() * (gridHeight - 2) * cellSize;

      // Check if this position is not inside a building
      final gridX = (x / cellSize).floor();
      final gridY = (y / cellSize).floor();

      if (city.getBuildingAt(gridX, gridY) == null) {
        final person = PersonComponent(
          cellSize: cellSize,
          gridWidth: gridWidth,
          gridHeight: gridHeight,
          city: city,
          startPosition: Vector2(x, y),
        );

        _people.add(person);
        parent?.add(person);
        return;
      }
    }
  }
}
