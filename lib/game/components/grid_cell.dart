import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../city_game.dart';

/// Represents a single cell in the grid for placement highlighting
class GridCellHighlight extends PositionComponent with HasGameReference<CityGame> {
  final int gridX;
  final int gridY;
  final int gridWidth;
  final int gridHeight;
  final double cellSize;
  bool isValid;

  GridCellHighlight({
    required this.gridX,
    required this.gridY,
    required this.gridWidth,
    required this.gridHeight,
    required this.cellSize,
    this.isValid = true,
  }) : super(
          position: Vector2(gridX * cellSize, gridY * cellSize),
          size: Vector2(gridWidth * cellSize, gridHeight * cellSize),
        );

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final color =
        isValid ? AppColors.validPlacement : AppColors.invalidPlacement;

    final paint = Paint()..color = color;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      paint,
    );

    // Draw border
    final borderPaint = Paint()
      ..color = isValid ? Colors.green : Colors.red
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      borderPaint,
    );
  }

  void updatePosition(int newGridX, int newGridY, bool newIsValid) {
    position = Vector2(newGridX * cellSize, newGridY * cellSize);
    isValid = newIsValid;
  }
}

/// Invisible tap detector for grid cells
class GridTapDetector extends PositionComponent
    with TapCallbacks, HasGameReference<CityGame> {
  final int gridWidth;
  final int gridHeight;
  final double cellSize;
  final void Function(int x, int y) onCellTapped;
  final void Function(int x, int y)? onCellHover;

  GridTapDetector({
    required this.gridWidth,
    required this.gridHeight,
    required this.cellSize,
    required this.onCellTapped,
    this.onCellHover,
  }) : super(
          size: Vector2(
            gridWidth * cellSize,
            gridHeight * cellSize,
          ),
        );

  @override
  bool onTapDown(TapDownEvent event) {
    final localPos = event.localPosition;
    final gridX = (localPos.x / cellSize).floor();
    final gridY = (localPos.y / cellSize).floor();

    if (gridX >= 0 && gridX < gridWidth && gridY >= 0 && gridY < gridHeight) {
      onCellTapped(gridX, gridY);
    }

    return true;
  }

  /// Convert world position to grid position
  (int, int)? worldToGrid(Vector2 worldPos) {
    final localPos = worldPos - position;
    final gridX = (localPos.x / cellSize).floor();
    final gridY = (localPos.y / cellSize).floor();

    if (gridX >= 0 && gridX < gridWidth && gridY >= 0 && gridY < gridHeight) {
      return (gridX, gridY);
    }
    return null;
  }
}
