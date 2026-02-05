import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../firebase_options.dart';
import 'auth_service.dart';
import 'connectivity_service.dart';
import 'migration_service.dart';
import 'sync_service.dart';

/// Initialisation de tous les services Firebase et cloud
class FirebaseInit {
  static bool _isInitialized = false;
  static bool _firebaseInitialized = false;

  /// Verifier si Firebase est initialise
  static bool get isInitialized => _isInitialized;
  static bool get isFirebaseInitialized => _firebaseInitialized;

  /// Initialiser les services de base (sans Firebase)
  /// Permet au jeu de démarrer immédiatement en mode local
  static Future<void> initializeLocal() async {
    if (_isInitialized) return;

    try {
      // 1. Initialiser Hive pour le cache local
      debugPrint('[FirebaseInit] Initialisation Hive...');
      await Hive.initFlutter();

      // 2. Initialiser AuthService en mode guest local (pas d'appel Firebase)
      debugPrint('[FirebaseInit] Initialisation AuthService en mode local...');
      await authService.initializeAsGuest();

      _isInitialized = true;
      debugPrint('[FirebaseInit] Initialisation locale complete');
    } catch (e) {
      debugPrint('[FirebaseInit] Erreur initialisation locale: $e');
      // Même en cas d'erreur, on marque comme initialisé pour continuer
      _isInitialized = true;
    }
  }

  /// Initialiser Firebase en arrière-plan (après le lancement du jeu)
  /// Cette méthode ne bloque pas le démarrage de l'app
  static Future<void> initializeFirebaseInBackground() async {
    if (_firebaseInitialized) return;

    try {
      debugPrint('[FirebaseInit] Initialisation Firebase en arrière-plan...');

      // 1. Initialiser Firebase Core
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // 2. Initialiser le service de connectivité
      await connectivityService.initialize();

      // 3. Connecter AuthService à Firebase
      await authService.tryConnectFirebase();

      // 4. Initialiser le service de synchronisation
      await syncService.initialize();

      _firebaseInitialized = true;
      debugPrint('[FirebaseInit] Firebase initialisé avec succès');
    } catch (e) {
      debugPrint('[FirebaseInit] Erreur initialisation Firebase: $e');
      // On continue sans Firebase, l'app fonctionne en mode local
      _firebaseInitialized = false;
    }
  }

  /// Méthode legacy pour compatibilité - initialise tout
  static Future<void> initialize() async {
    await initializeLocal();
    // Firebase sera initialisé en arrière-plan
    initializeFirebaseInBackground();
  }

  /// Effectuer la migration automatique si necessaire
  static Future<void> performAutoMigration() async {
    if (!authService.isAuthenticated) return;
    if (!connectivityService.isOnline) return;

    try {
      final needsMigration = await migrationService.needsMigration();
      if (needsMigration) {
        debugPrint('[FirebaseInit] Migration automatique en cours...');
        final result = await migrationService.autoMigrate();
        if (result.success) {
          debugPrint(
              '[FirebaseInit] Migration reussie: ${result.migratedGameId}');
        }
      }
    } catch (e) {
      debugPrint('[FirebaseInit] Erreur migration: $e');
    }
  }
}
