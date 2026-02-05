import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../game/data/game_state.dart';
import '../models/cloud_game_save.dart';
import 'auth_service.dart';
import 'cloud_save_service.dart';
import 'connectivity_service.dart';
import 'sync_service.dart';

/// Statut de migration
enum MigrationStatus {
  notStarted,
  checking,
  migrating,
  completed,
  failed,
  skipped,
}

/// Resultat de migration
class MigrationResult {
  final bool success;
  final String? errorMessage;
  final int gamesMigrated;
  final String? migratedGameId;

  MigrationResult.success({this.gamesMigrated = 0, this.migratedGameId})
      : success = true,
        errorMessage = null;

  MigrationResult.failure(this.errorMessage)
      : success = false,
        gamesMigrated = 0,
        migratedGameId = null;

  MigrationResult.skipped()
      : success = true,
        errorMessage = null,
        gamesMigrated = 0,
        migratedGameId = null;
}

/// Service de migration des sauvegardes locales vers le cloud
class MigrationService extends ChangeNotifier {
  static const String _migrationStatusKey = 'migration_status';
  static const String _migratedGameIdKey = 'migrated_game_id';
  static const String _lastMigrationKey = 'last_migration_date';
  static const String _legacyGameBoxName = 'game_data';
  static const String _legacyPlayerBoxName = 'player_data';
  static const String _legacyCityBoxName = 'city_data';

  MigrationStatus _status = MigrationStatus.notStarted;
  String? _lastError;
  double _progress = 0.0;

  MigrationStatus get status => _status;
  String? get lastError => _lastError;
  double get progress => _progress;
  bool get isMigrating => _status == MigrationStatus.migrating;

  /// Verifier si une migration est necessaire
  Future<bool> needsMigration() async {
    final prefs = await SharedPreferences.getInstance();

    // Verifier si deja migre
    final migrationDone = prefs.getBool(_migrationStatusKey) ?? false;
    if (migrationDone) return false;

    // Verifier si l'utilisateur est connecte
    if (!authService.isAuthenticated) return false;

    // Verifier s'il y a des donnees locales a migrer
    final hasLegacyData = await _hasLegacyData();
    return hasLegacyData;
  }

  /// Verifier la presence de donnees legacy
  Future<bool> _hasLegacyData() async {
    try {
      // Verifier les anciennes boxes Hive
      final gameBox = await Hive.openBox(_legacyGameBoxName);
      if (gameBox.isNotEmpty) {
        await gameBox.close();
        return true;
      }
      await gameBox.close();

      // Verifier SharedPreferences (ancien systeme)
      final prefs = await SharedPreferences.getInstance();
      final hasGameState = prefs.containsKey('game_state');
      final hasPlayerData = prefs.containsKey('player_money') ||
          prefs.containsKey('player_xp');
      final hasCityData = prefs.containsKey('city_buildings') ||
          prefs.containsKey('city_name');

      return hasGameState || hasPlayerData || hasCityData;
    } catch (e) {
      debugPrint('[MigrationService] Erreur verification legacy: $e');
      return false;
    }
  }

  /// Demarrer la migration automatique
  Future<MigrationResult> autoMigrate() async {
    if (!authService.isAuthenticated) {
      return MigrationResult.failure('Utilisateur non connecte');
    }

    if (!connectivityService.isOnline) {
      return MigrationResult.failure('Pas de connexion internet');
    }

    final needsMig = await needsMigration();
    if (!needsMig) {
      return MigrationResult.skipped();
    }

    return await migrate();
  }

  /// Migrer les donnees locales vers le cloud
  Future<MigrationResult> migrate() async {
    if (_status == MigrationStatus.migrating) {
      return MigrationResult.failure('Migration deja en cours');
    }

    _status = MigrationStatus.migrating;
    _progress = 0.0;
    _lastError = null;
    notifyListeners();

    try {
      // Etape 1: Recuperer les donnees legacy
      _progress = 0.1;
      notifyListeners();

      final legacyGameState = await _loadLegacyGameState();
      if (legacyGameState == null) {
        _status = MigrationStatus.skipped;
        notifyListeners();
        return MigrationResult.skipped();
      }

      _progress = 0.3;
      notifyListeners();

      // Etape 2: Creer une partie cloud
      final gameName = await _getLegacyGameName() ?? 'Partie migrée';

      _progress = 0.5;
      notifyListeners();

      final createResult = await cloudSaveService.createGame(
        name: gameName,
        initialState: legacyGameState,
      );

      if (!createResult.success) {
        _status = MigrationStatus.failed;
        _lastError = createResult.errorMessage;
        notifyListeners();
        return MigrationResult.failure(createResult.errorMessage ?? 'Erreur creation');
      }

      _progress = 0.7;
      notifyListeners();

      // Etape 3: Definir comme partie courante
      final gameId = createResult.save!.gameId;
      await syncService.setCurrentGame(gameId);

      _progress = 0.9;
      notifyListeners();

      // Etape 4: Marquer comme migre
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_migrationStatusKey, true);
      await prefs.setString(_migratedGameIdKey, gameId);
      await prefs.setString(_lastMigrationKey, DateTime.now().toIso8601String());

      // Etape 5: Optionnel - Nettoyer les anciennes donnees
      // (on garde les donnees legacy en backup pour l'instant)

      _progress = 1.0;
      _status = MigrationStatus.completed;
      notifyListeners();

      debugPrint('[MigrationService] Migration reussie: $gameId');
      return MigrationResult.success(gamesMigrated: 1, migratedGameId: gameId);
    } catch (e) {
      _status = MigrationStatus.failed;
      _lastError = e.toString();
      notifyListeners();
      debugPrint('[MigrationService] Erreur migration: $e');
      return MigrationResult.failure(e.toString());
    }
  }

  /// Charger le GameState depuis les donnees legacy
  Future<GameState?> _loadLegacyGameState() async {
    try {
      // Methode 1: Essayer la box Hive game_data
      try {
        final gameBox = await Hive.openBox(_legacyGameBoxName);
        if (gameBox.isNotEmpty) {
          final gameJson = gameBox.get('current_game');
          if (gameJson != null) {
            await gameBox.close();
            if (gameJson is String) {
              final data = jsonDecode(gameJson) as Map<String, dynamic>;
              return GameState.fromJson(data);
            } else if (gameJson is Map) {
              return GameState.fromJson(Map<String, dynamic>.from(gameJson));
            }
          }
          await gameBox.close();
        }
      } catch (e) {
        debugPrint('[MigrationService] Pas de game_data box: $e');
      }

      // Methode 2: Essayer SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final gameStateJson = prefs.getString('game_state');
      if (gameStateJson != null) {
        final data = jsonDecode(gameStateJson) as Map<String, dynamic>;
        return GameState.fromJson(data);
      }

      // Methode 3: Reconstruire depuis les donnees separees
      final hasPlayerData = prefs.containsKey('player_money');
      final hasCityData = prefs.containsKey('city_name');

      if (hasPlayerData || hasCityData) {
        // Construire un GameState basique
        final playerJson = <String, dynamic>{
          'money': prefs.getInt('player_money') ?? 10000,
          'xp': prefs.getInt('player_xp') ?? 0,
          'gems': prefs.getInt('player_gems') ?? 50,
        };

        final cityName = prefs.getString('city_name') ?? 'Ma Ville';

        // Essayer de charger les batiments
        final buildingsJson = prefs.getString('city_buildings');
        List<dynamic>? buildings;
        if (buildingsJson != null) {
          buildings = jsonDecode(buildingsJson) as List<dynamic>;
        }

        final cityJson = <String, dynamic>{
          'buildings': buildings ?? [],
          'roads': [],
          'decorations': [],
        };

        return GameState.fromJson({
          'player': playerJson,
          'city': cityJson,
          'cityName': cityName,
        });
      }

      return null;
    } catch (e) {
      debugPrint('[MigrationService] Erreur loadLegacyGameState: $e');
      return null;
    }
  }

  /// Recuperer le nom de la partie legacy
  Future<String?> _getLegacyGameName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('city_name') ?? prefs.getString('game_name');
    } catch (e) {
      return null;
    }
  }

  /// Recuperer l'ID de la partie migree
  Future<String?> getMigratedGameId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_migratedGameIdKey);
  }

  /// Verifier si la migration a ete effectuee
  Future<bool> wasMigrated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_migrationStatusKey) ?? false;
  }

  /// Forcer la re-migration (pour debug/support)
  Future<void> resetMigrationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_migrationStatusKey);
    await prefs.remove(_migratedGameIdKey);
    await prefs.remove(_lastMigrationKey);
    _status = MigrationStatus.notStarted;
    _progress = 0.0;
    notifyListeners();
  }

  /// Nettoyer les donnees legacy apres confirmation
  Future<void> cleanupLegacyData() async {
    try {
      // Nettoyer Hive boxes
      if (await Hive.boxExists(_legacyGameBoxName)) {
        await Hive.deleteBoxFromDisk(_legacyGameBoxName);
      }
      if (await Hive.boxExists(_legacyPlayerBoxName)) {
        await Hive.deleteBoxFromDisk(_legacyPlayerBoxName);
      }
      if (await Hive.boxExists(_legacyCityBoxName)) {
        await Hive.deleteBoxFromDisk(_legacyCityBoxName);
      }

      // Nettoyer SharedPreferences (garder migration_status)
      final prefs = await SharedPreferences.getInstance();
      final keysToRemove = [
        'game_state',
        'player_money',
        'player_xp',
        'player_gems',
        'city_name',
        'city_buildings',
        'game_name',
      ];

      for (final key in keysToRemove) {
        await prefs.remove(key);
      }

      debugPrint('[MigrationService] Donnees legacy nettoyees');
    } catch (e) {
      debugPrint('[MigrationService] Erreur cleanup: $e');
    }
  }
}

/// Instance globale du service de migration
final migrationService = MigrationService();
