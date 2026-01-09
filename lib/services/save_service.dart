import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../game/data/game_state.dart';
import '../models/city_model.dart';
import '../models/player_model.dart';

/// Service for saving and loading game state using Hive
class SaveService {
  static const String _boxName = 'game_save';
  static const String _saveKey = 'current_save';
  static const String _settingsKey = 'settings';

  late Box<String> _box;
  bool _isInitialized = false;

  /// Initialize Hive and open the save box
  Future<void> initialize() async {
    if (_isInitialized) return;

    await Hive.initFlutter();

    try {
      _box = await Hive.openBox<String>(_boxName);
    } catch (e) {
      // If the box is corrupted or has issues, delete it and create a fresh one
      await Hive.deleteBoxFromDisk(_boxName);
      _box = await Hive.openBox<String>(_boxName);
    }
    _isInitialized = true;
  }

  /// Check if a save exists
  bool hasSave() {
    _ensureInitialized();
    return _box.containsKey(_saveKey);
  }

  /// Save the current game state
  Future<void> saveGame(GameState gameState) async {
    _ensureInitialized();

    final saveData = jsonEncode(gameState.toJson());
    await _box.put(_saveKey, saveData);
  }

  /// Load the saved game state
  Future<GameState?> loadGame() async {
    _ensureInitialized();

    final saveData = _box.get(_saveKey);
    if (saveData == null) return null;

    try {
      final json = jsonDecode(saveData) as Map<String, dynamic>;
      return GameState.fromJson(json);
    } catch (e) {
      // Corrupted save, return null
      return null;
    }
  }

  /// Load just the player data
  Future<PlayerModel?> loadPlayer() async {
    _ensureInitialized();

    final saveData = _box.get(_saveKey);
    if (saveData == null) return null;

    try {
      final json = jsonDecode(saveData) as Map<String, dynamic>;
      if (json.containsKey('player')) {
        return PlayerModel.fromJson(json['player'] as Map<String, dynamic>);
      }
    } catch (e) {
      // Corrupted save
    }
    return null;
  }

  /// Load just the city data
  Future<CityModel?> loadCity() async {
    _ensureInitialized();

    final saveData = _box.get(_saveKey);
    if (saveData == null) return null;

    try {
      final json = jsonDecode(saveData) as Map<String, dynamic>;
      if (json.containsKey('city')) {
        return CityModel.fromJson(json['city'] as Map<String, dynamic>);
      }
    } catch (e) {
      // Corrupted save
    }
    return null;
  }

  /// Delete the save
  Future<void> deleteSave() async {
    _ensureInitialized();
    await _box.delete(_saveKey);
  }

  /// Save settings
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    _ensureInitialized();
    await _box.put(_settingsKey, jsonEncode(settings));
  }

  /// Load settings
  Future<Map<String, dynamic>?> loadSettings() async {
    _ensureInitialized();

    final settingsData = _box.get(_settingsKey);
    if (settingsData == null) return null;

    try {
      return jsonDecode(settingsData) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('SaveService not initialized. Call initialize() first.');
    }
  }

  /// Close the Hive box
  Future<void> close() async {
    if (_isInitialized) {
      await _box.close();
      _isInitialized = false;
    }
  }
}

/// Global save service instance
final saveService = SaveService();
