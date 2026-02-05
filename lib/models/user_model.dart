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
