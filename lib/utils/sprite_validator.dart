import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'constants.dart';

/// Utility class to validate sprite dimensions against expected building sizes
class SpriteValidator {
  SpriteValidator._();

  /// Tolerance in pixels for sprite dimension validation
  static const int tolerance = 5;

  /// Validation result for a single sprite
  static final List<SpriteValidationResult> _validationResults = [];

  /// Get all validation results
  static List<SpriteValidationResult> get validationResults =>
      List.unmodifiable(_validationResults);

  /// Validate all building sprites at app startup
  static Future<void> validateAllSprites() async {
    _validationResults.clear();

    for (final config in BuildingConfigs.configs.values) {
      if (config.spritePath == null) continue;

      try {
        final result = await _validateSprite(config);
        _validationResults.add(result);

        if (!result.isValid) {
          print('WARNING: Sprite validation failed for ${config.name}:');
          print('  Path: ${config.spritePath}');
          print('  Expected: ${config.spritePixelWidth}x${config.spritePixelHeight}');
          print('  Actual: ${result.actualWidth}x${result.actualHeight}');
        }
      } catch (e) {
        _validationResults.add(SpriteValidationResult(
          buildingType: config.type,
          spritePath: config.spritePath!,
          expectedWidth: config.spritePixelWidth,
          expectedHeight: config.spritePixelHeight,
          actualWidth: 0,
          actualHeight: 0,
          error: e.toString(),
        ));
        print('ERROR: Failed to load sprite for ${config.name}: $e');
      }
    }

    // Print summary
    final validCount = _validationResults.where((r) => r.isValid).length;
    final invalidCount = _validationResults.where((r) => !r.isValid && r.error == null).length;
    final errorCount = _validationResults.where((r) => r.error != null).length;

    print('Sprite Validation Summary:');
    print('  Valid: $validCount');
    print('  Invalid dimensions: $invalidCount');
    print('  Load errors: $errorCount');
  }

  /// Validate a single sprite
  static Future<SpriteValidationResult> _validateSprite(
      BuildingConfig config) async {
    final data = await rootBundle.load(config.spritePath!);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    final image = frame.image;

    return SpriteValidationResult(
      buildingType: config.type,
      spritePath: config.spritePath!,
      expectedWidth: config.spritePixelWidth,
      expectedHeight: config.spritePixelHeight,
      actualWidth: image.width,
      actualHeight: image.height,
    );
  }

  /// Check if a specific building type has valid sprite dimensions
  static bool isSpriteValid(BuildingType type) {
    final result = _validationResults.firstWhere(
      (r) => r.buildingType == type,
      orElse: () => SpriteValidationResult(
        buildingType: type,
        spritePath: '',
        expectedWidth: 0,
        expectedHeight: 0,
        actualWidth: 0,
        actualHeight: 0,
        error: 'Not validated',
      ),
    );
    return result.isValid;
  }

  /// Get validation result for a specific building type
  static SpriteValidationResult? getValidationResult(BuildingType type) {
    try {
      return _validationResults.firstWhere((r) => r.buildingType == type);
    } catch (_) {
      return null;
    }
  }

  /// Get all invalid sprites
  static List<SpriteValidationResult> getInvalidSprites() {
    return _validationResults.where((r) => !r.isValid).toList();
  }
}

/// Result of sprite validation
class SpriteValidationResult {
  final BuildingType buildingType;
  final String spritePath;
  final int expectedWidth;
  final int expectedHeight;
  final int actualWidth;
  final int actualHeight;
  final String? error;

  const SpriteValidationResult({
    required this.buildingType,
    required this.spritePath,
    required this.expectedWidth,
    required this.expectedHeight,
    required this.actualWidth,
    required this.actualHeight,
    this.error,
  });

  /// Check if dimensions are within tolerance
  bool get isValid {
    if (error != null) return false;

    final widthDiff = (actualWidth - expectedWidth).abs();
    final heightDiff = (actualHeight - expectedHeight).abs();

    return widthDiff <= SpriteValidator.tolerance &&
        heightDiff <= SpriteValidator.tolerance;
  }

  /// Get width difference
  int get widthDiff => actualWidth - expectedWidth;

  /// Get height difference
  int get heightDiff => actualHeight - expectedHeight;

  @override
  String toString() {
    if (error != null) {
      return 'SpriteValidationResult($buildingType: ERROR - $error)';
    }
    return 'SpriteValidationResult($buildingType: ${isValid ? "VALID" : "INVALID"} - '
        'expected ${expectedWidth}x$expectedHeight, '
        'actual ${actualWidth}x$actualHeight)';
  }
}
