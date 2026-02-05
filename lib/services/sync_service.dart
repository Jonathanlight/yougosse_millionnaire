import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../game/data/game_state.dart';
import '../models/cloud_game_save.dart';
import 'auth_service.dart';
import 'cloud_save_service.dart';
import 'connectivity_service.dart';

/// Statut de synchronisation
enum SyncStatus {
  idle,
  syncing,
  error,
  offline,
  success,
}

/// Resultat de synchronisation
class SyncResult {
  final bool success;
  final String? errorMessage;
  final int itemsSynced;
  final int itemsFailed;

  SyncResult.success({this.itemsSynced = 0})
      : success = true,
        errorMessage = null,
        itemsFailed = 0;

  SyncResult.failure(this.errorMessage)
      : success = false,
        itemsSynced = 0,
        itemsFailed = 0;

  SyncResult.partial({
    required this.itemsSynced,
    required this.itemsFailed,
    this.errorMessage,
  }) : success = itemsFailed == 0;
}

/// Service de synchronisation Hive <-> Firestore
class SyncService extends ChangeNotifier {
  static const String _syncQueueBoxName = 'sync_queue';
  static const String _localGamesBoxName = 'local_games';
  static const String _syncMetaBoxName = 'sync_meta';
  static const int _maxRetries = 3;
  static const Duration _autoSyncInterval = Duration(minutes: 5);
  static const Duration _debounceDelay = Duration(seconds: 2);

  final Uuid _uuid = const Uuid();

  Box<String>? _syncQueueBox;
  Box<String>? _localGamesBox;
  Box<dynamic>? _syncMetaBox;

  Timer? _autoSyncTimer;
  Timer? _debounceTimer;

  SyncStatus _status = SyncStatus.idle;
  String? _lastError;
  DateTime? _lastSyncTime;
  String? _currentGameId;

  SyncStatus get status => _status;
  String? get lastError => _lastError;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get currentGameId => _currentGameId;
  bool get isSyncing => _status == SyncStatus.syncing;

  /// Initialiser le service
  Future<void> initialize() async {
    _syncQueueBox = await Hive.openBox<String>(_syncQueueBoxName);
    _localGamesBox = await Hive.openBox<String>(_localGamesBoxName);
    _syncMetaBox = await Hive.openBox<dynamic>(_syncMetaBoxName);

    _lastSyncTime = _syncMetaBox?.get('lastSyncTime') as DateTime?;
    _currentGameId = _syncMetaBox?.get('currentGameId') as String?;

    // Ecouter les changements de connectivite
    connectivityService.addListener(_onConnectivityChanged);

    // Demarrer la sync auto si connecte
    if (connectivityService.isOnline && authService.isAuthenticated) {
      _startAutoSync();
      // Sync immediate au demarrage
      unawaited(_processQueue());
    }

    debugPrint('[SyncService] Initialise - Queue: ${_syncQueueBox?.length ?? 0} items');
  }

  /// Callback changement de connectivite
  void _onConnectivityChanged() {
    if (connectivityService.isOnline && authService.isAuthenticated) {
      _status = SyncStatus.idle;
      _startAutoSync();
      unawaited(_processQueue());
    } else {
      _status = SyncStatus.offline;
      _stopAutoSync();
    }
    notifyListeners();
  }

  /// Demarrer la synchronisation automatique
  void _startAutoSync() {
    _stopAutoSync();
    _autoSyncTimer = Timer.periodic(_autoSyncInterval, (_) {
      if (connectivityService.isOnline && authService.isAuthenticated) {
        unawaited(_processQueue());
      }
    });
  }

  /// Arreter la synchronisation automatique
  void _stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
  }

  // ==================== GESTION PARTIE COURANTE ====================

  /// Definir la partie en cours
  Future<void> setCurrentGame(String gameId) async {
    _currentGameId = gameId;
    await _syncMetaBox?.put('currentGameId', gameId);
    notifyListeners();
  }

  /// Charger la partie courante depuis le cache local
  Future<GameState?> loadCurrentGameFromCache() async {
    if (_currentGameId == null) return null;
    return await loadGameFromCache(_currentGameId!);
  }

  /// Charger une partie depuis le cache local
  Future<GameState?> loadGameFromCache(String gameId) async {
    final jsonStr = _localGamesBox?.get(gameId);
    if (jsonStr == null) return null;

    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final save = CloudGameSave(
        gameId: json['gameId'] as String,
        name: json['name'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        lastPlayedAt: DateTime.parse(json['lastPlayedAt'] as String),
        version: json['version'] as String,
        syncTimestamp: json['syncTimestamp'] as int,
        player: _parsePlayer(json['player'] as Map<String, dynamic>),
        city: _parseCity(json['city'] as Map<String, dynamic>),
        cityName: json['cityName'] as String,
      );
      return save.toGameState();
    } catch (e) {
      debugPrint('[SyncService] Erreur loadGameFromCache: $e');
      return null;
    }
  }

  /// Helper pour parser PlayerModel
  dynamic _parsePlayer(Map<String, dynamic> json) {
    // Import dynamique pour eviter les dependances circulaires
    return json;
  }

  /// Helper pour parser CityModel
  dynamic _parseCity(Map<String, dynamic> json) {
    return json;
  }

  // ==================== SAUVEGARDE LOCALE + QUEUE ====================

  /// Sauvegarder localement et ajouter a la queue de sync
  Future<void> saveLocally({
    required String gameId,
    required String name,
    required GameState gameState,
    SyncAction action = SyncAction.update,
  }) async {
    final now = DateTime.now();

    // Creer la sauvegarde locale
    final saveData = {
      'gameId': gameId,
      'name': name,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'lastPlayedAt': now.toIso8601String(),
      'version': '1.0.0',
      'syncTimestamp': now.millisecondsSinceEpoch,
      'player': gameState.player.toJson(),
      'city': gameState.city.toJson(),
      'cityName': gameState.cityName,
    };

    // Sauvegarder dans Hive
    await _localGamesBox?.put(gameId, jsonEncode(saveData));

    // Ajouter a la queue de sync
    await _addToQueue(gameId, action, saveData);

    // Debounce sync
    _debouncedSync();
  }

  /// Ajouter un element a la queue de synchronisation
  Future<void> _addToQueue(
    String gameId,
    SyncAction action,
    Map<String, dynamic> data,
  ) async {
    final item = SyncQueueItem(
      id: _uuid.v4(),
      gameId: gameId,
      action: action,
      createdAt: DateTime.now(),
      data: data,
    );

    await _syncQueueBox?.put(item.id, jsonEncode(item.toJson()));
    debugPrint('[SyncService] Ajoute a la queue: ${action.name} - $gameId');
  }

  /// Marquer une partie pour suppression
  Future<void> markForDeletion(String gameId) async {
    await _localGamesBox?.delete(gameId);
    await _addToQueue(gameId, SyncAction.delete, {'gameId': gameId});
    _debouncedSync();
  }

  /// Debounced sync pour eviter trop d'appels
  void _debouncedSync() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDelay, () {
      if (connectivityService.isOnline && authService.isAuthenticated) {
        unawaited(_processQueue());
      }
    });
  }

  // ==================== TRAITEMENT QUEUE ====================

  /// Traiter la queue de synchronisation
  Future<SyncResult> _processQueue() async {
    if (_status == SyncStatus.syncing) {
      return SyncResult.failure('Synchronisation deja en cours');
    }

    if (!connectivityService.isOnline) {
      _status = SyncStatus.offline;
      notifyListeners();
      return SyncResult.failure('Hors ligne');
    }

    if (!authService.isAuthenticated) {
      return SyncResult.failure('Non authentifie');
    }

    final queueItems = _syncQueueBox?.keys.toList() ?? [];
    if (queueItems.isEmpty) {
      return SyncResult.success();
    }

    _status = SyncStatus.syncing;
    _lastError = null;
    notifyListeners();

    int synced = 0;
    int failed = 0;

    for (final key in queueItems) {
      final jsonStr = _syncQueueBox?.get(key);
      if (jsonStr == null) continue;

      try {
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        final item = SyncQueueItem.fromJson(json);

        final success = await _processSyncItem(item);

        if (success) {
          await _syncQueueBox?.delete(key);
          synced++;
        } else if (item.retryCount >= _maxRetries) {
          // Trop de tentatives, supprimer
          await _syncQueueBox?.delete(key);
          failed++;
          debugPrint('[SyncService] Abandon apres $_maxRetries tentatives: ${item.gameId}');
        } else {
          // Incrementer le compteur de retry
          final updatedItem = item.incrementRetry();
          await _syncQueueBox?.put(key, jsonEncode(updatedItem.toJson()));
          failed++;
        }
      } catch (e) {
        debugPrint('[SyncService] Erreur traitement queue item: $e');
        failed++;
      }
    }

    _lastSyncTime = DateTime.now();
    await _syncMetaBox?.put('lastSyncTime', _lastSyncTime);

    if (failed > 0) {
      _status = SyncStatus.error;
      _lastError = '$failed elements non synchronises';
    } else {
      _status = SyncStatus.success;
    }

    notifyListeners();

    debugPrint('[SyncService] Queue traitee: $synced sync, $failed echecs');
    return SyncResult.partial(
      itemsSynced: synced,
      itemsFailed: failed,
    );
  }

  /// Traiter un element de la queue
  Future<bool> _processSyncItem(SyncQueueItem item) async {
    try {
      switch (item.action) {
        case SyncAction.create:
          final result = await cloudSaveService.createGame(
            name: item.data['name'] as String,
          );
          return result.success;

        case SyncAction.update:
          // Recuperer le GameState depuis les donnees
          final localJson = _localGamesBox?.get(item.gameId);
          if (localJson == null) return false;

          final localData = jsonDecode(localJson) as Map<String, dynamic>;

          // Verifier si cloud est plus recent
          final cloudTimestamp = await cloudSaveService.getCloudTimestamp(item.gameId);
          final localTimestamp = localData['syncTimestamp'] as int? ?? 0;

          if (cloudTimestamp != null && cloudTimestamp > localTimestamp) {
            // Cloud est plus recent, ne pas ecraser
            debugPrint('[SyncService] Cloud plus recent, skip update: ${item.gameId}');
            return true; // Considere comme reussi pour vider la queue
          }

          final result = await cloudSaveService.quickSave(
            gameId: item.gameId,
            gameState: _gameStateFromLocalData(localData),
          );
          return result.success;

        case SyncAction.delete:
          final result = await cloudSaveService.deleteGame(item.gameId);
          return result.success;
      }
    } catch (e) {
      debugPrint('[SyncService] Erreur processSyncItem: $e');
      return false;
    }
  }

  /// Convertir donnees locales en GameState
  GameState _gameStateFromLocalData(Map<String, dynamic> data) {
    return GameState.fromJson({
      'player': data['player'],
      'city': data['city'],
      'cityName': data['cityName'],
    });
  }

  // ==================== SYNC MANUELLE ====================

  /// Forcer la synchronisation
  Future<SyncResult> forceSync() async {
    if (!connectivityService.isOnline) {
      return SyncResult.failure('Pas de connexion internet');
    }

    if (!authService.isAuthenticated) {
      return SyncResult.failure('Utilisateur non connecte');
    }

    return await _processQueue();
  }

  /// Telecharger une partie depuis le cloud
  Future<GameState?> downloadFromCloud(String gameId) async {
    if (!connectivityService.isOnline) return null;
    if (!authService.isAuthenticated) return null;

    final result = await cloudSaveService.loadGame(gameId);
    if (!result.success || result.save == null) return null;

    // Sauvegarder localement
    final save = result.save!;
    final localData = {
      'gameId': save.gameId,
      'name': save.name,
      'createdAt': save.createdAt.toIso8601String(),
      'updatedAt': save.updatedAt.toIso8601String(),
      'lastPlayedAt': save.lastPlayedAt.toIso8601String(),
      'version': save.version,
      'syncTimestamp': save.syncTimestamp,
      'player': save.player.toJson(),
      'city': save.city.toJson(),
      'cityName': save.cityName,
    };

    await _localGamesBox?.put(gameId, jsonEncode(localData));

    return save.toGameState();
  }

  /// Uploader la partie courante vers le cloud
  Future<SyncResult> uploadCurrentGame() async {
    if (_currentGameId == null) {
      return SyncResult.failure('Aucune partie en cours');
    }

    final localJson = _localGamesBox?.get(_currentGameId!);
    if (localJson == null) {
      return SyncResult.failure('Partie locale introuvable');
    }

    // Ajouter a la queue et forcer sync
    final localData = jsonDecode(localJson) as Map<String, dynamic>;
    await _addToQueue(_currentGameId!, SyncAction.update, localData);

    return await forceSync();
  }

  // ==================== GESTION CONFLITS ====================

  /// Verifier s'il y a un conflit de version
  Future<bool> hasConflict(String gameId) async {
    final localJson = _localGamesBox?.get(gameId);
    if (localJson == null) return false;

    final localData = jsonDecode(localJson) as Map<String, dynamic>;
    final localTimestamp = localData['syncTimestamp'] as int? ?? 0;

    final cloudTimestamp = await cloudSaveService.getCloudTimestamp(gameId);
    if (cloudTimestamp == null) return false;

    // Conflit si les deux ont ete modifies
    return localTimestamp != cloudTimestamp;
  }

  /// Resoudre un conflit en gardant la version locale
  Future<void> resolveConflictKeepLocal(String gameId) async {
    final localJson = _localGamesBox?.get(gameId);
    if (localJson == null) return;

    final localData = jsonDecode(localJson) as Map<String, dynamic>;
    // Forcer l'upload
    await _addToQueue(gameId, SyncAction.update, localData);
    await forceSync();
  }

  /// Resoudre un conflit en gardant la version cloud
  Future<void> resolveConflictKeepCloud(String gameId) async {
    // Supprimer de la queue locale
    final keysToRemove = <dynamic>[];
    for (final key in _syncQueueBox?.keys ?? []) {
      final jsonStr = _syncQueueBox?.get(key);
      if (jsonStr == null) continue;

      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      if (json['gameId'] == gameId) {
        keysToRemove.add(key);
      }
    }

    for (final key in keysToRemove) {
      await _syncQueueBox?.delete(key);
    }

    // Telecharger depuis le cloud
    await downloadFromCloud(gameId);
  }

  // ==================== UTILITAIRES ====================

  /// Obtenir toutes les parties locales
  Future<List<GameMetadata>> getLocalGamesList() async {
    final games = <GameMetadata>[];

    for (final key in _localGamesBox?.keys ?? []) {
      final jsonStr = _localGamesBox?.get(key);
      if (jsonStr == null) continue;

      try {
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;
        games.add(GameMetadata(
          gameId: data['gameId'] as String,
          name: data['name'] as String,
          createdAt: DateTime.parse(data['createdAt'] as String),
          updatedAt: DateTime.parse(data['updatedAt'] as String),
          lastPlayedAt: DateTime.parse(data['lastPlayedAt'] as String),
          money: (data['player'] as Map<String, dynamic>?)?['money'] as int? ?? 0,
          level: _calculateLevel((data['player'] as Map<String, dynamic>?)?['xp'] as int? ?? 0),
          population: _calculatePopulation(data['city'] as Map<String, dynamic>?),
          buildingsCount: ((data['city'] as Map<String, dynamic>?)?['buildings'] as List?)?.length ?? 0,
          version: data['version'] as String? ?? '1.0.0',
        ));
      } catch (e) {
        debugPrint('[SyncService] Erreur parsing local game: $e');
      }
    }

    // Trier par derniere partie jouee
    games.sort((a, b) => b.lastPlayedAt.compareTo(a.lastPlayedAt));
    return games;
  }

  int _calculateLevel(int xp) => (xp / 100).floor() + 1;

  int _calculatePopulation(Map<String, dynamic>? city) {
    if (city == null) return 0;
    final buildings = city['buildings'] as List?;
    return (buildings?.length ?? 0) * 10;
  }

  /// Nombre d'elements en attente de sync
  int get pendingCount => _syncQueueBox?.length ?? 0;

  /// Vider le cache local
  Future<void> clearLocalCache() async {
    await _localGamesBox?.clear();
    await _syncQueueBox?.clear();
    await _syncMetaBox?.clear();
    _currentGameId = null;
    _lastSyncTime = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    _debounceTimer?.cancel();
    connectivityService.removeListener(_onConnectivityChanged);
    super.dispose();
  }
}

/// Instance globale du service de synchronisation
final syncService = SyncService();
