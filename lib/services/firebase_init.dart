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

  /// Verifier si Firebase est initialise
  static bool get isInitialized => _isInitialized;

  /// Initialiser Firebase et les services cloud
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Initialiser Firebase
      debugPrint('[FirebaseInit] Initialisation Firebase...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // 2. Initialiser Hive pour le cache local
      debugPrint('[FirebaseInit] Initialisation Hive...');
      await Hive.initFlutter();

      // 3. Initialiser le service de connectivite
      debugPrint('[FirebaseInit] Initialisation ConnectivityService...');
      await connectivityService.initialize();

      // 4. Initialiser le service d'authentification
      debugPrint('[FirebaseInit] Initialisation AuthService...');
      authService.initialize();

      // 5. Initialiser le service de synchronisation
      debugPrint('[FirebaseInit] Initialisation SyncService...');
      await syncService.initialize();

      _isInitialized = true;
      debugPrint('[FirebaseInit] Initialisation complete');
    } catch (e) {
      debugPrint('[FirebaseInit] Erreur initialisation: $e');
      // En cas d'erreur, on continue en mode offline
      _isInitialized = true;
    }
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
          debugPrint('[FirebaseInit] Migration reussie: ${result.migratedGameId}');
        }
      }
    } catch (e) {
      debugPrint('[FirebaseInit] Erreur migration: $e');
    }
  }
}
