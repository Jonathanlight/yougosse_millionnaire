import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Service for managing app localization
class LocalizationService extends ChangeNotifier {
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  String _currentLocale = 'fr';
  Map<String, dynamic> _translations = {};
  bool _isInitialized = false;

  String get currentLocale => _currentLocale;
  bool get isInitialized => _isInitialized;

  /// Initialize the localization service
  Future<void> initialize([String locale = 'fr']) async {
    await setLocale(locale);
    _isInitialized = true;
  }

  /// Set the current locale and load translations
  Future<void> setLocale(String locale) async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/$locale.json');
      _translations = json.decode(jsonString);
      _currentLocale = locale;
      notifyListeners();
    } catch (e) {
      print('Failed to load locale $locale: $e');
      // Fallback to French if the locale is not found
      if (locale != 'fr') {
        await setLocale('fr');
      }
    }
  }

  /// Toggle between French and English
  Future<void> toggleLocale() async {
    final newLocale = _currentLocale == 'fr' ? 'en' : 'fr';
    await setLocale(newLocale);
  }

  /// Get a translated string by key path (e.g., "settings.title")
  String t(String key, [Map<String, dynamic>? params]) {
    final keys = key.split('.');
    dynamic value = _translations;

    for (final k in keys) {
      if (value is Map<String, dynamic> && value.containsKey(k)) {
        value = value[k];
      } else {
        return key; // Return the key if translation not found
      }
    }

    if (value is String) {
      // Replace parameters in the string
      if (params != null) {
        String result = value;
        params.forEach((paramKey, paramValue) {
          result = result.replaceAll('{$paramKey}', paramValue.toString());
        });
        return result;
      }
      return value;
    }

    return key;
  }
}

/// Global localization service instance
final localizationService = LocalizationService();

/// Extension for easy access to translations
extension LocalizationExtension on String {
  String tr([Map<String, dynamic>? params]) {
    return localizationService.t(this, params);
  }
}
