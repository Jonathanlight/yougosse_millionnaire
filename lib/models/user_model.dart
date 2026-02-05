import 'package:cloud_firestore/cloud_firestore.dart';

/// Modele utilisateur pour Firebase Auth + Firestore
class UserModel {
  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final int totalGamesCreated;
  final String authProvider; // 'email', 'google', 'apple'
  final bool isAnonymous;

  UserModel({
    required this.id,
    this.email,
    this.displayName,
    this.photoUrl,
    required this.createdAt,
    required this.lastLoginAt,
    this.totalGamesCreated = 0,
    this.authProvider = 'email',
    this.isAnonymous = false,
  });

  /// Creer depuis Firebase User + donnees Firestore
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document vide');
    }

    return UserModel(
      id: doc.id,
      email: data['email'] as String?,
      displayName: data['displayName'] as String?,
      photoUrl: data['photoUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalGamesCreated: data['totalGamesCreated'] as int? ?? 0,
      authProvider: data['authProvider'] as String? ?? 'email',
      isAnonymous: data['isAnonymous'] as bool? ?? false,
    );
  }

  /// Convertir en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      'totalGamesCreated': totalGamesCreated,
      'authProvider': authProvider,
      'isAnonymous': isAnonymous,
    };
  }

  /// Convertir en JSON pour le cache local
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'totalGamesCreated': totalGamesCreated,
      'authProvider': authProvider,
      'isAnonymous': isAnonymous,
    };
  }

  /// Créer depuis JSON (cache local)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLoginAt: DateTime.parse(json['lastLoginAt'] as String),
      totalGamesCreated: json['totalGamesCreated'] as int? ?? 0,
      authProvider: json['authProvider'] as String? ?? 'local',
      isAnonymous: json['isAnonymous'] as bool? ?? true,
    );
  }

  /// Copie avec modifications
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    int? totalGamesCreated,
    String? authProvider,
    bool? isAnonymous,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      totalGamesCreated: totalGamesCreated ?? this.totalGamesCreated,
      authProvider: authProvider ?? this.authProvider,
      isAnonymous: isAnonymous ?? this.isAnonymous,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, displayName: $displayName)';
  }
}
