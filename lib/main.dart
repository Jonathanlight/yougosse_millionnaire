import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'game/city_game.dart';
import 'game/components/building.dart';
import 'game/data/game_state.dart';
import 'models/building_model.dart';
import 'services/audio_service.dart';
import 'services/objectives_service.dart';
import 'services/save_service.dart';
import 'services/weather_service.dart';
import 'ui/overlays/build_menu.dart';
import 'ui/overlays/building_info.dart';
import 'ui/overlays/daily_greeting_dialog.dart';
import 'ui/overlays/game_rules_overlay.dart';
import 'ui/overlays/hud_overlay.dart';
import 'ui/overlays/monthly_objectives_overlay.dart';
import 'ui/overlays/objectives_overlay.dart';
import 'ui/overlays/settings_overlay.dart';
import 'ui/overlays/weather_overlay.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Allow all orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Set fullscreen mode
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: [SystemUiOverlay.top],
  );

  runApp(
    const ProviderScope(
      child: MillionaireCityApp(),
    ),
  );
}

class MillionaireCityApp extends StatelessWidget {
  const MillionaireCityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yougosse Millionnaire',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

/// Splash screen with logo colors
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  String _loadingText = 'Chargement...';
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 3500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Step 1: Initialize save service
      setState(() {
        _loadingText = 'Chargement des données...';
        _progress = 0.2;
      });
      await saveService.initialize();

      // Step 2: Initialize audio service
      setState(() {
        _loadingText = 'Chargement audio...';
        _progress = 0.4;
      });
      await audioService.initialize();

      // Step 3: Preload building images
      setState(() {
        _loadingText = 'Chargement des images...';
        _progress = 0.6;
      });
      await BuildingComponent.loadBuildingImages();

      // Step 4: Final preparation
      setState(() {
        _loadingText = 'Préparation du jeu...';
        _progress = 0.9;
      });
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _loadingText = 'Prêt!';
        _progress = 1.0;
      });
      await Future.delayed(const Duration(milliseconds: 5000));

      // Navigate to game
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const GameScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    } catch (e) {
      print('Error during initialization: $e');
      setState(() {
        _loadingText = 'Erreur de chargement';
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Logo colors: Gold, Green (money), Blue (sky)
    const goldColor = Color(0xFFFFD700);
    const greenColor = Color(0xFF4CAF50);
    const darkBg = Color(0xFF1E1E1E);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              darkBg,
              const Color(0xFF2D2D2D),
              darkBg,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: goldColor.withValues(alpha: 0.3),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.asset(
                              'assets/logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback if logo doesn't load
                                return Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [goldColor, greenColor],
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: const Icon(
                                    Icons.location_city,
                                    size: 100,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Title with gradient
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [goldColor, greenColor],
                          ).createShader(bounds),
                          child: const Text(
                            'YOUGOSSE MILLIONNAIRE',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Construisez votre empire',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade400,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 60),

                        // Progress bar
                        SizedBox(
                          width: 200,
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: _progress,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey.shade800,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          goldColor),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _loadingText,
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late GameState _gameState;
  late CityGame _game;
  late WeatherService _weatherService;
  late ObjectivesService _objectivesService;

  bool _isLoading = true;
  bool _showBuildMenu = false;
  bool _showSettings = false;
  bool _showObjectives = false;
  bool _showGameRules = false;
  bool _showDailyGreeting = false;
  bool _showMonthlyObjectives = false;
  BuildingModel? _selectedBuilding;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _weatherService = WeatherService();
    _objectivesService = ObjectivesService();
    _initializeGame();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveGame();
    _weatherService.dispose();
    _objectivesService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _saveGame();
      audioService.pauseMusic();
    } else if (state == AppLifecycleState.resumed) {
      audioService.resumeMusic();
    }
  }

  Future<void> _initializeGame() async {
    // Try to load existing save
    final savedState = await saveService.loadGame();

    if (savedState != null) {
      _gameState = savedState;

      // Process daily credit payments (if any)
      final creditDeducted = _gameState.processCreditPayment();
      if (creditDeducted > 0) {
        // Show credit payment notification after build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showCreditPaymentDialog(creditDeducted);
        });
      }

      // Calculate offline earnings
      final offlineEarnings = _gameState.claimOfflineEarnings();
      if (offlineEarnings > 0) {
        // Show offline earnings dialog after build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showOfflineEarningsDialog(offlineEarnings);
        });
      }
    } else {
      _gameState = GameState();
    }

    // Initialize weather service
    _weatherService.initialize();

    // Initialize objectives service
    _objectivesService.initialize(null); // TODO: Load from save

    // Update objectives with current game state
    _updateObjectivesProgress();

    // Listen to game state changes for objectives
    _gameState.addListener(_updateObjectivesProgress);

    _game = CityGame(
      gameState: _gameState,
      weatherService: _weatherService,
      onSaveRequested: _saveGame,
      onBuildingInfoRequested: _onBuildingInfoRequested,
    );

    setState(() {
      _isLoading = false;
    });

    // Check if we should show daily greeting (after other dialogs)
    _checkDailyGreeting();
  }

  Future<void> _checkDailyGreeting() async {
    // Wait a bit for other dialogs to finish
    await Future.delayed(const Duration(milliseconds: 500));

    // Always show NPC button on app launch
    if (mounted) {
      setState(() {
        _showDailyGreeting = true;
      });
    }
  }

  void _updateObjectivesProgress() {
    _objectivesService.updateProgress(
      totalMoneyCollected: _gameState.player.totalMoneyEarned,
      buildingsBuilt: _gameState.city.buildings.length,
      population: _gameState.population,
      level: _gameState.level,
      happiness: _gameState.happiness,
    );
  }

  void _saveGame() {
    _gameState.updateSessionTime();
    saveService.saveGame(_gameState);
  }

  void _onBuildingInfoRequested(BuildingModel building) {
    setState(() {
      _selectedBuilding = building;
    });
  }

  void _showCreditPaymentDialog(int deducted) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Row(
          children: [
            Icon(Icons.account_balance, color: Colors.orange),
            const SizedBox(width: 12),
            const Text(
              'Paiement de crédit',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pendant votre absence, la banque a prélevé:',
              style: TextStyle(color: Colors.grey.shade300),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.remove_circle,
                    color: Colors.orange.shade400,
                    size: 32,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '-$deducted€',
                    style: TextStyle(
                      color: Colors.orange.shade400,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (_gameState.remainingDebt > 0) ...[
              const SizedBox(height: 12),
              Text(
                'Dette restante: ${_gameState.remainingDebt}€',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ],
            if (_gameState.isInDebt) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Attention: Solde négatif!',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showOfflineEarningsDialog(int earnings) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Row(
          children: [
            Icon(Icons.access_time, color: Colors.blue.shade400),
            const SizedBox(width: 12),
            const Text(
              'Bon retour!',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pendant votre absence, votre ville a gagné:',
              style: TextStyle(color: Colors.grey.shade300),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.euro,
                    color: Colors.green.shade400,
                    size: 32,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$earnings€',
                    style: TextStyle(
                      color: Colors.green.shade400,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: const Text('Collecter!'),
          ),
        ],
      ),
    );
  }

  void _onBuildingSelected(BuildingType type) {
    setState(() {
      _showBuildMenu = false;
    });
    _game.enterPlacementMode(type);
  }

  void _collectRevenue(String buildingId) {
    _gameState.collectRevenue(buildingId);
  }

  void _demolishBuilding(String buildingId) {
    // Get the building to calculate refund
    final building = _gameState.city.getBuildingById(buildingId);
    if (building != null) {
      // Refund 50% of the building cost
      final refund = building.config.cost ~/ 2;
      _gameState.addMoney(refund);

      // Show refund message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Batiment demoli - Remboursement: +$refund€'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    // Close the building info overlay
    setState(() {
      _selectedBuilding = null;
    });

    // Remove the building
    _game.buildingSystem.removeBuildingComponent(buildingId);
  }

  void _startMoveBuilding(String buildingId) {
    setState(() {
      _selectedBuilding = null;
    });
    _game.enterMoveMode(buildingId);
  }

  void _collectAllRevenue() {
    final collected = _gameState.collectAllRevenue();
    if (collected > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Collecté $collected€!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _resetGame() {
    _gameState.reset();
    saveService.deleteSave();
    setState(() {
      _showSettings = false;
    });

    // Reload the game
    _isLoading = true;
    _initializeGame();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.blue),
              SizedBox(height: 24),
              Text(
                'Chargement...',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Game view
          GameWidget(
            game: _game,
            backgroundBuilder: (context) => Container(
              color: AppColors.terrainGrass,
            ),
          ),

          // HUD overlay (always visible)
          HudOverlay(
            game: _game,
            gameState: _gameState,
            onBuildMenuPressed: () {
              setState(() {
                _showBuildMenu = true;
              });
            },
            onSettingsPressed: () {
              setState(() {
                _showSettings = true;
              });
            },
            onCollectAllPressed: _collectAllRevenue,
          ),

          // Weather indicator (top center)
          Positioned(
            top: 85,
            left: 0,
            right: 0,
            child: Center(
              child: WeatherOverlay(
                weatherService: _weatherService,
              ),
            ),
          ),

          // Objectives envelope button (top right)
          Positioned(
            top: 175,
            right: 16,
            child: ObjectivesButton(
              objectivesService: _objectivesService,
              onTap: () {
                setState(() {
                  _showObjectives = true;
                });
              },
            ),
          ),

          // Monthly objectives button (below objectives)
          Positioned(
            top: 265,
            right: 16,
            child: _MonthlyObjectivesButton(
              onTap: () {
                setState(() {
                  _showMonthlyObjectives = true;
                });
              },
            ),
          ),

          // Game rules button (below monthly objectives)
          Positioned(
            top: 310,
            right: 16,
            child: GameRulesButton(
              onTap: () {
                setState(() {
                  _showGameRules = true;
                });
              },
            ),
          ),

          // Game rules overlay
          if (_showGameRules)
            GameRulesOverlay(
              onClose: () {
                setState(() {
                  _showGameRules = false;
                });
              },
            ),

          // Objectives overlay
          if (_showObjectives)
            ObjectivesOverlay(
              objectivesService: _objectivesService,
              onClose: () {
                setState(() {
                  _showObjectives = false;
                });
              },
              onRewardClaimed: (reward) {
                _gameState.addMoney(reward);
              },
            ),

          // Build menu overlay
          if (_showBuildMenu)
            BuildMenuOverlay(
              gameState: _gameState,
              onBuildingSelected: _onBuildingSelected,
              onClose: () {
                setState(() {
                  _showBuildMenu = false;
                });
              },
            ),

          // Building info overlay
          if (_selectedBuilding != null)
            BuildingInfoOverlay(
              building: _selectedBuilding!,
              onClose: () {
                setState(() {
                  _selectedBuilding = null;
                });
              },
              onCollect: () => _collectRevenue(_selectedBuilding!.id),
              onDemolish: () => _demolishBuilding(_selectedBuilding!.id),
              onMove: () => _startMoveBuilding(_selectedBuilding!.id),
            ),

          // Settings overlay
          if (_showSettings)
            SettingsOverlay(
              gameState: _gameState,
              onClose: () {
                setState(() {
                  _showSettings = false;
                });
              },
              onSave: _saveGame,
              onReset: _resetGame,
            ),

          // Monthly objectives overlay
          if (_showMonthlyObjectives)
            MonthlyObjectivesOverlay(
              gameState: _gameState,
              onClose: () {
                setState(() {
                  _showMonthlyObjectives = false;
                });
              },
              onRewardClaimed: (money, xp) {
                _gameState.addMoney(money);
                _gameState.addXp(xp);
              },
            ),

          // NPC message button (animated icon, auto-hides after 5s)
          Positioned(
            bottom: 150,
            right: 16,
            child: NpcMessageButton(
              lastDailyRevenue: _gameState.player.lastDailyRevenue,
              population: _gameState.population,
              onDismiss: () {
                setState(() {
                  _showDailyGreeting = false;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Button to open monthly objectives overlay
class _MonthlyObjectivesButton extends StatelessWidget {
  final VoidCallback onTap;

  const _MonthlyObjectivesButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.purple.withValues(alpha: 0.8),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.calendar_month,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }
}