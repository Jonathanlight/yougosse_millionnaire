import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Utility class for formatting and helper methods
class Helpers {
  Helpers._();

  /// Format money with currency symbol (Euro)
  /// Uses compact notation for very large numbers
  static String formatMoney(int amount) {
    if (amount >= 1000000000000000) {
      // Quadrillion
      return '${(amount / 1000000000000000).toStringAsFixed(1)}Q€';
    } else if (amount >= 1000000000000) {
      // Trillion
      return '${(amount / 1000000000000).toStringAsFixed(1)}T€';
    } else if (amount >= 1000000000) {
      // Billion
      return '${(amount / 1000000000).toStringAsFixed(1)}B€';
    } else if (amount >= 1000000) {
      // Million
      return '${(amount / 1000000).toStringAsFixed(1)}M€';
    } else if (amount >= 10000) {
      // Thousands (only for 10K+)
      return '${(amount / 1000).toStringAsFixed(1)}K€';
    }
    final formatter = NumberFormat('#,###', 'fr_FR');
    return '${formatter.format(amount)}€';
  }

  /// Format time duration in human readable format
  static String formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  /// Format large numbers with K/M/B/T suffixes
  static String formatNumber(int number) {
    if (number >= 1000000000000000) {
      return '${(number / 1000000000000000).toStringAsFixed(1)}Q';
    } else if (number >= 1000000000000) {
      return '${(number / 1000000000000).toStringAsFixed(1)}T';
    } else if (number >= 1000000000) {
      return '${(number / 1000000000).toStringAsFixed(1)}B';
    } else if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  /// Calculate percentage
  static double percentage(int current, int max) {
    if (max == 0) return 0;
    return (current / max).clamp(0.0, 1.0);
  }

  /// Lerp color
  static Color lerpColor(Color a, Color b, double t) {
    return Color.lerp(a, b, t) ?? a;
  }

  /// Grid position to world position
  static Offset gridToWorld(int gridX, int gridY, double cellSize) {
    return Offset(gridX * cellSize, gridY * cellSize);
  }

  /// World position to grid position
  static (int, int) worldToGrid(Offset worldPos, double cellSize) {
    return (
      (worldPos.dx / cellSize).floor(),
      (worldPos.dy / cellSize).floor(),
    );
  }

  /// Check if a position is within grid bounds
  static bool isWithinGrid(int x, int y, int width, int height) {
    return x >= 0 && x < width && y >= 0 && y < height;
  }

  /// Calculate distance between two grid positions
  static double gridDistance(int x1, int y1, int x2, int y2) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    return (dx * dx + dy * dy).toDouble();
  }
}

/// Extension on DateTime for game time calculations
extension DateTimeExtension on DateTime {
  /// Get seconds elapsed since this time
  int secondsSince() {
    return DateTime.now().difference(this).inSeconds;
  }

  /// Get minutes elapsed since this time
  int minutesSince() {
    return DateTime.now().difference(this).inMinutes;
  }
}

/// Extension on Duration for game time formatting
extension DurationExtension on Duration {
  /// Format as game time
  String toGameTime() {
    return Helpers.formatDuration(this);
  }
}

/// Extension on int for money formatting
extension IntExtension on int {
  /// Format as currency
  String toCurrency() {
    return Helpers.formatMoney(this);
  }

  /// Format with K/M suffix
  String toCompact() {
    return Helpers.formatNumber(this);
  }
}
