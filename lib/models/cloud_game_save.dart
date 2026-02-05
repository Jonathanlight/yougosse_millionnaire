import 'package:cloud_firestore/cloud_firestore.dart';
import '../game/data/game_state.dart';
import 'city_model.dart';
import 'player_model.dart';

/// Metadonnees resumees d'une partie (pour liste)
class GameMetadata {
  final String gameId;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastPlayedAt;
  final int money;
  final int level;
  final int population;
  final int buildingsCount;
  final String version;

  GameMetadata({
    required this.gameId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.lastPlayedAt,
    required this.money,
    required this.level,
    required this.population,
    required this.buildingsCount,
    required this.version,
  });

  factory GameMetadata.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GameMetadata(
      gameId: doc.id,
      name: data['name'] as String? ?? 'Partie sans nom',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastPlayedAt: (data['lastPlayedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      money: data['player']?['money'] as int? ?? 0,
      level: _calculateLevel(data['player']?['xp'] as int? ?? 0),
      population: _calculatePopulation(data['city']),
      buildingsCount: (data['city']?['buildings'] as List?)?.length ?? 0,
      version: data['version'] as String? ?? '1.0.0',
    );
  }

  static int _calculateLevel(int xp) {
    return (xp / 100).floor() + 1;
  }

  static int _calculatePopulation(Map<String, dynamic>? cityData) {
    if (cityData == null) return 0;
    final buildings = cityData['buildings'] as List?;
    if (buildings == null) return 0;
    // Calcul simplifie - le vrai calcul est dans CityModel
    return buildings.length * 10;
  }
}

/// Sauvegarde complete d'une partie dans le cloud
class CloudGameSave {
  final String gameId;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastPlayedAt;
  final String version;
  final int syncTimestamp; // Pour anti-rollback
  final PlayerModel player;
  final CityModel city;
  final String cityName;
  final Map<String, dynamic>? objectives;
  final Map<String, dynamic>? shopData;
  final Map<String, dynamic>? settings;

  CloudGameSave({
    required this.gameId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.lastPlayedAt,
    required this.version,
    required this.syncTimestamp,
    required this.player,
    required this.city,
    required this.cityName,
    this.objectives,
    this.shopData,
    this.settings,
  });

  /// Creer depuis un GameState existant
  factory CloudGameSave.fromGameState({
    required String gameId,
    required String name,
    required GameState gameState,
    required String version,
    DateTime? createdAt,
  }) {
    final now = DateTime.now();
    return CloudGameSave(
      gameId: gameId,
      name: name,
      createdAt: createdAt ?? now,
      updatedAt: now,
      lastPlayedAt: now,
      version: version,
      syncTimestamp: now.millisecondsSinceEpoch,
      player: gameState.player,
      city: gameState.city,
      cityName: gameState.cityName,
    );
  }

  /// Creer depuis Firestore
  factory CloudGameSave.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return CloudGameSave(
      gameId: doc.id,
      name: data['name'] as String? ?? 'Partie sans nom',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastPlayedAt: (data['lastPlayedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      version: data['version'] as String? ?? '1.0.0',
      syncTimestamp: data['syncTimestamp'] as int? ?? 0,
      player: PlayerModel.fromJson(data['player'] as Map<String, dynamic>? ?? {}),
      city: CityModel.fromJson(data['city'] as Map<String, dynamic>? ?? {}),
      cityName: data['cityName'] as String? ?? 'Ma Ville',
      objectives: data['objectives'] as Map<String, dynamic>?,
      shopData: data['shopData'] as Map<String, dynamic>?,
      settings: data['settings'] as Map<String, dynamic>?,
    );
  }

  /// Convertir en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastPlayedAt': Timestamp.fromDate(lastPlayedAt),
      'version': version,
      'syncTimestamp': syncTimestamp,
      'player': player.toJson(),
      'city': city.toJson(),
      'cityName': cityName,
      if (objectives != null) 'objectives': objectives,
      if (shopData != null) 'shopData': shopData,
      if (settings != null) 'settings': settings,
    };
  }

  /// Convertir en GameState pour le jeu
  GameState toGameState() {
    return GameState(
      player: player,
      city: city,
      cityName: cityName,
    );
  }

  /// Copie avec modifications
  CloudGameSave copyWith({
    String? gameId,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastPlayedAt,
    String? version,
    int? syncTimestamp,
    PlayerModel? player,
    CityModel? city,
    String? cityName,
    Map<String, dynamic>? objectives,
    Map<String, dynamic>? shopData,
    Map<String, dynamic>? settings,
  }) {
    return CloudGameSave(
      gameId: gameId ?? this.gameId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      version: version ?? this.version,
      syncTimestamp: syncTimestamp ?? this.syncTimestamp,
      player: player ?? this.player,
      city: city ?? this.city,
      cityName: cityName ?? this.cityName,
      objectives: objectives ?? this.objectives,
      shopData: shopData ?? this.shopData,
      settings: settings ?? this.settings,
    );
  }

  @override
  String toString() {
    return 'CloudGameSave(gameId: $gameId, name: $name, money: ${player.money})';
  }
}

/// Element dans la queue de synchronisation offline
class SyncQueueItem {
  final String id;
  final String gameId;
  final SyncAction action;
  final DateTime createdAt;
  final Map<String, dynamic> data;
  final int retryCount;

  SyncQueueItem({
    required this.id,
    required this.gameId,
    required this.action,
    required this.createdAt,
    required this.data,
    this.retryCount = 0,
  });

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) {
    return SyncQueueItem(
      id: json['id'] as String,
      gameId: json['gameId'] as String,
      action: SyncAction.values[json['action'] as int],
      createdAt: DateTime.parse(json['createdAt'] as String),
      data: json['data'] as Map<String, dynamic>,
      retryCount: json['retryCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gameId': gameId,
      'action': action.index,
      'createdAt': createdAt.toIso8601String(),
      'data': data,
      'retryCount': retryCount,
    };
  }

  SyncQueueItem incrementRetry() {
    return SyncQueueItem(
      id: id,
      gameId: gameId,
      action: action,
      createdAt: createdAt,
      data: data,
      retryCount: retryCount + 1,
    );
  }
}

/// Types d'actions de synchronisation
enum SyncAction {
  create,
  update,
  delete,
}
