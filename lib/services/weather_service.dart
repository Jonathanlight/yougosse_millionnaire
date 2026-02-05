import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Types of weather in the game
enum WeatherType {
  sunny,
  night,
  rain,
  snow,
  cloudy,
}

/// Service for managing weather with ChangeNotifier for reactive updates
class WeatherService extends ChangeNotifier {
  WeatherType _currentWeather = WeatherType.sunny;
  double _weatherIntensity = 0.5;
  Timer? _weatherTimer;
  final Random _random = Random();

  // Time of day (0.0 = midnight, 0.5 = noon, 1.0 = midnight)
  double _timeOfDay = 0.5;
  Timer? _timeTimer;
  bool _isNightTime = false;

  // Temperature in degrees Celsius
  int _temperature = 22;

  WeatherType get currentWeather => _currentWeather;
  double get weatherIntensity => _weatherIntensity;
  double get timeOfDay => _timeOfDay;
  bool get isNightTime => _isNightTime;
  int get temperature => _temperature;

  /// Get ambient light level (0.0 = dark, 1.0 = bright)
  double get ambientLight {
    if (_isNightTime) {
      return 0.3;
    }
    switch (_currentWeather) {
      case WeatherType.sunny:
        return 1.0;
      case WeatherType.cloudy:
        return 0.7;
      case WeatherType.rain:
        return 0.5;
      case WeatherType.snow:
        return 0.8;
      case WeatherType.night:
        return 0.3;
    }
  }

  /// Initialize the weather service
  void initialize() {
    _startWeatherCycle();
    _startDayCycle();
  }

  /// Start random weather changes
  void _startWeatherCycle() {
    _changeWeatherRandomly();

    // Change weather every 30-90 seconds
    _weatherTimer = Timer.periodic(
      Duration(seconds: 30 + _random.nextInt(60)),
      (_) => _changeWeatherRandomly(),
    );
  }

  /// Start day/night cycle
  void _startDayCycle() {
    // Update time every second (1 game day = 5 real minutes)
    _timeTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateTime(),
    );
  }

  void _updateTime() {
    // Advance time (full cycle in 5 minutes = 300 seconds)
    _timeOfDay += 1.0 / 1500.0;
    if (_timeOfDay >= 1.0) {
      _timeOfDay = 0.0;
    }

    // Night is between 0.75-0.25 (6PM to 6AM in game time)
    final wasNight = _isNightTime;
    _isNightTime = _timeOfDay < 0.25 || _timeOfDay > 0.75;

    if (wasNight != _isNightTime) {
      if (_isNightTime) {
        _currentWeather = WeatherType.night;
      } else if (_currentWeather == WeatherType.night) {
        _currentWeather = WeatherType.sunny;
      }
      notifyListeners();
    }
  }

  void _changeWeatherRandomly() {
    // Don't change weather at night (keep it as night)
    if (_isNightTime) {
      _currentWeather = WeatherType.night;
      _updateTemperature();
      notifyListeners();
      return;
    }

    // Weather probabilities:
    // Sunny: 40%, Cloudy: 25%, Rain: 20%, Snow: 15%
    final roll = _random.nextInt(100);

    if (roll < 40) {
      _currentWeather = WeatherType.sunny;
    } else if (roll < 65) {
      _currentWeather = WeatherType.cloudy;
    } else if (roll < 85) {
      _currentWeather = WeatherType.rain;
    } else {
      _currentWeather = WeatherType.snow;
    }

    // Random intensity
    _weatherIntensity = 0.3 + _random.nextDouble() * 0.7;

    // Update temperature based on weather
    _updateTemperature();

    notifyListeners();
  }

  void _updateTemperature() {
    // Base temperature depends on weather type
    switch (_currentWeather) {
      case WeatherType.sunny:
        _temperature = 25 + _random.nextInt(10); // 25-34
        break;
      case WeatherType.cloudy:
        _temperature = 18 + _random.nextInt(8); // 18-25
        break;
      case WeatherType.rain:
        _temperature = 12 + _random.nextInt(8); // 12-19
        break;
      case WeatherType.snow:
        _temperature = -5 + _random.nextInt(8); // -5 to 2
        break;
      case WeatherType.night:
        // Night is cooler
        _temperature = 10 + _random.nextInt(10); // 10-19
        break;
    }
  }

  /// Force a specific weather (for testing or events)
  void setWeather(WeatherType weather, {double intensity = 0.5}) {
    _currentWeather = weather;
    _weatherIntensity = intensity.clamp(0.0, 1.0);
    notifyListeners();
  }

  /// Dispose timers
  @override
  void dispose() {
    _weatherTimer?.cancel();
    _timeTimer?.cancel();
    super.dispose();
  }
}