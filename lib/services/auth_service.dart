import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/user_model.dart';

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

/// Service d'authentification Firebase
class AuthService extends ChangeNotifier {
  // Lazy access to avoid accessing Firebase before initialization
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? _firebaseUser;
  UserModel? _currentUser;
  StreamSubscription<User?>? _authSubscription;
  bool _isInitialized = false;

  // Getters
  User? get firebaseUser => _firebaseUser;
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _firebaseUser != null;
  bool get isAnonymous => _firebaseUser?.isAnonymous ?? false;
  String? get userId => _firebaseUser?.uid;
  bool get isInitialized => _isInitialized;

  /// Initialiser le service et ecouter les changements d'auth
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Ecouter les changements d'authentification
    _authSubscription = _auth.authStateChanges().listen(_onAuthStateChanged);

    // Verifier si un utilisateur est deja connecte
    _firebaseUser = _auth.currentUser;
    if (_firebaseUser != null) {
      await _loadUserProfile();
    }

    _isInitialized = true;
    debugPrint('[AuthService] Initialise - User: ${_firebaseUser?.uid}');
  }

  /// Callback lors des changements d'etat d'auth
  Future<void> _onAuthStateChanged(User? user) async {
    _firebaseUser = user;

    if (user != null) {
      await _loadUserProfile();
    } else {
      _currentUser = null;
    }

    notifyListeners();
  }

  /// Charger le profil utilisateur depuis Firestore
  Future<void> _loadUserProfile() async {
    if (_firebaseUser == null) return;

    try {
      final doc = await _firestore.collection('users').doc(_firebaseUser!.uid).get();

      if (doc.exists) {
        _currentUser = UserModel.fromFirestore(doc);
        // Mettre a jour lastLoginAt
        await _updateLastLogin();
      }
    } catch (e) {
      debugPrint('[AuthService] Erreur chargement profil: $e');
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
  }

  // ==================== INSCRIPTION / CONNEXION EMAIL ====================

  /// Inscription avec email et mot de passe
  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Mettre a jour le nom d'affichage si fourni
        if (displayName != null) {
          await credential.user!.updateDisplayName(displayName);
        }

        await _createUserProfile(
          provider: 'email',
          displayName: displayName,
        );

        return AuthResult.success(_currentUser);
      }

      return AuthResult.failure('Erreur lors de l\'inscription');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(
        _getErrorMessage(e.code),
        errorCode: e.code,
      );
    } catch (e) {
      return AuthResult.failure('Erreur inattendue: $e');
    }
  }

  /// Connexion avec email et mot de passe
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await _loadUserProfile();

        // Creer le profil s'il n'existe pas (migration)
        if (_currentUser == null) {
          await _createUserProfile(provider: 'email');
        }

        return AuthResult.success(_currentUser);
      }

      return AuthResult.failure('Erreur lors de la connexion');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(
        _getErrorMessage(e.code),
        errorCode: e.code,
      );
    } catch (e) {
      return AuthResult.failure('Erreur inattendue: $e');
    }
  }

  // ==================== CONNEXION GOOGLE ====================

  /// Connexion avec Google
  Future<AuthResult> signInWithGoogle() async {
    try {
      // Declencher le flow de connexion Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return AuthResult.failure('Connexion Google annulee');
      }

      // Obtenir les details d'auth
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Creer les credentials Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Connexion Firebase
      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        await _loadUserProfile();

        // Creer le profil s'il n'existe pas
        if (_currentUser == null) {
          await _createUserProfile(
            provider: 'google',
            displayName: googleUser.displayName,
            photoUrl: googleUser.photoUrl,
          );
        }

        return AuthResult.success(_currentUser);
      }

      return AuthResult.failure('Erreur lors de la connexion Google');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(
        _getErrorMessage(e.code),
        errorCode: e.code,
      );
    } catch (e) {
      return AuthResult.failure('Erreur Google Sign-In: $e');
    }
  }

  // ==================== CONNEXION APPLE ====================

  /// Connexion avec Apple (iOS uniquement)
  Future<AuthResult> signInWithApple() async {
    if (!Platform.isIOS && !Platform.isMacOS) {
      return AuthResult.failure('Apple Sign-In disponible uniquement sur iOS/macOS');
    }

    try {
      // Generer un nonce aleatoire pour la securite
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      // Demander les credentials Apple
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      // Creer les credentials Firebase
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      // Connexion Firebase
      final userCredential = await _auth.signInWithCredential(oauthCredential);

      if (userCredential.user != null) {
        // Apple ne renvoie le nom que lors de la premiere connexion
        String? displayName;
        if (appleCredential.givenName != null || appleCredential.familyName != null) {
          displayName = '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'.trim();
        }

        await _loadUserProfile();

        // Creer le profil s'il n'existe pas
        if (_currentUser == null) {
          await _createUserProfile(
            provider: 'apple',
            displayName: displayName,
          );
        }

        return AuthResult.success(_currentUser);
      }

      return AuthResult.failure('Erreur lors de la connexion Apple');
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return AuthResult.failure('Connexion Apple annulee');
      }
      return AuthResult.failure('Erreur Apple Sign-In: ${e.message}');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(
        _getErrorMessage(e.code),
        errorCode: e.code,
      );
    } catch (e) {
      return AuthResult.failure('Erreur Apple Sign-In: $e');
    }
  }

  // ==================== MODE INVITE ====================

  /// Connexion anonyme (mode invite)
  Future<AuthResult> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();

      if (credential.user != null) {
        await _createUserProfile(
          provider: 'anonymous',
          displayName: 'Joueur Invite',
        );

        return AuthResult.success(_currentUser);
      }

      return AuthResult.failure('Erreur lors de la connexion anonyme');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(
        _getErrorMessage(e.code),
        errorCode: e.code,
      );
    } catch (e) {
      return AuthResult.failure('Erreur inattendue: $e');
    }
  }

  /// Convertir un compte anonyme en compte permanent
  Future<AuthResult> linkWithEmail({
    required String email,
    required String password,
  }) async {
    if (_firebaseUser == null || !_firebaseUser!.isAnonymous) {
      return AuthResult.failure('Utilisateur non anonyme');
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      final userCredential = await _firebaseUser!.linkWithCredential(credential);

      if (userCredential.user != null) {
        // Mettre a jour le profil
        await _firestore.collection('users').doc(_firebaseUser!.uid).update({
          'email': email,
          'isAnonymous': false,
          'authProvider': 'email',
        });

        await _loadUserProfile();
        return AuthResult.success(_currentUser);
      }

      return AuthResult.failure('Erreur lors de la liaison du compte');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(
        _getErrorMessage(e.code),
        errorCode: e.code,
      );
    } catch (e) {
      return AuthResult.failure('Erreur inattendue: $e');
    }
  }

  /// Convertir un compte anonyme avec Google
  Future<AuthResult> linkWithGoogle() async {
    if (_firebaseUser == null || !_firebaseUser!.isAnonymous) {
      return AuthResult.failure('Utilisateur non anonyme');
    }

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return AuthResult.failure('Connexion Google annulee');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseUser!.linkWithCredential(credential);

      if (userCredential.user != null) {
        await _firestore.collection('users').doc(_firebaseUser!.uid).update({
          'email': googleUser.email,
          'displayName': googleUser.displayName,
          'photoUrl': googleUser.photoUrl,
          'isAnonymous': false,
          'authProvider': 'google',
        });

        await _loadUserProfile();
        return AuthResult.success(_currentUser);
      }

      return AuthResult.failure('Erreur lors de la liaison du compte');
    } catch (e) {
      return AuthResult.failure('Erreur: $e');
    }
  }

  // ==================== GESTION MOT DE PASSE ====================

  /// Envoyer un email de reinitialisation du mot de passe
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResult.success(null);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(
        _getErrorMessage(e.code),
        errorCode: e.code,
      );
    } catch (e) {
      return AuthResult.failure('Erreur inattendue: $e');
    }
  }

  /// Changer le mot de passe
  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_firebaseUser == null || _firebaseUser!.email == null) {
      return AuthResult.failure('Utilisateur non connecte');
    }

    try {
      // Re-authentifier l'utilisateur
      final credential = EmailAuthProvider.credential(
        email: _firebaseUser!.email!,
        password: currentPassword,
      );

      await _firebaseUser!.reauthenticateWithCredential(credential);

      // Changer le mot de passe
      await _firebaseUser!.updatePassword(newPassword);

      return AuthResult.success(_currentUser);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(
        _getErrorMessage(e.code),
        errorCode: e.code,
      );
    } catch (e) {
      return AuthResult.failure('Erreur inattendue: $e');
    }
  }

  // ==================== DECONNEXION ====================

  /// Deconnexion
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      _currentUser = null;
      notifyListeners();
      debugPrint('[AuthService] Deconnexion reussie');
    } catch (e) {
      debugPrint('[AuthService] Erreur deconnexion: $e');
    }
  }

  /// Supprimer le compte
  Future<AuthResult> deleteAccount() async {
    if (_firebaseUser == null) {
      return AuthResult.failure('Utilisateur non connecte');
    }

    try {
      // Supprimer les donnees Firestore
      final batch = _firestore.batch();

      // Supprimer les parties
      final gamesQuery = await _firestore
          .collection('users')
          .doc(_firebaseUser!.uid)
          .collection('games')
          .get();

      for (final doc in gamesQuery.docs) {
        batch.delete(doc.reference);
      }

      // Supprimer le profil
      batch.delete(_firestore.collection('users').doc(_firebaseUser!.uid));

      await batch.commit();

      // Supprimer le compte Firebase Auth
      await _firebaseUser!.delete();

      _currentUser = null;
      notifyListeners();

      return AuthResult.success(null);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(
        _getErrorMessage(e.code),
        errorCode: e.code,
      );
    } catch (e) {
      return AuthResult.failure('Erreur inattendue: $e');
    }
  }

  // ==================== UTILITAIRES ====================

  /// Generer un nonce aleatoire pour Apple Sign-In
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = List.generate(length, (_) => charset[DateTime.now().microsecondsSinceEpoch % charset.length]);
    return random.join();
  }

  /// Hash SHA256 pour le nonce
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Convertir les codes d'erreur Firebase en messages francais
  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Aucun compte trouve avec cet email';
      case 'wrong-password':
        return 'Mot de passe incorrect';
      case 'email-already-in-use':
        return 'Cet email est deja utilise';
      case 'weak-password':
        return 'Le mot de passe est trop faible (min. 6 caracteres)';
      case 'invalid-email':
        return 'Email invalide';
      case 'user-disabled':
        return 'Ce compte a ete desactive';
      case 'too-many-requests':
        return 'Trop de tentatives. Reessayez plus tard';
      case 'operation-not-allowed':
        return 'Operation non autorisee';
      case 'network-request-failed':
        return 'Erreur reseau. Verifiez votre connexion';
      case 'requires-recent-login':
        return 'Veuillez vous reconnecter pour effectuer cette action';
      case 'credential-already-in-use':
        return 'Ces identifiants sont deja lies a un autre compte';
      default:
        return 'Erreur d\'authentification ($code)';
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
