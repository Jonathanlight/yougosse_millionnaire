import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/building_model.dart';
import '../../services/audio_service.dart';
import '../../utils/constants.dart';
import '../city_game.dart';
import '../data/sprite_data.dart';

/// Visual component for a building in the game
class BuildingComponent extends PositionComponent
    with TapCallbacks, DragCallbacks, HasGameReference<CityGame> {
  final BuildingModel model;
  final double cellSize;

  bool _showMoneyIcon = false;
  double _moneyIconPulse = 0;
  double _constructionPulse = 0;
  double _timerAngle = 0;

  // Long-press and drag state
  bool _isDragging = false;
  bool _isLongPressing = false;
  bool _longPressActivated = false;
  double _longPressTimer = 0;
  double _longPressHaloPulse = 0;
  Vector2? _dragStartPosition;
  int _originalGridX = 0;
  int _originalGridY = 0;
  bool _isValidPlacement = true;

  static const double longPressDuration = 0.8; // 800ms

  // Static cache for building images
  static final Map<String, ui.Image> _imageCache = {};
  static bool _imagesLoading = false;
  ui.Image? _buildingImage;

  static bool _imagesLoaded = false;

  /// Check if images are loaded
  static bool get imagesLoaded => _imagesLoaded;

  /// Get all sprite paths from building configs
  static List<String> _getAllSpritePaths() {
    return BuildingConfigs.configs.values
        .where((config) => config.spritePath != null)
        .map((config) => config.spritePath!)
        .toList();
  }

  BuildingComponent({
    required this.model,
    required this.cellSize,
  }) : super(
          position: Vector2(
            model.gridX * cellSize,
            model.gridY * cellSize,
          ),
          size: Vector2(
            model.config.width * cellSize,
            model.config.height * cellSize,
          ),
          // Priority based on Y position for proper z-ordering (back to front)
          priority: model.gridY + model.gridX,
        );

  BuildingConfig get config => model.config;

  /// Load all building images
  static Future<void> loadBuildingImages() async {
    if (_imagesLoaded || _imagesLoading) return;
    _imagesLoading = true;

    try {
      // Load all building images from configs
      final spritePaths = _getAllSpritePaths();
      for (final path in spritePaths) {
        if (!_imageCache.containsKey(path)) {
          try {
            final data = await rootBundle.load(path);
            final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
            final frame = await codec.getNextFrame();
            _imageCache[path] = frame.image;
            print('Loaded building image: $path');
          } catch (e) {
            print('Failed to load image $path: $e');
          }
        }
      }
      _imagesLoaded = true;
      print('Building images loaded: ${_imageCache.length} images');
    } catch (e) {
      print('Failed to load building images: $e');
    }
    _imagesLoading = false;
  }

  /// Get image for this building type from config
  String? _getImagePath() {
    return config.spritePath;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Load building images if needed
    if (!_imagesLoaded) {
      await loadBuildingImages();
    }

    // Get the image for this building type
    final imagePath = _getImagePath();
    print('Building ${model.type.name} - imagePath: $imagePath, cacheKeys: ${_imageCache.keys.toList()}');

    if (imagePath != null) {
      if (_imageCache.containsKey(imagePath)) {
        _buildingImage = _imageCache[imagePath];
        print('Image assigned for ${model.type.name}: ${_buildingImage != null}');
      } else {
        print('Image NOT in cache: $imagePath');
      }
    }

    // Add spawn animation
    scale = Vector2.zero();
    add(
      ScaleEffect.to(
        Vector2.all(1),
        EffectController(duration: 0.3, curve: Curves.elasticOut),
      ),
    );
  }

  /// Update the position when the building is moved
  void updatePosition(int newGridX, int newGridY) {
    position = Vector2(
      newGridX * cellSize,
      newGridY * cellSize,
    );
    // Update priority for proper z-ordering
    priority = newGridY + newGridX;
  }

  // Track if construction was in progress
  bool? _wasUnderConstruction;

  @override
  void update(double dt) {
    super.update(dt);

    // Initialize tracking on first update
    _wasUnderConstruction ??= model.isUnderConstruction;

    // Check if construction just finished
    if (_wasUnderConstruction == true && !model.isUnderConstruction) {
      // Construction just completed - reset lastCollectedAt to now
      // so the timer starts from 0
      model.lastCollectedAt = DateTime.now();
      _wasUnderConstruction = false;
    } else if (!model.isUnderConstruction) {
      _wasUnderConstruction = false;
    }

    // Update money icon pulse
    if (model.hasRevenueToCollect && !model.isUnderConstruction) {
      _showMoneyIcon = true;
      _moneyIconPulse += dt * 3;
    } else {
      _showMoneyIcon = false;
      // Keep pulsing for the timer effect even when no revenue to collect
      _moneyIconPulse += dt * 2;
    }

    // Update construction pulse
    if (model.isUnderConstruction) {
      _constructionPulse += dt * 2;
    }

    // Update timer animation
    _timerAngle += dt * 2;

    // Update long press timer
    if (_isLongPressing && !_longPressActivated) {
      _longPressTimer += dt;
      _longPressHaloPulse += dt * 6; // Fast pulse during long press

      if (_longPressTimer >= longPressDuration) {
        // Long press completed - activate move mode
        _longPressActivated = true;
        _activateMoveMode();
      }
    }

    // Update halo pulse when dragging
    if (_isDragging) {
      _longPressHaloPulse += dt * 4;
    }
  }

  void _activateMoveMode() {
    _isDragging = true;
    _dragStartPosition = position.clone();
    _originalGridX = model.gridX;
    _originalGridY = model.gridY;

    // Bring to front while dragging
    priority = 10000;

    // Haptic feedback
    HapticFeedback.mediumImpact();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw long press halo indicator
    if (_isLongPressing && !_longPressActivated) {
      _renderLongPressHalo(canvas);
    }

    // Draw validity indicator while dragging
    if (_isDragging) {
      _renderMoveIndicator(canvas);
    }

    if (model.isUnderConstruction) {
      _renderConstruction(canvas);
    } else {
      _renderBuilding(canvas);
      // Render timer for revenue collection
      if (config.hasRevenue) {
        _renderTimer(canvas);
      }
    }

    if (_showMoneyIcon) {
      _renderMoneyIcon(canvas);
    }
  }

  void _renderLongPressHalo(Canvas canvas) {
    // Calculate progress (0.0 to 1.0)
    final progress = (_longPressTimer / longPressDuration).clamp(0.0, 1.0);

    // Pulsing halo effect
    final pulseAlpha = 0.3 + 0.3 * math.sin(_longPressHaloPulse);
    final haloColor = AppColors.movePulseHalo.withValues(alpha: pulseAlpha);

    // Draw expanding halo
    final haloExpand = 10 + progress * 15;
    final haloPaint = Paint()
      ..color = haloColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 + progress * 4;

    canvas.drawRect(
      Rect.fromLTWH(-haloExpand, -haloExpand, size.x + haloExpand * 2, size.y + haloExpand * 2),
      haloPaint,
    );

    // Draw progress arc at the corner
    final progressArcPaint = Paint()
      ..color = Colors.cyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final arcRect = Rect.fromCenter(
      center: Offset(size.x / 2, -15),
      width: 24,
      height: 24,
    );

    // Background track
    final trackPaint = Paint()
      ..color = Colors.grey.shade800
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawArc(arcRect, 0, 2 * math.pi, false, trackPaint);

    // Progress arc
    canvas.drawArc(arcRect, -math.pi / 2, progress * 2 * math.pi, false, progressArcPaint);

    // "Hold" text
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Maintenir...',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(size.x / 2 - textPainter.width / 2, -40),
    );
  }

  void _renderMoveIndicator(Canvas canvas) {
    // Calculate current grid position
    final centerX = position.x + size.x / 2;
    final centerY = position.y + size.y / 2;
    final newGridX = (centerX / cellSize).floor() - (config.width ~/ 2);
    final newGridY = (centerY / cellSize).floor() - (config.height ~/ 2);

    // Check if position is valid
    final canMove = game.gameState.city.canMoveBuilding(model.id, newGridX, newGridY);
    _isValidPlacement = canMove;

    // Animated pulse for visual feedback
    final pulseAlpha = 0.2 + 0.15 * math.sin(_longPressHaloPulse);

    // Draw semi-transparent overlay
    final bgColor = canMove
        ? AppColors.moveValidBg.withValues(alpha: pulseAlpha + 0.2)
        : AppColors.moveInvalidBg.withValues(alpha: pulseAlpha + 0.2);
    final borderColor = canMove ? AppColors.moveValidBorder : AppColors.moveInvalidBorder;

    final paint = Paint()..color = bgColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), paint);

    // Draw animated border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), borderPaint);
  }

  void _renderBuilding(Canvas canvas) {
    final rect = Rect.fromLTWH(4, 4, size.x - 8, size.y - 8);

    // Try to get image from cache if not already assigned
    if (_buildingImage == null && _imagesLoaded) {
      final imagePath = _getImagePath();
      if (imagePath != null && _imageCache.containsKey(imagePath)) {
        _buildingImage = _imageCache[imagePath];
      }
    }

    // Try to render image if available
    if (_buildingImage != null) {
      _renderImage(canvas, rect);
      return;
    }

    // Fallback to programmatic rendering based on category
    switch (config.category) {
      case BuildingCategory.residential:
        _renderHouse(canvas, rect);
      case BuildingCategory.commercial:
        _renderShop(canvas, rect);
      case BuildingCategory.industrial:
        _renderFactory(canvas, rect);
      case BuildingCategory.decoration:
        _renderPark(canvas, rect);
      case BuildingCategory.monument:
        _renderTownHall(canvas, rect);
      case BuildingCategory.infrastructure:
        _renderRoad(canvas, rect);
    }
  }

  void _renderImage(Canvas canvas, Rect destRect) {
    if (_buildingImage == null) return;

    final img = _buildingImage!;
    final srcRect = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());

    // Calculate aspect ratios
    final srcAspect = srcRect.width / srcRect.height;

    // Fit the image to the cell while maintaining aspect ratio
    // Align to bottom center (buildings sit on the ground)
    double scaledWidth, scaledHeight;

    if (srcAspect > 1) {
      // Image is wider than tall - fit to width
      scaledWidth = destRect.width;
      scaledHeight = scaledWidth / srcAspect;
    } else {
      // Image is taller than wide - fit to height
      scaledHeight = destRect.height;
      scaledWidth = scaledHeight * srcAspect;
    }

    // Position: center horizontally, align bottom
    final adjustedDestRect = Rect.fromLTWH(
      destRect.left + (destRect.width - scaledWidth) / 2,
      destRect.bottom - scaledHeight,
      scaledWidth,
      scaledHeight,
    );

    canvas.drawImageRect(
      img,
      srcRect,
      adjustedDestRect,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  void _renderTimer(Canvas canvas) {
    if (model.isUnderConstruction) return;
    if (!config.hasRevenue) return;

    // Use cycle-based progress
    final progress = model.cycleProgress;
    final timeRemaining = model.timeUntilNextRevenue;

    if (model.isCycleComplete) return; // Already ready to collect

    // Draw circular timer - MAXIMUM SIZE for visibility
    final centerX = size.x / 2;
    final centerY = -25.0; // Above the building
    final radius = 30.0; // VERY LARGE

    // Outer glow effect - strong pulsing
    final pulse = (math.sin(_moneyIconPulse * 2) + 1) / 2;
    final glowPaint = Paint()
      ..color = Colors.cyan.withValues(alpha: 0.5 + pulse * 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset(centerX, centerY), radius + 8, glowPaint);

    // Second glow layer
    final glow2Paint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(centerX, centerY), radius + 4, glow2Paint);

    // Background circle
    final bgPaint = Paint()
      ..color = const Color(0xFF0d1117)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, centerY), radius, bgPaint);

    // Outer ring - thicker
    final outerRingPaint = Paint()
      ..color = Colors.cyan.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(Offset(centerX, centerY), radius, outerRingPaint);

    // Background track - thicker
    final trackPaint = Paint()
      ..color = Colors.grey.shade800
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(Offset(centerX, centerY), radius - 8, trackPaint);

    // Progress arc with gradient color - thicker
    final progressColor = Color.lerp(
      Colors.cyan,
      Colors.green,
      progress,
    )!;
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: radius - 8),
      -math.pi / 2,
      progress * 2 * math.pi,
      false,
      progressPaint,
    );

    // Format remaining time
    final totalSeconds = timeRemaining.inSeconds;
    String timeText;
    String unitLabel;

    if (totalSeconds >= 3600) {
      // Show hours and minutes
      final hours = totalSeconds ~/ 3600;
      final minutes = (totalSeconds % 3600) ~/ 60;
      timeText = '$hours:${minutes.toString().padLeft(2, '0')}';
      unitLabel = 'h:m';
    } else if (totalSeconds >= 60) {
      // Show minutes and seconds
      final minutes = totalSeconds ~/ 60;
      final seconds = totalSeconds % 60;
      timeText = '$minutes:${seconds.toString().padLeft(2, '0')}';
      unitLabel = 'm:s';
    } else {
      // Show seconds only
      timeText = '$totalSeconds';
      unitLabel = 'sec';
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: timeText,
        style: TextStyle(
          color: Colors.white,
          fontSize: totalSeconds >= 3600 ? 14 : 18,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: progressColor,
              blurRadius: 8,
            ),
            const Shadow(
              color: Colors.black,
              blurRadius: 2,
              offset: Offset(1, 1),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(centerX - textPainter.width / 2, centerY - textPainter.height / 2),
    );

    // Unit label below
    final labelPainter = TextPainter(
      text: TextSpan(
        text: unitLabel,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 8,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    labelPainter.layout();
    labelPainter.paint(
      canvas,
      Offset(centerX - labelPainter.width / 2, centerY + 8),
    );
  }

  void _renderHouse(Canvas canvas, Rect rect) {
    // Main body
    final bodyPaint = Paint()..color = config.color;
    canvas.drawRect(
      Rect.fromLTWH(rect.left, rect.top + rect.height * 0.3, rect.width,
          rect.height * 0.7),
      bodyPaint,
    );

    // Roof (triangle)
    final roofPaint = Paint()..color = config.roofColor;
    final roofPath = Path()
      ..moveTo(rect.left, rect.top + rect.height * 0.3)
      ..lineTo(rect.left + rect.width / 2, rect.top)
      ..lineTo(rect.right, rect.top + rect.height * 0.3)
      ..close();
    canvas.drawPath(roofPath, roofPaint);

    // Door
    final doorPaint = Paint()..color = Colors.brown.shade800;
    canvas.drawRect(
      Rect.fromLTWH(
        rect.left + rect.width * 0.4,
        rect.top + rect.height * 0.6,
        rect.width * 0.2,
        rect.height * 0.4,
      ),
      doorPaint,
    );

    // Window
    final windowPaint = Paint()..color = Colors.yellow.shade200;
    canvas.drawRect(
      Rect.fromLTWH(
        rect.left + rect.width * 0.15,
        rect.top + rect.height * 0.4,
        rect.width * 0.2,
        rect.height * 0.15,
      ),
      windowPaint,
    );
  }

  void _renderApartment(Canvas canvas, Rect rect) {
    // Main body
    final bodyPaint = Paint()..color = config.color;
    canvas.drawRect(rect, bodyPaint);

    // Windows grid
    final windowPaint = Paint()..color = Colors.lightBlue.shade100;
    const windowRows = 4;
    const windowCols = 3;
    final windowWidth = rect.width / (windowCols * 2);
    final windowHeight = rect.height / (windowRows * 2);

    for (int row = 0; row < windowRows; row++) {
      for (int col = 0; col < windowCols; col++) {
        canvas.drawRect(
          Rect.fromLTWH(
            rect.left + (col * 2 + 0.5) * windowWidth,
            rect.top + (row * 2 + 0.5) * windowHeight,
            windowWidth * 0.8,
            windowHeight * 0.8,
          ),
          windowPaint,
        );
      }
    }

    // Roof
    final roofPaint = Paint()..color = config.roofColor;
    canvas.drawRect(
      Rect.fromLTWH(rect.left - 2, rect.top - 4, rect.width + 4, 6),
      roofPaint,
    );
  }

  void _renderShop(Canvas canvas, Rect rect) {
    // Main body
    final bodyPaint = Paint()..color = config.color;
    canvas.drawRect(rect, bodyPaint);

    // Awning
    final awningPaint = Paint()..color = Colors.red.shade700;
    canvas.drawRect(
      Rect.fromLTWH(
        rect.left - 4,
        rect.top,
        rect.width + 8,
        rect.height * 0.25,
      ),
      awningPaint,
    );

    // Store front window
    final windowPaint = Paint()..color = Colors.lightBlue.shade50;
    canvas.drawRect(
      Rect.fromLTWH(
        rect.left + rect.width * 0.1,
        rect.top + rect.height * 0.3,
        rect.width * 0.8,
        rect.height * 0.5,
      ),
      windowPaint,
    );

    // Door
    final doorPaint = Paint()..color = Colors.brown;
    canvas.drawRect(
      Rect.fromLTWH(
        rect.left + rect.width * 0.35,
        rect.top + rect.height * 0.5,
        rect.width * 0.3,
        rect.height * 0.5,
      ),
      doorPaint,
    );
  }

  void _renderFactory(Canvas canvas, Rect rect) {
    // Main body
    final bodyPaint = Paint()..color = config.color;
    canvas.drawRect(rect, bodyPaint);

    // Chimney
    final chimneyPaint = Paint()..color = Colors.grey.shade700;
    canvas.drawRect(
      Rect.fromLTWH(
        rect.right - rect.width * 0.25,
        rect.top - rect.height * 0.3,
        rect.width * 0.15,
        rect.height * 0.4,
      ),
      chimneyPaint,
    );

    // Smoke (animated circles)
    final smokePaint = Paint()..color = Colors.grey.shade400.withValues(alpha: 0.6);
    final smokeOffset = math.sin(_constructionPulse) * 2;
    canvas.drawCircle(
      Offset(rect.right - rect.width * 0.175, rect.top - rect.height * 0.35 - smokeOffset),
      6,
      smokePaint,
    );

    // Windows
    final windowPaint = Paint()..color = Colors.yellow.shade600;
    for (int i = 0; i < 3; i++) {
      canvas.drawRect(
        Rect.fromLTWH(
          rect.left + rect.width * 0.1 + i * rect.width * 0.3,
          rect.top + rect.height * 0.4,
          rect.width * 0.2,
          rect.height * 0.3,
        ),
        windowPaint,
      );
    }
  }

  void _renderPark(Canvas canvas, Rect rect) {
    // Grass base
    final grassPaint = Paint()..color = config.color;
    canvas.drawOval(rect, grassPaint);

    // Trees (simple circles)
    final treePaint = Paint()..color = Colors.green.shade800;
    final treeRadius = rect.width * 0.15;

    canvas.drawCircle(
      Offset(rect.center.dx - rect.width * 0.2, rect.center.dy - rect.height * 0.1),
      treeRadius,
      treePaint,
    );
    canvas.drawCircle(
      Offset(rect.center.dx + rect.width * 0.15, rect.center.dy),
      treeRadius * 0.8,
      treePaint,
    );
    canvas.drawCircle(
      Offset(rect.center.dx, rect.center.dy + rect.height * 0.15),
      treeRadius * 0.9,
      treePaint,
    );

    // Trunk hints
    final trunkPaint = Paint()..color = Colors.brown.shade600;
    canvas.drawRect(
      Rect.fromLTWH(
        rect.center.dx - rect.width * 0.22,
        rect.center.dy,
        4,
        8,
      ),
      trunkPaint,
    );
  }

  void _renderTownHall(Canvas canvas, Rect rect) {
    // Base
    final basePaint = Paint()..color = config.color;
    canvas.drawRect(rect, basePaint);

    // Columns
    final columnPaint = Paint()..color = Colors.white;
    const numColumns = 4;
    final columnWidth = rect.width / (numColumns * 2 + 1);

    for (int i = 0; i < numColumns; i++) {
      canvas.drawRect(
        Rect.fromLTWH(
          rect.left + columnWidth * (i * 2 + 1),
          rect.top + rect.height * 0.2,
          columnWidth,
          rect.height * 0.7,
        ),
        columnPaint,
      );
    }

    // Roof/Pediment
    final roofPaint = Paint()..color = config.roofColor;
    final pedimentPath = Path()
      ..moveTo(rect.left, rect.top + rect.height * 0.2)
      ..lineTo(rect.center.dx, rect.top)
      ..lineTo(rect.right, rect.top + rect.height * 0.2)
      ..close();
    canvas.drawPath(pedimentPath, roofPaint);

    // Door
    final doorPaint = Paint()..color = Colors.brown.shade800;
    canvas.drawRect(
      Rect.fromLTWH(
        rect.center.dx - rect.width * 0.1,
        rect.top + rect.height * 0.6,
        rect.width * 0.2,
        rect.height * 0.4,
      ),
      doorPaint,
    );
  }

  void _renderFlower(Canvas canvas, Rect rect) {
    // Grass base
    final grassPaint = Paint()..color = Colors.green.shade300;
    canvas.drawOval(rect.deflate(4), grassPaint);

    // Flowers
    final flowerColors = [
      Colors.pink.shade400,
      Colors.red.shade400,
      Colors.yellow.shade400,
      Colors.purple.shade400,
    ];

    final random = math.Random(model.id.hashCode);
    for (int i = 0; i < 5; i++) {
      final flowerX = rect.left + 8 + random.nextDouble() * (rect.width - 16);
      final flowerY = rect.top + 8 + random.nextDouble() * (rect.height - 16);
      final color = flowerColors[random.nextInt(flowerColors.length)];

      // Stem
      final stemPaint = Paint()
        ..color = Colors.green.shade600
        ..strokeWidth = 2;
      canvas.drawLine(
        Offset(flowerX, flowerY),
        Offset(flowerX, flowerY + 8),
        stemPaint,
      );

      // Flower
      final flowerPaint = Paint()..color = color;
      canvas.drawCircle(Offset(flowerX, flowerY), 4, flowerPaint);

      // Center
      final centerPaint = Paint()..color = Colors.yellow;
      canvas.drawCircle(Offset(flowerX, flowerY), 2, centerPaint);
    }
  }

  void _renderRoad(Canvas canvas, Rect rect) {
    // Road base
    final roadPaint = Paint()..color = Colors.grey.shade700;
    canvas.drawRect(rect.deflate(2), roadPaint);

    // Road markings
    final markingPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;

    // Center line (dashed)
    final centerY = rect.center.dy;
    for (double x = rect.left + 8; x < rect.right - 8; x += 12) {
      canvas.drawLine(
        Offset(x, centerY),
        Offset(x + 6, centerY),
        markingPaint,
      );
    }
  }

  void _renderConstruction(Canvas canvas) {
    // Semi-transparent building preview
    canvas.saveLayer(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = Colors.white.withValues(alpha: 0.5),
    );
    _renderBuilding(canvas);
    canvas.restore();

    // Construction scaffolding
    final scaffoldPaint = Paint()
      ..color = Colors.orange.shade700
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRect(
      Rect.fromLTWH(6, 6, size.x - 12, size.y - 12),
      scaffoldPaint,
    );

    // Progress bar background
    final progressBgPaint = Paint()..color = Colors.grey.shade800;
    final progressBarRect = Rect.fromLTWH(
      8,
      size.y - 16,
      size.x - 16,
      10,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(progressBarRect, const Radius.circular(5)),
      progressBgPaint,
    );

    // Progress bar fill
    final progressPaint = Paint()..color = Colors.green;
    final progressWidth = (size.x - 16) * model.constructionProgress;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(8, size.y - 16, progressWidth, 10),
        const Radius.circular(5),
      ),
      progressPaint,
    );

    // Construction icon (hammer/wrench)
    final pulse = math.sin(_constructionPulse) * 0.1 + 1;
    final iconPaint = Paint()..color = Colors.yellow;
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2 - 10);
    canvas.scale(pulse);

    // Simple gear icon
    final gearPath = Path();
    const teeth = 8;
    const outerRadius = 12.0;
    const innerRadius = 8.0;

    for (int i = 0; i < teeth * 2; i++) {
      final angle = (i * math.pi) / teeth;
      final radius = i.isEven ? outerRadius : innerRadius;
      final x = math.cos(angle) * radius;
      final y = math.sin(angle) * radius;
      if (i == 0) {
        gearPath.moveTo(x, y);
      } else {
        gearPath.lineTo(x, y);
      }
    }
    gearPath.close();

    canvas.drawPath(gearPath, iconPaint);
    canvas.restore();
  }

  void _renderMoneyIcon(Canvas canvas) {
    final pulse = math.sin(_moneyIconPulse) * 2;
    final iconY = -8 + pulse;

    // Money icon background
    final bgPaint = Paint()..color = Colors.green.shade600;
    canvas.drawCircle(
      Offset(size.x / 2, iconY),
      14,
      bgPaint,
    );

    // Euro sign
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '€',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        size.x / 2 - textPainter.width / 2,
        iconY - textPainter.height / 2,
      ),
    );
  }

  @override
  bool onTapDown(TapDownEvent event) {
    // Don't handle tap if we're dragging
    if (_isDragging) return false;

    if (model.isUnderConstruction) {
      return false;
    }

    // Start long press timer for move mode
    _isLongPressing = true;
    _longPressTimer = 0;
    _longPressActivated = false;

    return true;
  }

  @override
  bool onTapUp(TapUpEvent event) {
    // If long press wasn't activated, this is a normal tap
    if (_isLongPressing && !_longPressActivated) {
      _isLongPressing = false;
      _longPressTimer = 0;

      // Handle normal tap - collect revenue or show info
      if (model.hasRevenueToCollect) {
        final revenue = game.gameState.collectRevenue(model.id);
        if (revenue > 0) {
          _spawnConfettiEffect(revenue);
          audioService.playCashRegister();
        }
      } else {
        game.showBuildingInfo(model);
      }
    }

    return true;
  }

  @override
  bool onTapCancel(TapCancelEvent event) {
    // Cancel long press if finger lifted too early
    if (_isLongPressing && !_longPressActivated) {
      _isLongPressing = false;
      _longPressTimer = 0;
    }
    return true;
  }

  // ==================== LONG-PRESS TO MOVE ====================

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);

    if (model.isUnderConstruction) {
      return;
    }

    // Start long press timer (dragging also triggers long press)
    if (!_isDragging) {
      _isLongPressing = true;
      _longPressTimer = 0;
      _longPressActivated = false;
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);

    // Only move if long press was activated
    if (!_isDragging || !_longPressActivated) return;

    // Move the building visually following the drag
    // Account for camera zoom
    final zoom = game.camera.viewfinder.zoom;
    position += event.localDelta / zoom;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);

    // Reset long press state
    _isLongPressing = false;
    _longPressTimer = 0;

    // If long press wasn't activated, do nothing (was just a touch)
    if (!_longPressActivated) {
      _isDragging = false;
      return;
    }

    _isDragging = false;
    _longPressActivated = false;

    // Calculate the grid position where we dropped
    final centerX = position.x + size.x / 2;
    final centerY = position.y + size.y / 2;
    final newGridX = (centerX / cellSize).floor() - (config.width ~/ 2);
    final newGridY = (centerY / cellSize).floor() - (config.height ~/ 2);

    // Check if we can move to this position
    final canMove = game.gameState.city.canMoveBuilding(model.id, newGridX, newGridY);

    if (canMove && (newGridX != _originalGridX || newGridY != _originalGridY)) {
      // Move the building in the model
      game.gameState.city.moveBuilding(model.id, newGridX, newGridY);

      // Snap to grid with drop animation
      final targetPosition = Vector2(newGridX * cellSize, newGridY * cellSize);
      position = targetPosition;

      // Drop animation (scale bounce)
      add(
        ScaleEffect.to(
          Vector2.all(1.1),
          EffectController(duration: 0.1),
        )..onComplete = () {
          add(
            ScaleEffect.to(
              Vector2.all(1.0),
              EffectController(duration: 0.1, curve: Curves.easeOut),
            ),
          );
        },
      );

      // Update priority for z-ordering
      priority = newGridY + newGridX;

      // Success haptic
      HapticFeedback.lightImpact();
    } else {
      // Revert to original position with smooth animation
      final originalPosition = Vector2(_originalGridX * cellSize, _originalGridY * cellSize);

      // Animate back to original position
      add(
        MoveEffect.to(
          originalPosition,
          EffectController(duration: 0.3, curve: Curves.easeOutBack),
        )..onComplete = () {
          priority = _originalGridY + _originalGridX;
        },
      );

      // Error haptic
      HapticFeedback.heavyImpact();
    }
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);

    // Reset long press state
    _isLongPressing = false;
    _longPressTimer = 0;

    if (!_isDragging) return;

    _isDragging = false;
    _longPressActivated = false;

    // Revert to original position with animation
    add(
      MoveEffect.to(
        Vector2(_originalGridX * cellSize, _originalGridY * cellSize),
        EffectController(duration: 0.3, curve: Curves.easeOutBack),
      )..onComplete = () {
        priority = _originalGridY + _originalGridX;
      },
    );
  }

  void _spawnConfettiEffect(int amount) {
    // Confetti colors
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.cyan,
    ];
    final random = math.Random();

    // Add confetti particles
    for (int i = 0; i < 20; i++) {
      final particle = ConfettiParticle(
        startPosition: Vector2(position.x + size.x / 2, position.y + size.y / 2),
        angle: -math.pi / 2 + (random.nextDouble() - 0.5) * math.pi, // Upward burst
        color: colors[random.nextInt(colors.length)],
        rotationSpeed: (random.nextDouble() - 0.5) * 10,
        particleSize: 6 + random.nextDouble() * 6,
      );
      parent?.add(particle);
    }

    // Add floating money text
    final moneyText = MoneyTextComponent(
      amount: amount,
      startPosition: Vector2(position.x + size.x / 2, position.y),
    );
    parent?.add(moneyText);
  }
}

/// Confetti particle effect when collecting money
class ConfettiParticle extends PositionComponent {
  final double angle;
  final Color color;
  final double rotationSpeed;
  final double particleSize;
  double _lifetime = 0;
  double _rotation = 0;
  double _velocityY = 0;
  static const double maxLifetime = 2.0;
  static const double gravity = 150.0;

  ConfettiParticle({
    required Vector2 startPosition,
    required this.angle,
    required this.color,
    required this.rotationSpeed,
    this.particleSize = 8.0,
  }) : super(position: startPosition);

  @override
  void update(double dt) {
    super.update(dt);
    _lifetime += dt;
    _rotation += rotationSpeed * dt;

    // Initial burst then fall with gravity
    final initialSpeed = 200.0 * (1 - _lifetime / 0.3).clamp(0.0, 1.0);
    position.x += math.cos(angle) * initialSpeed * dt;

    // Apply gravity
    _velocityY += gravity * dt;
    position.y += math.sin(angle) * initialSpeed * dt + _velocityY * dt;

    // Add some horizontal wobble
    position.x += math.sin(_lifetime * 10) * 20 * dt;

    if (_lifetime >= maxLifetime) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final progress = _lifetime / maxLifetime;
    final alpha = ((1 - progress) * 255).round().clamp(0, 255);

    final paint = Paint()
      ..color = color.withAlpha(alpha);

    canvas.save();
    canvas.rotate(_rotation);

    // Draw confetti rectangle
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: particleSize, height: particleSize * 0.6),
      paint,
    );

    canvas.restore();
  }
}

/// Floating money text that appears when collecting revenue
class MoneyTextComponent extends PositionComponent {
  final int amount;
  double _lifetime = 0;
  static const double maxLifetime = 1.5;

  MoneyTextComponent({
    required this.amount,
    required Vector2 startPosition,
  }) : super(position: startPosition);

  @override
  void update(double dt) {
    super.update(dt);
    _lifetime += dt;
    position.y -= dt * 40; // Float upward

    if (_lifetime >= maxLifetime) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final alpha = ((1 - (_lifetime / maxLifetime)) * 255).round().clamp(0, 255);

    final textPainter = TextPainter(
      text: TextSpan(
        text: '+$amount€',
        style: TextStyle(
          color: Colors.green.shade400.withAlpha(alpha),
          fontSize: 20,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black.withAlpha(alpha),
              blurRadius: 2,
              offset: const Offset(1, 1),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(-textPainter.width / 2, 0));
  }
}
