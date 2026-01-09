import 'package:flutter/material.dart';
import '../../services/weather_service.dart';

/// Overlay showing current weather status
class WeatherOverlay extends StatelessWidget {
  final WeatherService weatherService;

  const WeatherOverlay({
    super.key,
    required this.weatherService,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: weatherService,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _getBackgroundColor().withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _getGlowColor().withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _getWeatherIcon(),
              const SizedBox(width: 8),
              Text(
                _getWeatherText(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _getWeatherIcon() {
    IconData icon;
    Color color;
    double size = 20;

    switch (weatherService.currentWeather) {
      case WeatherType.sunny:
        icon = Icons.wb_sunny;
        color = Colors.yellow;
        break;
      case WeatherType.night:
        icon = Icons.nightlight_round;
        color = Colors.indigo.shade200;
        break;
      case WeatherType.rain:
        icon = Icons.water_drop;
        color = Colors.lightBlue;
        break;
      case WeatherType.snow:
        icon = Icons.ac_unit;
        color = Colors.white;
        break;
      case WeatherType.cloudy:
        icon = Icons.cloud;
        color = Colors.grey.shade300;
        break;
    }

    return Icon(icon, color: color, size: size);
  }

  String _getWeatherText() {
    switch (weatherService.currentWeather) {
      case WeatherType.sunny:
        return 'Ensoleille';
      case WeatherType.night:
        return 'Nuit';
      case WeatherType.rain:
        return 'Pluie';
      case WeatherType.snow:
        return 'Neige';
      case WeatherType.cloudy:
        return 'Nuageux';
    }
  }

  Color _getBackgroundColor() {
    switch (weatherService.currentWeather) {
      case WeatherType.sunny:
        return Colors.orange.shade800;
      case WeatherType.night:
        return Colors.indigo.shade900;
      case WeatherType.rain:
        return Colors.blueGrey.shade700;
      case WeatherType.snow:
        return Colors.blue.shade800;
      case WeatherType.cloudy:
        return Colors.grey.shade700;
    }
  }

  Color _getGlowColor() {
    switch (weatherService.currentWeather) {
      case WeatherType.sunny:
        return Colors.yellow;
      case WeatherType.night:
        return Colors.indigo;
      case WeatherType.rain:
        return Colors.blue;
      case WeatherType.snow:
        return Colors.lightBlue;
      case WeatherType.cloudy:
        return Colors.grey;
    }
  }
}
