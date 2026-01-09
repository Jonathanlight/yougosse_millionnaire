import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Road component for connecting buildings (optional feature)
class RoadComponent extends PositionComponent {
  final int gridX;
  final int gridY;
  final double cellSize;
  final Set<RoadDirection> connections;

  RoadComponent({
    required this.gridX,
    required this.gridY,
    required this.cellSize,
    this.connections = const {},
  }) : super(
          position: Vector2(gridX * cellSize, gridY * cellSize),
          size: Vector2(cellSize, cellSize),
        );

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final roadPaint = Paint()..color = Colors.grey.shade600;
    final linePaint = Paint()
      ..color = Colors.yellow.shade600
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw road base
    canvas.drawRect(
      Rect.fromLTWH(4, 4, size.x - 8, size.y - 8),
      roadPaint,
    );

    // Draw center lines based on connections
    final center = Offset(size.x / 2, size.y / 2);

    if (connections.contains(RoadDirection.north) ||
        connections.contains(RoadDirection.south)) {
      // Vertical road
      canvas.drawLine(
        Offset(center.dx, 4),
        Offset(center.dx, size.y - 4),
        linePaint,
      );
    }

    if (connections.contains(RoadDirection.east) ||
        connections.contains(RoadDirection.west)) {
      // Horizontal road
      canvas.drawLine(
        Offset(4, center.dy),
        Offset(size.x - 4, center.dy),
        linePaint,
      );
    }

    // If no connections, draw a simple square
    if (connections.isEmpty) {
      canvas.drawLine(
        Offset(center.dx - 5, center.dy),
        Offset(center.dx + 5, center.dy),
        linePaint,
      );
    }
  }

  void updateConnections(Set<RoadDirection> newConnections) {
    connections.clear();
    connections.addAll(newConnections);
  }
}

enum RoadDirection { north, south, east, west }

/// Helper to manage road network
class RoadNetwork {
  final Map<(int, int), RoadComponent> roads = {};
  final double cellSize;

  RoadNetwork({required this.cellSize});

  RoadComponent? addRoad(int x, int y) {
    if (roads.containsKey((x, y))) return null;

    final road = RoadComponent(
      gridX: x,
      gridY: y,
      cellSize: cellSize,
    );

    roads[(x, y)] = road;
    _updateConnections(x, y);
    return road;
  }

  void removeRoad(int x, int y) {
    roads.remove((x, y));
    // Update adjacent roads
    _updateConnections(x - 1, y);
    _updateConnections(x + 1, y);
    _updateConnections(x, y - 1);
    _updateConnections(x, y + 1);
  }

  void _updateConnections(int x, int y) {
    final road = roads[(x, y)];
    if (road == null) return;

    final connections = <RoadDirection>{};

    if (roads.containsKey((x, y - 1))) connections.add(RoadDirection.north);
    if (roads.containsKey((x, y + 1))) connections.add(RoadDirection.south);
    if (roads.containsKey((x + 1, y))) connections.add(RoadDirection.east);
    if (roads.containsKey((x - 1, y))) connections.add(RoadDirection.west);

    road.updateConnections(connections);
  }
}
