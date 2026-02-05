import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../services/weather_service.dart';

/// Visual weather effects overlay
class WeatherEffectsComponent extends PositionComponent {
  final WeatherService weatherService;
  final double worldWidth;
  final double worldHeight;

  final List<_Particle> _particles = [];
  final Random _random = Random();

  static const int maxRainParticles = 400;
  static const int maxSnowParticles = 500;

  WeatherEffectsComponent({
    required this.weatherService,
    required this.worldWidth,
    required this.worldHeight,
  }) : super(priority: 9999); // Always on top

  @override
  void update(double dt) {
    super.update(dt);

    // Update existing particles
    _particles.removeWhere((p) => !p.update(dt, worldHeight));

    // Spawn new particles based on weather
    _spawnParticles();
  }

  void _spawnParticles() {
    switch (weatherService.currentWeather) {
      case WeatherType.rain:
        _spawnRain();
        break;
      case WeatherType.snow:
        _spawnSnow();
        break;
      default:
        // Clear particles gradually for other weather
        break;
    }
  }

  void _spawnRain() {
    final targetCount = (maxRainParticles * weatherService.weatherIntensity).round();
    while (_particles.length < targetCount) {
      // Variety in rain drops - some heavy, some light
      final isHeavyDrop = _random.nextDouble() < 0.3;
      _particles.add(_RainDrop(
        x: _random.nextDouble() * worldWidth,
        y: -_random.nextDouble() * 150,
        speed: isHeavyDrop ? 500 + _random.nextDouble() * 300 : 350 + _random.nextDouble() * 150,
        length: isHeavyDrop ? 15 + _random.nextDouble() * 20 : 8 + _random.nextDouble() * 12,
        thickness: isHeavyDrop ? 2.0 : 1.2,
      ));
    }
  }

  void _spawnSnow() {
    final targetCount = (maxSnowParticles * weatherService.weatherIntensity).round();
    while (_particles.length < targetCount) {
      // More variety in snowflakes
      final isLargeFlake = _random.nextDouble() < 0.2;
      _particles.add(_SnowFlake(
        x: _random.nextDouble() * worldWidth,
        y: -_random.nextDouble() * 100,
        speed: isLargeFlake ? 20 + _random.nextDouble() * 30 : 40 + _random.nextDouble() * 60,
        size: isLargeFlake ? 5 + _random.nextDouble() * 4 : 2 + _random.nextDouble() * 4,
        wobbleSpeed: 0.5 + _random.nextDouble() * 2.5,
        wobbleAmount: 15 + _random.nextDouble() * 40,
      ));
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Render ambient overlay based on weather/time
    _renderAmbientOverlay(canvas);

    // Render particles
    for (final particle in _particles) {
      particle.render(canvas);
    }
  }

  void _renderAmbientOverlay(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, worldWidth, worldHeight);

    switch (weatherService.currentWeather) {
      case WeatherType.night:
        // Dark blue overlay for night
        final paint = Paint()
          ..color = const Color(0xFF000033).withValues(alpha: 0.5);
        canvas.drawRect(rect, paint);

        // Add some stars
        _renderStars(canvas);
        break;

      case WeatherType.rain:
        // Dark gray overlay for rain atmosphere
        final paint = Paint()
          ..color = Colors.blueGrey.withValues(alpha: 0.25);
        canvas.drawRect(rect, paint);
        // Add darker clouds at top
        final cloudPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey.shade800.withValues(alpha: 0.3),
              Colors.transparent,
            ],
            stops: const [0.0, 0.4],
          ).createShader(rect);
        canvas.drawRect(rect, cloudPaint);
        break;

      case WeatherType.cloudy:
        // Light gray overlay
        final paint = Paint()
          ..color = Colors.grey.withValues(alpha: 0.15);
        canvas.drawRect(rect, paint);
        break;

      case WeatherType.snow:
        // White/blue tint for snowy atmosphere
        final paint = Paint()
          ..color = Colors.lightBlue.withValues(alpha: 0.15);
        canvas.drawRect(rect, paint);
        // Add fog effect at bottom for snow accumulation feel
        final fogPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.0),
              Colors.white.withValues(alpha: 0.1),
            ],
          ).createShader(Rect.fromLTWH(0, worldHeight * 0.7, worldWidth, worldHeight * 0.3));
        canvas.drawRect(Rect.fromLTWH(0, worldHeight * 0.7, worldWidth, worldHeight * 0.3), fogPaint);
        break;

      case WeatherType.sunny:
        // Warm yellow tint
        final paint = Paint()
          ..color = Colors.yellow.withValues(alpha: 0.05);
        canvas.drawRect(rect, paint);
        break;
    }
  }

  void _renderStars(Canvas canvas) {
    final starPaint = Paint()..color = Colors.white;
    final random = Random(42); // Fixed seed for consistent stars

    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * worldWidth;
      final y = random.nextDouble() * worldHeight * 0.5; // Top half only
      final size = 1 + random.nextDouble() * 2;

      // Twinkling effect
      final twinkle = (sin(DateTime.now().millisecondsSinceEpoch / 500.0 + i) + 1) / 2;
      starPaint.color = Colors.white.withValues(alpha: 0.3 + twinkle * 0.7);

      canvas.drawCircle(Offset(x, y), size, starPaint);
    }
  }
}

/// Base particle class
abstract class _Particle {
  double x;
  double y;

  _Particle({required this.x, required this.y});

  /// Update particle, return false if should be removed
  bool update(double dt, double maxY);

  /// Render the particle
  void render(Canvas canvas);
}

/// Rain drop particle
class _RainDrop extends _Particle {
  final double speed;
  final double length;
  final double thickness;

  _RainDrop({
    required super.x,
    required super.y,
    required this.speed,
    required this.length,
    this.thickness = 1.5,
  });

  @override
  bool update(double dt, double maxY) {
    y += speed * dt;
    // Wind effect varies with thickness
    x += (30 + thickness * 15) * dt;
    return y < maxY;
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.lightBlue.withValues(alpha: thickness > 1.5 ? 0.7 : 0.5)
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(x, y),
      Offset(x + thickness, y + length),
      paint,
    );
  }
}

/// Snow flake particle
class _SnowFlake extends _Particle {
  final double speed;
  final double size;
  final double wobbleSpeed;
  final double wobbleAmount;
  double _time = 0;
  final double _startX;

  _SnowFlake({
    required super.x,
    required super.y,
    required this.speed,
    required this.size,
    required this.wobbleSpeed,
    required this.wobbleAmount,
  }) : _startX = x;

  @override
  bool update(double dt, double maxY) {
    _time += dt;
    y += speed * dt;
    // Wobble left and right
    x = _startX + sin(_time * wobbleSpeed) * wobbleAmount;
    return y < maxY;
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(x, y), size, paint);

    // Inner glow
    final glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(Offset(x, y), size * 0.8, glowPaint);
  }
}
