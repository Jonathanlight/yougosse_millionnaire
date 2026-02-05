import 'package:flutter/material.dart';
import '../../game/data/game_state.dart';
import '../../services/auth_service.dart';
import '../../services/cloud_save_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/firebase_init.dart';
import '../../services/migration_service.dart';
import '../../services/sync_service.dart';
import 'auth_screen.dart';
import 'game_select_screen.dart';

/// Enum pour gerer l'etat de l'application
enum AppState {
  loading,
  auth,
  gameSelect,
  game,
}

/// Widget wrapper qui gere le flux d'authentification et la selection de partie
class AppWrapper extends StatefulWidget {
  final Widget Function(String? gameId, GameState? initialState) gameBuilder;

  const AppWrapper({
    super.key,
    required this.gameBuilder,
  });

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  AppState _state = AppState.loading;
  String? _currentGameId;
  GameState? _initialGameState;
  String _loadingMessage = 'Chargement...';
  bool _showMigrationProgress = false;
  double _migrationProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Initialiser Firebase et services
      setState(() {
        _loadingMessage = 'Connexion aux services...';
      });
      await FirebaseInit.initialize();

      // Ecouter les changements d'authentification
      authService.addListener(_onAuthStateChanged);

      // Verifier l'etat d'authentification
      if (authService.isAuthenticated) {
        await _handleAuthenticatedUser();
      } else {
        setState(() {
          _state = AppState.auth;
        });
      }
    } catch (e) {
      debugPrint('[AppWrapper] Erreur initialisation: $e');
      // En cas d'erreur, aller a l'ecran d'auth
      setState(() {
        _state = AppState.auth;
      });
    }
  }

  void _onAuthStateChanged() {
    if (!mounted) return;

    if (!authService.isAuthenticated) {
      // Deconnexion - retour a l'ecran d'auth
      setState(() {
        _state = AppState.auth;
        _currentGameId = null;
        _initialGameState = null;
      });
    }
  }

  Future<void> _handleAuthenticatedUser() async {
    setState(() {
      _loadingMessage = 'Vérification des données...';
    });

    // Verifier si migration necessaire
    if (await migrationService.needsMigration()) {
      setState(() {
        _showMigrationProgress = true;
        _loadingMessage = 'Migration des données...';
      });

      // Ecouter la progression de la migration
      migrationService.addListener(_onMigrationProgress);

      final result = await migrationService.migrate();

      migrationService.removeListener(_onMigrationProgress);

      if (result.success && result.migratedGameId != null) {
        // Charger directement la partie migree
        await _loadGame(result.migratedGameId!);
        return;
      }
    }

    // Verifier s'il y a une partie en cours
    final currentGameId = syncService.currentGameId;
    if (currentGameId != null) {
      await _loadGame(currentGameId);
    } else {
      // Aller a la selection de partie
      setState(() {
        _state = AppState.gameSelect;
        _showMigrationProgress = false;
      });
    }
  }

  void _onMigrationProgress() {
    if (!mounted) return;
    setState(() {
      _migrationProgress = migrationService.progress;
    });
  }

  Future<void> _loadGame(String gameId) async {
    setState(() {
      _loadingMessage = 'Chargement de la partie...';
      _showMigrationProgress = false;
    });

    try {
      GameState? gameState;

      // Essayer de charger depuis le cloud
      if (connectivityService.isOnline) {
        final result = await cloudSaveService.loadGame(gameId);
        if (result.success && result.save != null) {
          gameState = result.save!.toGameState();
        }
      }

      // Fallback sur le cache local
      gameState ??= await syncService.loadGameFromCache(gameId);

      // Si toujours null, creer un nouveau GameState
      gameState ??= GameState();

      await syncService.setCurrentGame(gameId);

      setState(() {
        _currentGameId = gameId;
        _initialGameState = gameState;
        _state = AppState.game;
      });
    } catch (e) {
      debugPrint('[AppWrapper] Erreur chargement partie: $e');
      // Aller a la selection
      setState(() {
        _state = AppState.gameSelect;
      });
    }
  }

  void _onAuthSuccess() {
    _handleAuthenticatedUser();
  }

  void _onGameSelected(String gameId) {
    _loadGame(gameId);
  }

  void _onNewGame() async {
    // Afficher dialog de creation
    final name = await _showCreateGameDialog();
    if (name == null || name.trim().isEmpty) return;

    setState(() {
      _state = AppState.loading;
      _loadingMessage = 'Création de la partie...';
    });

    try {
      final result = await cloudSaveService.createGame(name: name.trim());
      if (result.success && result.save != null) {
        await _loadGame(result.save!.gameId);
      } else {
        // Erreur - retour a la selection
        setState(() {
          _state = AppState.gameSelect;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.errorMessage ?? 'Erreur'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _state = AppState.gameSelect;
      });
    }
  }

  Future<String?> _showCreateGameDialog() async {
    final controller = TextEditingController(text: 'Ma Ville');

    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle partie'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Nom de votre ville',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  void _onLogout() {
    setState(() {
      _state = AppState.auth;
      _currentGameId = null;
      _initialGameState = null;
    });
  }

  void _onBackToGameSelect() {
    setState(() {
      _state = AppState.gameSelect;
      _currentGameId = null;
      _initialGameState = null;
    });
  }

  @override
  void dispose() {
    authService.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case AppState.loading:
        return _buildLoadingScreen();

      case AppState.auth:
        return AuthScreen(
          onAuthSuccess: _onAuthSuccess,
          onSkip: _onAuthSuccess, // Mode invite
        );

      case AppState.gameSelect:
        return GameSelectScreen(
          onGameSelected: _onGameSelected,
          onNewGame: _onNewGame,
          onLogout: _onLogout,
        );

      case AppState.game:
        return widget.gameBuilder(_currentGameId, _initialGameState);
    }
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1a237e),
              Color(0xFF0d47a1),
              Color(0xFF01579b),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.location_city,
                    size: 60,
                    color: Color(0xFF1a237e),
                  ),
                ),
                const SizedBox(height: 32),

                // Message
                Text(
                  _loadingMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),

                // Progress bar
                SizedBox(
                  width: 200,
                  child: Column(
                    children: [
                      if (_showMigrationProgress) ...[
                        LinearProgressIndicator(
                          value: _migrationProgress,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(_migrationProgress * 100).toInt()}%',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ] else ...[
                        const CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
