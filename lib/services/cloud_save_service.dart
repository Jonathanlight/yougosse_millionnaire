import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../game/data/game_state.dart';
import '../models/cloud_game_save.dart';
import 'auth_service.dart';

/// Resultat d'une operation de sauvegarde cloud
class CloudSaveResult {
  final bool success;
  final String? errorMessage;
  final CloudGameSave? save;
  final List<GameMetadata>? gamesList;

  CloudSaveResult.success({this.save, this.gamesList})
      : success = true,
        errorMessage = null;

  CloudSaveResult.failure(this.errorMessage)
      : success = false,
        save = null,
        gamesList = null;
}

/// Service de sauvegarde cloud via Firestore
class CloudSaveService {
  // Lazy access to avoid accessing Firebase before initialization
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  static const String _usersCollection = 'users';
  static const String _gamesCollection = 'games';
  static const String _appVersion = '1.0.0';
  static const int _maxGamesPerUser = 10;

  /// Reference a la collection des parties d'un utilisateur
  CollectionReference<Map<String, dynamic>> _gamesRef(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_gamesCollection);
  }

  // ==================== LISTE DES PARTIES ====================

  /// Recuperer la liste des parties de l'utilisateur
  Future<CloudSaveResult> getGamesList() async {
    final userId = authService.userId;
    if (userId == null) {
      return CloudSaveResult.failure('Utilisateur non connecte');
    }

    try {
      final snapshot = await _gamesRef(userId)
          .orderBy('lastPlayedAt', descending: true)
          .get();

      final games = snapshot.docs
          .map((doc) => GameMetadata.fromFirestore(doc))
          .toList();

      debugPrint('[CloudSaveService] ${games.length} parties trouvees');
      return CloudSaveResult.success(gamesList: games);
    } catch (e) {
      debugPrint('[CloudSaveService] Erreur getGamesList: $e');
      return CloudSaveResult.failure('Erreur lors du chargement des parties: $e');
    }
  }

  /// Ecouter les changements de la liste des parties (temps reel)
  Stream<List<GameMetadata>> watchGamesList() {
    final userId = authService.userId;
    if (userId == null) {
      return Stream.value([]);
    }

    return _gamesRef(userId)
        .orderBy('lastPlayedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GameMetadata.fromFirestore(doc))
            .toList());
  }

  // ==================== CREER UNE PARTIE ====================

  /// Creer une nouvelle partie
  Future<CloudSaveResult> createGame({
    required String name,
    GameState? initialState,
  }) async {
    final userId = authService.userId;
    if (userId == null) {
      return CloudSaveResult.failure('Utilisateur non connecte');
    }

    try {
      // Verifier la limite de parties
      final existingGames = await _gamesRef(userId).count().get();
      if (existingGames.count != null && existingGames.count! >= _maxGamesPerUser) {
        return CloudSaveResult.failure(
            'Limite de $_maxGamesPerUser parties atteinte. Supprimez une partie pour en creer une nouvelle.');
      }

      // Generer un ID unique
      final gameId = _uuid.v4();
      final now = DateTime.now();

      // Creer le GameState initial si non fourni
      final gameState = initialState ?? GameState();

      // Creer la sauvegarde
      final save = CloudGameSave(
        gameId: gameId,
        name: name,
        createdAt: now,
        updatedAt: now,
        lastPlayedAt: now,
        version: _appVersion,
        syncTimestamp: now.millisecondsSinceEpoch,
        player: gameState.player,
        city: gameState.city,
        cityName: gameState.cityName,
      );

      // Sauvegarder dans Firestore
      await _gamesRef(userId).doc(gameId).set(save.toFirestore());

      // Incrementer le compteur de parties creees
      await _firestore.collection(_usersCollection).doc(userId).update({
        'totalGamesCreated': FieldValue.increment(1),
      });

      debugPrint('[CloudSaveService] Partie creee: $gameId');
      return CloudSaveResult.success(save: save);
    } catch (e) {
      debugPrint('[CloudSaveService] Erreur createGame: $e');
      return CloudSaveResult.failure('Erreur lors de la creation: $e');
    }
  }

  // ==================== CHARGER UNE PARTIE ====================

  /// Charger une partie complete
  Future<CloudSaveResult> loadGame(String gameId) async {
    final userId = authService.userId;
    if (userId == null) {
      return CloudSaveResult.failure('Utilisateur non connecte');
    }

    try {
      final doc = await _gamesRef(userId).doc(gameId).get();

      if (!doc.exists) {
        return CloudSaveResult.failure('Partie introuvable');
      }

      final save = CloudGameSave.fromFirestore(doc);

      // Mettre a jour lastPlayedAt
      await _gamesRef(userId).doc(gameId).update({
        'lastPlayedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[CloudSaveService] Partie chargee: $gameId');
      return CloudSaveResult.success(save: save);
    } catch (e) {
      debugPrint('[CloudSaveService] Erreur loadGame: $e');
      return CloudSaveResult.failure('Erreur lors du chargement: $e');
    }
  }

  // ==================== SAUVEGARDER UNE PARTIE ====================

  /// Sauvegarder une partie (mise a jour)
  Future<CloudSaveResult> saveGame({
    required String gameId,
    required GameState gameState,
    String? name,
  }) async {
    final userId = authService.userId;
    if (userId == null) {
      return CloudSaveResult.failure('Utilisateur non connecte');
    }

    try {
      final now = DateTime.now();

      // Recuperer les donnees existantes pour le nom et createdAt
      final existingDoc = await _gamesRef(userId).doc(gameId).get();
      if (!existingDoc.exists) {
        return CloudSaveResult.failure('Partie introuvable');
      }

      final existingData = existingDoc.data()!;
      final createdAt = (existingData['createdAt'] as Timestamp).toDate();
      final existingName = existingData['name'] as String;

      // Creer la sauvegarde mise a jour
      final save = CloudGameSave(
        gameId: gameId,
        name: name ?? existingName,
        createdAt: createdAt,
        updatedAt: now,
        lastPlayedAt: now,
        version: _appVersion,
        syncTimestamp: now.millisecondsSinceEpoch,
        player: gameState.player,
        city: gameState.city,
        cityName: gameState.cityName,
      );

      // Sauvegarder
      await _gamesRef(userId).doc(gameId).set(save.toFirestore());

      debugPrint('[CloudSaveService] Partie sauvegardee: $gameId');
      return CloudSaveResult.success(save: save);
    } catch (e) {
      debugPrint('[CloudSaveService] Erreur saveGame: $e');
      return CloudSaveResult.failure('Erreur lors de la sauvegarde: $e');
    }
  }

  /// Sauvegarde rapide (seulement les champs modifies frequemment)
  Future<CloudSaveResult> quickSave({
    required String gameId,
    required GameState gameState,
  }) async {
    final userId = authService.userId;
    if (userId == null) {
      return CloudSaveResult.failure('Utilisateur non connecte');
    }

    try {
      final now = DateTime.now();

      await _gamesRef(userId).doc(gameId).update({
        'updatedAt': Timestamp.fromDate(now),
        'lastPlayedAt': Timestamp.fromDate(now),
        'syncTimestamp': now.millisecondsSinceEpoch,
        'player': gameState.player.toJson(),
        'city': gameState.city.toJson(),
        'cityName': gameState.cityName,
      });

      debugPrint('[CloudSaveService] Quick save: $gameId');
      return CloudSaveResult.success();
    } catch (e) {
      debugPrint('[CloudSaveService] Erreur quickSave: $e');
      return CloudSaveResult.failure('Erreur lors de la sauvegarde rapide: $e');
    }
  }

  // ==================== SUPPRIMER UNE PARTIE ====================

  /// Supprimer une partie
  Future<CloudSaveResult> deleteGame(String gameId) async {
    final userId = authService.userId;
    if (userId == null) {
      return CloudSaveResult.failure('Utilisateur non connecte');
    }

    try {
      await _gamesRef(userId).doc(gameId).delete();

      debugPrint('[CloudSaveService] Partie supprimee: $gameId');
      return CloudSaveResult.success();
    } catch (e) {
      debugPrint('[CloudSaveService] Erreur deleteGame: $e');
      return CloudSaveResult.failure('Erreur lors de la suppression: $e');
    }
  }

  // ==================== RENOMMER UNE PARTIE ====================

  /// Renommer une partie
  Future<CloudSaveResult> renameGame(String gameId, String newName) async {
    final userId = authService.userId;
    if (userId == null) {
      return CloudSaveResult.failure('Utilisateur non connecte');
    }

    if (newName.trim().isEmpty) {
      return CloudSaveResult.failure('Le nom ne peut pas etre vide');
    }

    try {
      await _gamesRef(userId).doc(gameId).update({
        'name': newName.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[CloudSaveService] Partie renommee: $gameId -> $newName');
      return CloudSaveResult.success();
    } catch (e) {
      debugPrint('[CloudSaveService] Erreur renameGame: $e');
      return CloudSaveResult.failure('Erreur lors du renommage: $e');
    }
  }

  // ==================== DUPLIQUER UNE PARTIE ====================

  /// Dupliquer une partie
  Future<CloudSaveResult> duplicateGame(String gameId, String newName) async {
    final userId = authService.userId;
    if (userId == null) {
      return CloudSaveResult.failure('Utilisateur non connecte');
    }

    try {
      // Charger la partie originale
      final loadResult = await loadGame(gameId);
      if (!loadResult.success || loadResult.save == null) {
        return CloudSaveResult.failure('Impossible de charger la partie originale');
      }

      // Creer une copie avec un nouveau nom
      final gameState = loadResult.save!.toGameState();
      return await createGame(
        name: newName,
        initialState: gameState,
      );
    } catch (e) {
      debugPrint('[CloudSaveService] Erreur duplicateGame: $e');
      return CloudSaveResult.failure('Erreur lors de la duplication: $e');
    }
  }

  // ==================== VERIFICATION CONFLITS ====================

  /// Verifier si une sauvegarde locale est plus recente que le cloud
  Future<bool> isLocalNewer(String gameId, int localTimestamp) async {
    final userId = authService.userId;
    if (userId == null) return true;

    try {
      final doc = await _gamesRef(userId).doc(gameId).get();
      if (!doc.exists) return true;

      final cloudTimestamp = doc.data()?['syncTimestamp'] as int? ?? 0;
      return localTimestamp > cloudTimestamp;
    } catch (e) {
      return true;
    }
  }

  /// Recuperer le timestamp cloud d'une partie
  Future<int?> getCloudTimestamp(String gameId) async {
    final userId = authService.userId;
    if (userId == null) return null;

    try {
      final doc = await _gamesRef(userId).doc(gameId).get();
      if (!doc.exists) return null;

      return doc.data()?['syncTimestamp'] as int?;
    } catch (e) {
      return null;
    }
  }
}

/// Instance globale du service de sauvegarde cloud
final cloudSaveService = CloudSaveService();
