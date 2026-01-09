import 'dart:ui';
import '../../utils/constants.dart';

/// Sprite region in the sprite sheet
class SpriteRegion {
  final double x;
  final double y;
  final double width;
  final double height;

  const SpriteRegion({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  Rect toRect() => Rect.fromLTWH(x, y, width, height);
}

/// Sprite configurations for each building type
/// Based on the build.png sprite sheet (3230x3230 pixels)
/// Buildings are arranged in approximately 7 columns
class BuildingSprites {
  BuildingSprites._();

  // Sprite sheet is 3230x3230, buildings arranged in grid
  // Each cell is approximately 460x460 pixels
  static const double cellWidth = 460.0;
  static const double cellHeight = 460.0;

  // Row 1 - Large houses (y: 0-460)
  static const SpriteRegion house1 = SpriteRegion(x: 20, y: 50, width: 400, height: 380);
  static const SpriteRegion house2 = SpriteRegion(x: 480, y: 50, width: 380, height: 380);
  static const SpriteRegion house3 = SpriteRegion(x: 920, y: 30, width: 420, height: 400);
  static const SpriteRegion house4 = SpriteRegion(x: 1380, y: 20, width: 450, height: 420);

  // Row 2 - Medium houses (y: 460-920)
  static const SpriteRegion house5 = SpriteRegion(x: 20, y: 500, width: 350, height: 350);
  static const SpriteRegion house6 = SpriteRegion(x: 400, y: 500, width: 400, height: 370);
  static const SpriteRegion house7 = SpriteRegion(x: 850, y: 520, width: 300, height: 320);
  static const SpriteRegion house8 = SpriteRegion(x: 1200, y: 520, width: 300, height: 320);
  static const SpriteRegion house9 = SpriteRegion(x: 1550, y: 500, width: 340, height: 360);

  // Row 3 - Green roof and shops (y: 920-1380)
  static const SpriteRegion shop1 = SpriteRegion(x: 20, y: 960, width: 380, height: 380);
  static const SpriteRegion shop2 = SpriteRegion(x: 450, y: 980, width: 320, height: 340);
  static const SpriteRegion shop3 = SpriteRegion(x: 820, y: 1000, width: 300, height: 320);
  static const SpriteRegion shop4 = SpriteRegion(x: 1160, y: 1010, width: 280, height: 300);
  static const SpriteRegion shop5 = SpriteRegion(x: 1480, y: 980, width: 340, height: 360);
  static const SpriteRegion shop6 = SpriteRegion(x: 1860, y: 980, width: 340, height: 360);

  // Row 4 - Small buildings (y: 1380-1840)
  static const SpriteRegion small1 = SpriteRegion(x: 20, y: 1450, width: 280, height: 300);
  static const SpriteRegion small2 = SpriteRegion(x: 350, y: 1420, width: 340, height: 360);
  static const SpriteRegion small3 = SpriteRegion(x: 740, y: 1450, width: 320, height: 320);
  static const SpriteRegion small4 = SpriteRegion(x: 1100, y: 1470, width: 280, height: 280);
  static const SpriteRegion small5 = SpriteRegion(x: 1420, y: 1450, width: 320, height: 320);
  static const SpriteRegion castle = SpriteRegion(x: 1780, y: 1380, width: 420, height: 450);

  // Row 5 - Churches (y: 1840-2300)
  static const SpriteRegion church1 = SpriteRegion(x: 20, y: 1900, width: 340, height: 360);
  static const SpriteRegion church2 = SpriteRegion(x: 400, y: 1880, width: 320, height: 380);
  static const SpriteRegion church3 = SpriteRegion(x: 760, y: 1900, width: 280, height: 360);
  static const SpriteRegion tower1 = SpriteRegion(x: 1100, y: 1820, width: 360, height: 460);
  static const SpriteRegion tower2 = SpriteRegion(x: 1500, y: 1800, width: 360, height: 480);

  // Row 6 - More churches and towers (y: 2300-2760)
  static const SpriteRegion church4 = SpriteRegion(x: 20, y: 2360, width: 380, height: 380);
  static const SpriteRegion church5 = SpriteRegion(x: 450, y: 2380, width: 320, height: 360);
  static const SpriteRegion chapel = SpriteRegion(x: 820, y: 2400, width: 280, height: 340);
  static const SpriteRegion bigTower1 = SpriteRegion(x: 1160, y: 2280, width: 400, height: 500);
  static const SpriteRegion bigTower2 = SpriteRegion(x: 1600, y: 2260, width: 400, height: 520);

  /// Get sprite region for a building type
  /// Note: This is deprecated - we now use individual PNG images from spritePath in BuildingConfig
  static SpriteRegion? getSpriteForType(BuildingType type) {
    // Use spritePath from BuildingConfig instead
    return null;
  }

  /// Get multiple sprite options for variety
  /// Note: This is deprecated - we now use individual PNG images from spritePath in BuildingConfig
  static List<SpriteRegion> getSpritesForType(BuildingType type) {
    // Use spritePath from BuildingConfig instead
    return [];
  }
}
