import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import '../models/user_model.dart';

/// Etats d'authentification possibles
enum AuthState {
  /// Mode invité local - aucun appel Firebase, UUID local
  guestLocal,

  /// Mode invité Firebase - compte anonyme Firebase
  guestFirebase,

  /// Utilisateur authentifié (email, Google, Apple)
  authenticated,
}

/// Resultat d'une operation d'authentification
class AuthResult {
  final bool success;
  final UserModel? user;
  final String? errorMessage;
  final String? errorCode;

  AuthResult.success(this.user)
      : success = true,
        errorMessage = null,
        errorCode = null;

  AuthResult.failure(this.errorMessage, {this.errorCode})
      : success = false,
        user = null;
}

/// Service d'authentification avec fallback local robuste
class AuthService extends ChangeNotifier {
  // Clés SharedPreferences
  static const String _localUserIdKey = 'local_user_id';
  static const String _localUserNameKey = 'local_user_name';
  static const String _authStateKey = 'auth_state';

  // Firebase instances (lazy access)
  FirebaseAuth? _authInstance;
  FirebaseFirestore? _firestoreInstance;
  GoogleSignIn? _googleSignInInstance;

  FirebaseAuth get _auth {
    _authInstance ??= FirebaseAuth.instance;
    return _authInstance!;
  }

  FirebaseFirestore get _firestore {
    _firestoreInstance ??= FirebaseFirestore.instance;
    return _firestoreInstance!;
  }

  GoogleSignIn get _googleSignIn {
    _googleSignInInstance ??= GoogleSignIn();
    return _googleSignInInstance!;
  }

  // Etat interne
  User? _firebaseUser;
  UserModel? _currentUser;
  StreamSubscription<User?>? _authSubscription;
  bool _isInitialized = false;
  AuthState _authState = AuthState.guestLocal;
  String? _localUserId;
  bool _firebaseAvailable = false;

  // Getters
  User? get firebaseUser => _firebaseUser;
  UserModel? get currentUser => _currentUser;
  AuthState get authState => _authState;
  bool get isInitialized => _isInitialized;

  /// L'utilisateur est-il authentifié (compte permanent) ?
  bool get isAuthenticated => _authState == AuthState.authenticated;

  /// L'utilisateur est-il en mode invité (local ou Firebase) ?
  bool get isGuest =>
      _authState == AuthState.guestLocal ||
      _authState == AuthState.guestFirebase;

  /// L'utilisateur est-il en mode local pur (sans Firebase) ?
  bool get isLocalOnly => _authState == AuthState.guestLocal;

  /// ID utilisateur (Firebase UID ou UUID local)
  String? get userId {
    if (_firebaseUser != null) return _firebaseUser!.uid;
    return _localUserId;
  }

  /// Nom d'affichage
  String get displayName {
    if (_currentUser?.displayName != null) return _currentUser!.displayName!;
    if (_firebaseUser?.displayName != null) return _firebaseUser!.displayName!;
    return 'Joueur';
  }

  /// Firebase est-il disponible ?
  bool get isFirebaseAvailable => _firebaseAvailable;

  /// Initialiser le service en mode invité local (pas d'appel Firebase)
  /// C'est l'état par défaut au lancement de l'app
  Future<void> initializeAsGuest() async {
    if (_isInitialized) return;

    debugPrint('[AuthService] Initialisation en mode invité local...');

    try {
      // Charger ou créer l'ID utilisateur local
      final prefs = await SharedPreferences.getInstance();
      _localUserId = prefs.getString(_localUserIdKey);

      if (_localUserId == null) {
        _localUserId = const Uuid().v4();
        await prefs.setString(_localUserIdKey, _localUserId!);
        debugPrint('[AuthService] Nouvel ID local créé: $_localUserId');
      }

      // Charger le nom local si existant
      final localName = prefs.getString(_localUserNameKey);

      // Créer un UserModel local
      _currentUser = UserModel(
        id: _localUserId!,
        displayName: localName ?? 'Joueur',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        totalGamesCreated: 0,
        authProvider: 'local',
        isAnonymous: true,
      );

      _authState = AuthState.guestLocal;
      _isInitialized = true;

      debugPrint('[AuthService] Mode invité local initialisé - ID: $_localUserId');
      notifyListeners();
    } catch (e) {
      debugPrint('[AuthService] Erreur init guest: $e');
      // Même en cas d'erreur, on continue avec un ID temporaire
      _localUserId = const Uuid().v4();
      _authState = AuthState.guestLocal;
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Tenter de se connecter à Firebase (appelé en arrière-plan après le lancement)
  Future<void> tryConnectFirebase() async {
    try {
      debugPrint('[AuthService] Tentative connexion Firebase...');

      // Vérifier si un utilisateur Firebase est déjà connecté
      final currentUser = _auth.currentUser;

      if (currentUser != null) {
        _firebaseUser = currentUser;
        _firebaseAvailable = true;

        // Charger le profil Firestore
        await _loadUserProfile();

        // Déterminer l'état
        if (currentUser.isAnonymous) {
          _authState = AuthState.guestFirebase;
        } else {
          _authState = AuthState.authenticated;
        }

        debugPrint('[AuthService] Utilisateur Firebase restauré: ${currentUser.uid}');
      } else {
        _firebaseAvailable = true;
        debugPrint('[AuthService] Firebase disponible, pas d\'utilisateur connecté');
      }

      // Écouter les changements d'auth
      _authSubscription = _auth.authStateChanges().listen(_onAuthStateChanged);

      notifyListeners();
    } catch (e) {
      debugPrint('[AuthService] Firebase non disponible: $e');
      _firebaseAvailable = false;
      // On reste en mode local, pas de crash
    }
  }

  /// Callback lors des changements d'etat d'auth Firebase
  Future<void> _onAuthStateChanged(User? user) async {
    _firebaseUser = user;

    if (user != null) {
      await _loadUserProfile();

      if (user.isAnonymous) {
        _authState = AuthState.guestFirebase;
      } else {
        _authState = AuthState.authenticated;
      }
    } else if (_localUserId != null) {
      // Retour en mode local
      _authState = AuthState.guestLocal;
    }

    notifyListeners();
  }

  /// Charger le profil utilisateur depuis Firestore
  Future<void> _loadUserProfile() async {
    if (_firebaseUser == null) return;

    try {
      final doc =
          await _firestore.collection('users').doc(_firebaseUser!.uid).get();

      if (doc.exists) {
        _currentUser = UserModel.fromFirestore(doc);
        await _updateLastLogin();
      }
    } catch (e) {
      debugPrint('[AuthService] Erreur chargement profil: $e');
      // On continue sans profil Firestore
    }
  }

  /// Mettre a jour la date de derniere connexion
  Future<void> _updateLastLogin() async {
    if (_firebaseUser == null) return;

    try {
      await _firestore.collection('users').doc(_firebaseUser!.uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[AuthService] Erreur mise a jour lastLogin: $e');
    }
  }

  /// Creer le profil utilisateur dans Firestore
  Future<void> _createUserProfile({
    required String provider,
    String? displayName,
    String? photoUrl,
  }) async {
    if (_firebaseUser == null) return;

    try {
      final now = DateTime.now();
      final user = UserModel(
        id: _firebaseUser!.uid,
        email: _firebaseUser!.email,
        displayName: displayName ?? _firebaseUser!.displayName,
        photoUrl: photoUrl ?? _firebaseUser!.photoURL,
        createdAt: now,
        lastLoginAt: now,
        totalGamesCreated: 0,
        authProvider: provider,
        isAnonymous: _firebaseUser!.isAnonymous,
      );

      await _firestore.collection('users').doc(_firebaseUser!.uid).set(
            user.toFirestore(),
            SetOptions(merge: true),
          );

      _currentUser = user;
    } catch (e) {
      debugPrint('[AuthService] Erreur création profil: $e');
    }
  }

  // ==================== CONNEXION GOOGLE ====================

  /// Connexion avec Google
  Future<AuthResult> signInWithGoogle() async {
    if (!_firebaseAvailable) {
      return AuthResult.failure(
        'Connexion impossible. Vérifiez votre connexion internet.',
      );
    }

    try {
      debugPrint('[AuthService] Démarrage Google Sign-In...');

      // Déclencher le flow de connexion Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return AuthResult.failure('Connexion annulée');
      }

      debugPrint('[AuthService] Google user: ${googleUser.email}');

      // Obtenir les details d'auth
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Creer les credentials Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Connexion Firebase
      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        _firebaseUser = userCredential.user;
        await _loadUserProfile();

        // Creer le profil s'il n'existe pas
        if (_currentUser == null || _currentUser!.id != _firebaseUser!.uid) {
          await _createUserProfile(
            provider: 'google',
            displayName: googleUser.displayName,
            photoUrl: googleUser.photoUrl,
          );
        }

        _authState = AuthState.authenticated;
        notifyListeners();

        debugPrint('[AuthService] Connexion Google réussie');
        return AuthResult.success(_currentUser);
      }

      return AuthResult.failure('Erreur lors de la connexion Google');
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthService] FirebaseAuthException: ${e.code} - ${e.message}');
      return AuthResult.failure(
        _getErrorMessage(e.code),
        errorCode: e.code,
      );
    } catch (e) {
      debugPrint('[AuthService] Erreur Google Sign-In: $e');
      return AuthResult.failure(
        'Connexion impossible. Réessayez plus tard.',
      );
    }
  }

  // ==================== CONNEXION EMAIL ====================

  /// Inscription avec email et mot de passe
  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (!_firebaseAvailable) {
      return AuthResult.failure(
        'Inscription impossible. Vérifiez votre connexion internet.',
      );
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        _firebaseUser = credential.user;

        if (displayName != null) {
          await credential.user!.updateDisplayName(displayName);
        }

        await _createUserProfile(
          provider: 'email',
          displayName: displayName,
        );

        _authState = AuthState.authenticated;
        notifyListeners();

        return AuthResult.success(_currentUser);
      }

      return AuthResult.failure('Erreur lors de l\'inscription');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(
        _getErrorMessage(e.code),
        errorCode: e.code,
      );
    } catch (e) {
      return AuthResult.failure('Erreur inattendue. Réessayez plus tard.');
    }
  }

  /// Connexion avec email et mot de passe
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (!_firebaseAvailable) {
      return AuthResult.failure(
        'Connexion impossible. Vérifiez votre connexion internet.',
      );
    }

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        _firebaseUser = credential.user;
        await _loadUserProfile();

        if (_currentUser == null) {
          await _createUserProfile(provider: 'email');
        }

        _authState = AuthState.authenticated;
        notifyListeners();

        return AuthResult.success(_currentUser);
      }

      return AuthResult.failure('Erreur lors de la connexion');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(
        _getErrorMessage(e.code),
        errorCode: e.code,
      );
    } catch (e) {
      return AuthResult.failure('Erreur inattendue. Réessayez plus tard.');
    }
  }

  // ==================== CONNEXION APPLE ====================

  /// Connexion avec Apple (iOS uniquement)
  Future<AuthResult> signInWithApple() async {
    if (!Platform.isIOS && !Platform.isMacOS) {
      return AuthResult.failure(
          'Apple Sign-In disponible uniquement sur iOS/macOS');
    }

    if (!_firebaseAvailable) {
      return AuthResult.failure(
        'Connexion impossible. Vérifiez votre connexion internet.',
      );
    }

    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);

      if (userCredential.user != null) {
        _firebaseUser = userCredential.user;

        String? displayName;
        if (appleCredential.givenName != null ||
            appleCredential.familyName != null) {
          displayName =
              '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'
                  .trim();
        }

        await _loadUserProfile();

        if (_currentUser == null) {
          await _createUserProfile(
            provider: 'apple',
            displayName: displayName,
          );
        }

        _authState = AuthState.authenticated;
        notifyListeners();

        return AuthResult.success(_currentUser);
      }

      return AuthResult.failure('Erreur lors de la connexion Apple');
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return AuthResult.failure('Connexion annulée');
      }
      return AuthResult.failure('Erreur Apple Sign-In. Réessayez plus tard.');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(
        _getErrorMessage(e.code),
        errorCode: e.code,
      );
    } catch (e) {
      return AuthResult.failure('Erreur inattendue. Réessayez plus tard.');
    }
  }

  // ==================== MODE INVITE FIREBASE ====================

  /// Passer en mode invité Firebase (compte anonyme)
  Future<AuthResult> signInAnonymously() async {
    if (!_firebaseAvailable) {
      // Fallback: rester en mode local
      debugPrint('[AuthService] Firebase non dispo, reste en mode local');
      return AuthResult.success(_currentUser);
    }

    try {
      final credential = await _auth.signInAnonymously();

      if (credential.user != null) {
        _firebaseUser = credential.user;
        await _createUserProfile(
          provider: 'anonymous',
          displayName: 'Joueur Invité',
        );

        _authState = AuthState.guestFirebase;
        notifyListeners();

        return AuthResult.success(_currentUser);
      }

      return AuthResult.failure('Erreur lors de la connexion anonyme');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(
        _getErrorMessage(e.code),
        errorCode: e.code,
      );
    } catch (e) {
      // Fallback: rester en mode local
      debugPrint('[AuthService] Erreur anonyme, reste en mode local: $e');
      return AuthResult.success(_currentUser);
    }
  }

  // ==================== LIAISON DE COMPTE ====================

  /// Convertir un compte invité en compte Google
  Future<AuthResult> linkWithGoogle() async {
    if (_authState == AuthState.authenticated) {
      return AuthResult.failure('Déjà connecté avec un compte');
    }

    if (!_firebaseAvailable) {
      return AuthResult.failure(
        'Connexion impossible. Vérifiez votre connexion internet.',
      );
    }

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return AuthResult.failure('Connexion annulée');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Si on est en mode local, créer d'abord un compte anonyme
      if (_authState == AuthState.guestLocal) {
        final anonResult = await _auth.signInAnonymously();
        _firebaseUser = anonResult.user;
      }

      if (_firebaseUser != null) {
        final userCredential =
            await _firebaseUser!.linkWithCredential(credential);

        if (userCredential.user != null) {
          await _firestore.collection('users').doc(_firebaseUser!.uid).update({
            'email': googleUser.email,
            'displayName': googleUser.displayName,
            'photoUrl': googleUser.photoUrl,
            'isAnonymous': false,
            'authProvider': 'google',
          });

          await _loadUserProfile();
          _authState = AuthState.authenticated;
          notifyListeners();

          return AuthResult.success(_currentUser);
        }
      }

      // Fallback: connexion directe si link échoue
      return await signInWithGoogle();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        // Le compte Google existe déjà, se connecter directement
        return await signInWithGoogle();
      }
      return AuthResult.failure(
        _getErrorMessage(e.code),
        errorCode: e.code,
      );
    } catch (e) {
      return AuthResult.failure('Erreur. Réessayez plus tard.');
    }
  }

  /// Convertir un compte invité en compte email
  Future<AuthResult> linkWithEmail({
    required String email,
    required String password,
  }) async {
    if (_authState == AuthState.authenticated) {
      return AuthResult.failure('Déjà connecté avec un compte');
    }

    if (!_firebaseAvailable) {
      return AuthResult.failure(
        'Connexion impossible. Vérifiez votre connexion internet.',
      );
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      // Si on est en mode local, créer d'abord un compte anonyme
      if (_authState == AuthState.guestLocal) {
        final anonResult = await _auth.signInAnonymously();
        _firebaseUser = anonResult.user;
      }

      if (_firebaseUser != null) {
        final userCredential =
            await _firebaseUser!.linkWithCredential(credential);

        if (userCredential.user != null) {
          await _firestore.collection('users').doc(_firebaseUser!.uid).update({
            'email': email,
            'isAnonymous': false,
            'authProvider': 'email',
          });

          await _loadUserProfile();
          _authState = AuthState.authenticated;
          notifyListeners();

          return AuthResult.success(_currentUser);
        }
      }

      return AuthResult.failure('Erreur lors de la liaison du compte');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(
        _getErrorMessage(e.code),
        errorCode: e.code,
      );
    } catch (e) {
      return AuthResult.failure('Erreur inattendue. Réessayez plus tard.');
    }
  }

  // ==================== MOT DE PASSE ====================

  /// Envoyer un email de reinitialisation du mot de passe
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    if (!_firebaseAvailable) {
      return AuthResult.failure(
        'Service indisponible. Vérifiez votre connexion internet.',
      );
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResult.success(null);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(
        _getErrorMessage(e.code),
        errorCode: e.code,
      );
    } catch (e) {
      return AuthResult.failure('Erreur inattendue. Réessayez plus tard.');
    }
  }

  // ==================== DECONNEXION ====================

  /// Deconnexion - retour en mode invité local
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint('[AuthService] Erreur deconnexion: $e');
    }

    _firebaseUser = null;

    // Recréer un utilisateur local
    _currentUser = UserModel(
      id: _localUserId ?? const Uuid().v4(),
      displayName: 'Joueur',
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      totalGamesCreated: 0,
      authProvider: 'local',
      isAnonymous: true,
    );

    _authState = AuthState.guestLocal;
    notifyListeners();

    debugPrint('[AuthService] Déconnexion réussie, retour en mode local');
  }

  /// Supprimer le compte
  Future<AuthResult> deleteAccount() async {
    if (_firebaseUser == null) {
      return AuthResult.failure('Aucun compte à supprimer');
    }

    try {
      final batch = _firestore.batch();

      final gamesQuery = await _firestore
          .collection('users')
          .doc(_firebaseUser!.uid)
          .collection('games')
          .get();

      for (final doc in gamesQuery.docs) {
        batch.delete(doc.reference);
      }

      batch.delete(_firestore.collection('users').doc(_firebaseUser!.uid));

      await batch.commit();
      await _firebaseUser!.delete();

      // Retour en mode local
      await signOut();

      return AuthResult.success(null);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(
        _getErrorMessage(e.code),
        errorCode: e.code,
      );
    } catch (e) {
      return AuthResult.failure('Erreur inattendue. Réessayez plus tard.');
    }
  }

  // ==================== UTILITAIRES ====================

  /// Met à jour le nom d'affichage local
  Future<void> updateLocalDisplayName(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localUserNameKey, name);

      _currentUser = _currentUser?.copyWith(displayName: name) ??
          UserModel(
            id: _localUserId ?? '',
            displayName: name,
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
            totalGamesCreated: 0,
            authProvider: 'local',
            isAnonymous: true,
          );

      notifyListeners();
    } catch (e) {
      debugPrint('[AuthService] Erreur update nom: $e');
    }
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = List.generate(
        length, (_) => charset[DateTime.now().microsecondsSinceEpoch % charset.length]);
    return random.join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Aucun compte trouvé avec cet email';
      case 'wrong-password':
        return 'Mot de passe incorrect';
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé';
      case 'weak-password':
        return 'Le mot de passe est trop faible (min. 6 caractères)';
      case 'invalid-email':
        return 'Email invalide';
      case 'user-disabled':
        return 'Ce compte a été désactivé';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard';
      case 'operation-not-allowed':
        return 'Opération non autorisée';
      case 'network-request-failed':
        return 'Erreur réseau. Vérifiez votre connexion';
      case 'requires-recent-login':
        return 'Veuillez vous reconnecter pour effectuer cette action';
      case 'credential-already-in-use':
        return 'Ce compte est déjà lié à un autre utilisateur';
      case 'sign_in_failed':
        return 'Connexion impossible. Vérifiez votre configuration Google.';
      default:
        return 'Erreur de connexion. Réessayez plus tard.';
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

/// Instance globale du service d'authentification
final authService = AuthService();
