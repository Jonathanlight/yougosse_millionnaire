import 'package:flutter/material.dart';
import '../../game/data/building_data.dart';
import '../../game/data/game_state.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

/// Build menu overlay for selecting buildings to construct
class BuildMenuOverlay extends StatefulWidget {
  final GameState gameState;
  final void Function(BuildingType type) onBuildingSelected;
  final VoidCallback onClose;

  const BuildMenuOverlay({
    super.key,
    required this.gameState,
    required this.onBuildingSelected,
    required this.onClose,
  });

  @override
  State<BuildMenuOverlay> createState() => _BuildMenuOverlayState();
}

class _BuildMenuOverlayState extends State<BuildMenuOverlay>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<BuildingCategory> _categories = BuildingCategory.values;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: GestureDetector(
          onTap: () {},
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade600,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Construire',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.gameState.money.toCurrency(),
                            style: TextStyle(
                              color: Colors.green.shade400,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Category tabs
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      indicatorColor: Colors.blue,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey,
                      tabs: _categories.map((category) {
                        return Tab(
                          text: BuildingData.categoryNames[category],
                          icon: Icon(_getCategoryIcon(category)),
                        );
                      }).toList(),
                    ),

                    // Building grid
                    Flexible(
                      child: TabBarView(
                        controller: _tabController,
                        children: _categories.map((category) {
                          return _buildCategoryGrid(category);
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(BuildingCategory category) {
    final buildings = BuildingData.getUnlockedByCategory(
      category,
      widget.gameState.level,
    );

    if (buildings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock,
              color: Colors.grey.shade600,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              'Débloquez plus de bâtiments en montant de niveau !',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.0, // Changed from 1.2 to give more vertical space
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: buildings.length,
      itemBuilder: (context, index) {
        return _BuildingCard(
          config: buildings[index],
          canAfford: widget.gameState.player.canAfford(buildings[index].cost),
          onTap: () => widget.onBuildingSelected(buildings[index].type),
        );
      },
    );
  }

  IconData _getCategoryIcon(BuildingCategory category) {
    switch (category) {
      case BuildingCategory.residential:
        return Icons.home;
      case BuildingCategory.commercial:
        return Icons.store;
      case BuildingCategory.industrial:
        return Icons.factory;
      case BuildingCategory.decoration:
        return Icons.park;
      case BuildingCategory.monument:
        return Icons.account_balance;
      case BuildingCategory.infrastructure:
        return Icons.route;
    }
  }
}

class _BuildingCard extends StatelessWidget {
  final BuildingConfig config;
  final bool canAfford;
  final VoidCallback onTap;

  const _BuildingCard({
    required this.config,
    required this.canAfford,
    required this.onTap,
  });

  String _formatCycleDuration(int minutes) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      return '${hours}h';
    }
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: canAfford ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: canAfford
              ? Colors.grey.shade800
              : Colors.grey.shade800.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                canAfford ? config.color.withValues(alpha: 0.5) : Colors.grey.shade700,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Building preview
                  Expanded(
                    child: Center(
                      child: _BuildingPreview(config: config),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Building name
                  Text(
                    config.name,
                    style: TextStyle(
                      color: canAfford ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Cost and revenue
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          '${config.cost}€',
                          style: TextStyle(
                            color:
                                canAfford ? Colors.green.shade400 : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (config.hasRevenue)
                        Text(
                          '+${config.revenuePerCycle}€/${_formatCycleDuration(config.revenueCycleMinutes)}',
                          style: TextStyle(
                            color: Colors.blue.shade300,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Construction time badge
            if (config.constructionTimeSeconds > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.timer,
                        color: Colors.white,
                        size: 12,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${config.constructionTimeSeconds}s',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Size indicator
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${config.width}x${config.height}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
            ),

            // Locked overlay
            if (!canAfford)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.money_off,
                      color: Colors.red,
                      size: 32,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BuildingPreview extends StatelessWidget {
  final BuildingConfig config;

  const _BuildingPreview({required this.config});

  @override
  Widget build(BuildContext context) {
    // Use PNG image from config if available
    if (config.spritePath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          config.spritePath!,
          width: 60,
          height: 60,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to programmatic rendering if image fails
            return CustomPaint(
              size: const Size(60, 60),
              painter: _BuildingPreviewPainter(config: config),
            );
          },
        ),
      );
    }

    // Fallback to programmatic rendering for buildings without sprites
    return CustomPaint(
      size: const Size(60, 60),
      painter: _BuildingPreviewPainter(config: config),
    );
  }
}

class _BuildingPreviewPainter extends CustomPainter {
  final BuildingConfig config;

  _BuildingPreviewPainter({required this.config});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()..color = config.color;

    // Use category-based rendering as fallback
    switch (config.category) {
      case BuildingCategory.residential:
        _paintHouse(canvas, rect, paint);
      case BuildingCategory.commercial:
        _paintShop(canvas, rect, paint);
      case BuildingCategory.industrial:
        _paintFactory(canvas, rect, paint);
      case BuildingCategory.decoration:
        _paintPark(canvas, rect, paint);
      case BuildingCategory.monument:
        _paintTownHall(canvas, rect, paint);
      case BuildingCategory.infrastructure:
        _paintRoad(canvas, rect, paint);
    }
  }

  void _paintFlower(Canvas canvas, Rect rect, Paint paint) {
    // Grass base
    final grassPaint = Paint()..color = Colors.green.shade300;
    canvas.drawOval(rect.deflate(5), grassPaint);

    // Flowers
    final colors = [Colors.pink, Colors.red, Colors.yellow, Colors.purple];
    for (int i = 0; i < 4; i++) {
      final flowerPaint = Paint()..color = colors[i];
      canvas.drawCircle(
        Offset(
          rect.center.dx + (i % 2 == 0 ? -10 : 10),
          rect.center.dy + (i < 2 ? -8 : 8),
        ),
        5,
        flowerPaint,
      );
    }
  }

  void _paintRoad(Canvas canvas, Rect rect, Paint paint) {
    // Road base
    final roadPaint = Paint()..color = Colors.grey.shade700;
    canvas.drawRect(rect.deflate(5), roadPaint);

    // Road markings
    final markingPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(rect.left + 10, rect.center.dy),
      Offset(rect.right - 10, rect.center.dy),
      markingPaint,
    );
  }

  void _paintHouse(Canvas canvas, Rect rect, Paint paint) {
    // Body
    canvas.drawRect(
      Rect.fromLTWH(
          rect.left + 5, rect.top + rect.height * 0.4, rect.width - 10, rect.height * 0.55),
      paint,
    );

    // Roof
    final roofPaint = Paint()..color = config.roofColor;
    final roofPath = Path()
      ..moveTo(rect.left, rect.top + rect.height * 0.4)
      ..lineTo(rect.center.dx, rect.top + 5)
      ..lineTo(rect.right, rect.top + rect.height * 0.4)
      ..close();
    canvas.drawPath(roofPath, roofPaint);
  }

  void _paintApartment(Canvas canvas, Rect rect, Paint paint) {
    canvas.drawRect(
      Rect.fromLTWH(rect.left + 5, rect.top + 5, rect.width - 10, rect.height - 10),
      paint,
    );

    // Windows
    final windowPaint = Paint()..color = Colors.lightBlue.shade100;
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 2; col++) {
        canvas.drawRect(
          Rect.fromLTWH(
            rect.left + 10 + col * 22,
            rect.top + 10 + row * 14,
            8,
            8,
          ),
          windowPaint,
        );
      }
    }
  }

  void _paintShop(Canvas canvas, Rect rect, Paint paint) {
    canvas.drawRect(
      Rect.fromLTWH(rect.left + 5, rect.top + 15, rect.width - 10, rect.height - 20),
      paint,
    );

    // Awning
    final awningPaint = Paint()..color = Colors.red.shade700;
    canvas.drawRect(
      Rect.fromLTWH(rect.left + 2, rect.top + 10, rect.width - 4, 10),
      awningPaint,
    );
  }

  void _paintFactory(Canvas canvas, Rect rect, Paint paint) {
    canvas.drawRect(
      Rect.fromLTWH(rect.left + 5, rect.top + 20, rect.width - 10, rect.height - 25),
      paint,
    );

    // Chimney
    final chimneyPaint = Paint()..color = Colors.grey.shade700;
    canvas.drawRect(
      Rect.fromLTWH(rect.right - 20, rect.top + 5, 10, 20),
      chimneyPaint,
    );
  }

  void _paintPark(Canvas canvas, Rect rect, Paint paint) {
    canvas.drawOval(
      Rect.fromLTWH(rect.left + 5, rect.top + 10, rect.width - 10, rect.height - 15),
      paint,
    );

    // Trees
    final treePaint = Paint()..color = Colors.green.shade800;
    canvas.drawCircle(Offset(rect.center.dx - 10, rect.center.dy), 8, treePaint);
    canvas.drawCircle(Offset(rect.center.dx + 10, rect.center.dy + 5), 6, treePaint);
  }

  void _paintTownHall(Canvas canvas, Rect rect, Paint paint) {
    canvas.drawRect(
      Rect.fromLTWH(rect.left + 5, rect.top + 15, rect.width - 10, rect.height - 20),
      paint,
    );

    // Pediment
    final roofPaint = Paint()..color = config.roofColor;
    final roofPath = Path()
      ..moveTo(rect.left + 5, rect.top + 15)
      ..lineTo(rect.center.dx, rect.top + 5)
      ..lineTo(rect.right - 5, rect.top + 15)
      ..close();
    canvas.drawPath(roofPath, roofPaint);

    // Columns
    final columnPaint = Paint()..color = Colors.white;
    canvas.drawRect(
      Rect.fromLTWH(rect.left + 12, rect.top + 20, 5, 30),
      columnPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(rect.right - 17, rect.top + 20, 5, 30),
      columnPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
