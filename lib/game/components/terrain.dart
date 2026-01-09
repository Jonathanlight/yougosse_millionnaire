import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/constants.dart';

/// Terrain background component that draws a tiled background image and grid
class TerrainComponent extends PositionComponent {
  final int gridWidth;
  final int gridHeight;
  final double cellSize;

  ui.Image? _backgroundImage;
  double _tileSize = 256.0; // Size of each tile

  TerrainComponent({
    required this.gridWidth,
    required this.gridHeight,
    required this.cellSize,
  }) : super(
          size: Vector2(
            gridWidth * cellSize,
            gridHeight * cellSize,
          ),
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Load background image from assets folder (not assets/images)
    try {
      // Use rootBundle to load from assets/ directly
      final byteData = await rootBundle.load('assets/background-map.png');
      final codec = await ui.instantiateImageCodec(byteData.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      _backgroundImage = frame.image;
      // Use the image's natural size for tiling
      _tileSize = _backgroundImage!.width.toDouble();
    } catch (e) {
      // If image fails to load, we'll fall back to solid color
      debugPrint('Failed to load background image: $e');
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (_backgroundImage != null) {
      // Draw tiled background image
      final paint = Paint();
      final imgWidth = _backgroundImage!.width.toDouble();
      final imgHeight = _backgroundImage!.height.toDouble();

      // Calculate how many tiles we need
      final tilesX = (size.x / imgWidth).ceil() + 1;
      final tilesY = (size.y / imgHeight).ceil() + 1;

      // Draw tiles
      for (int tx = 0; tx < tilesX; tx++) {
        for (int ty = 0; ty < tilesY; ty++) {
          final destRect = Rect.fromLTWH(
            tx * imgWidth,
            ty * imgHeight,
            imgWidth,
            imgHeight,
          );

          canvas.drawImageRect(
            _backgroundImage!,
            Rect.fromLTWH(0, 0, imgWidth, imgHeight),
            destRect,
            paint,
          );
        }
      }
    } else {
      // Fallback: Draw grass background color
      final grassPaint = Paint()..color = AppColors.terrainGrass;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        grassPaint,
      );
    }

    // Draw grid lines
    final gridPaint = Paint()
      ..color = AppColors.gridLine
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Vertical lines
    for (int x = 0; x <= gridWidth; x++) {
      canvas.drawLine(
        Offset(x * cellSize, 0),
        Offset(x * cellSize, size.y),
        gridPaint,
      );
    }

    // Horizontal lines
    for (int y = 0; y <= gridHeight; y++) {
      canvas.drawLine(
        Offset(0, y * cellSize),
        Offset(size.x, y * cellSize),
        gridPaint,
      );
    }
  }
}
