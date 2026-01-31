import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

/// NPC character enumeration
enum NpcCharacter {
  nora,
  christine,
  james,
}

/// Extension to get character asset path
extension NpcCharacterExtension on NpcCharacter {
  String get assetPath {
    switch (this) {
      case NpcCharacter.nora:
        return AssetPaths.nora;
      case NpcCharacter.christine:
        return AssetPaths.christine;
      case NpcCharacter.james:
        return AssetPaths.james;
    }
  }

  String get displayName {
    switch (this) {
      case NpcCharacter.nora:
        return 'Nora';
      case NpcCharacter.christine:
        return 'Christine';
      case NpcCharacter.james:
        return 'James';
    }
  }
}

/// Greeting messages for each character
class GreetingMessages {
  GreetingMessages._();

  static const Map<NpcCharacter, List<String>> messages = {
    NpcCharacter.nora: [
      "Bonjour Maire ! Hier, ta ville a genere {revenue} ! Continue comme ca, tu es sur la bonne voie !",
      "Salut ! Les habitants sont contents, tu as gagne {revenue} hier. Ta ville grandit bien !",
      "Hey Maire ! {revenue} recoltes hier ! Tes citoyens te remercient pour ton travail !",
    ],
    NpcCharacter.christine: [
      "Bonjour ! Rapport du jour : {revenue} de revenus hier. Ta population est de {population} habitants !",
      "Maire, bonne nouvelle ! Tu as engrange {revenue} hier. Continue a developper ta ville !",
      "Hello ! Avec {revenue} gagnes hier et {population} habitants, ta ville prend forme !",
    ],
    NpcCharacter.james: [
      "Yo Maire ! {revenue} hier, pas mal du tout ! On continue a construire ?",
      "Chef ! La ville a rapporte {revenue} hier. Les affaires marchent bien !",
      "Salut boss ! {revenue} de revenus hier. Ta ville devient une vraie metropole !",
    ],
  };

  /// Get a random message for a character with placeholders replaced
  static String getMessage(NpcCharacter character, int revenue, int population) {
    final characterMessages = messages[character]!;
    final random = Random();
    final message = characterMessages[random.nextInt(characterMessages.length)];

    return message
        .replaceAll('{revenue}', '${revenue.toCurrency()}')
        .replaceAll('{population}', population.toCompact());
  }
}

/// Daily greeting dialog widget
class DailyGreetingDialog extends StatefulWidget {
  final int lastDailyRevenue;
  final int population;
  final VoidCallback onDismiss;

  const DailyGreetingDialog({
    super.key,
    required this.lastDailyRevenue,
    required this.population,
    required this.onDismiss,
  });

  @override
  State<DailyGreetingDialog> createState() => _DailyGreetingDialogState();

  /// Check if the greeting should be shown today
  static Future<bool> shouldShowToday() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastGreeting = prefs.getString('last_daily_greeting');

      if (lastGreeting == null) return true;

      final today = DateTime.now();
      final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      return lastGreeting != todayString;
    } catch (e) {
      // If SharedPreferences fails, show the greeting anyway
      return true;
    }
  }

  /// Mark the greeting as shown for today
  static Future<void> markAsShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      await prefs.setString('last_daily_greeting', todayString);
    } catch (e) {
      // Ignore SharedPreferences errors
    }
  }
}

class _DailyGreetingDialogState extends State<DailyGreetingDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late NpcCharacter _character;
  late String _message;
  bool _autoDismissScheduled = false;

  @override
  void initState() {
    super.initState();

    // Select random character
    final random = Random();
    _character = NpcCharacter.values[random.nextInt(NpcCharacter.values.length)];

    // Get message with placeholders replaced
    _message = GreetingMessages.getMessage(
      _character,
      widget.lastDailyRevenue,
      widget.population,
    );

    // Setup animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    // Start animation
    _animationController.forward();

    // Auto-dismiss after 5 seconds
    _scheduleAutoDismiss();
  }

  void _scheduleAutoDismiss() {
    if (_autoDismissScheduled) return;
    _autoDismissScheduled = true;
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _autoDismissScheduled) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _autoDismissScheduled = false;
    _animationController.dispose();
    super.dispose();
  }

  void _dismiss() async {
    _autoDismissScheduled = false;
    await DailyGreetingDialog.markAsShown();
    await _animationController.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {}, // Prevent dismiss on background tap
      child: Container(
        color: Colors.black.withValues(alpha: 0.6),
        child: Center(
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                margin: const EdgeInsets.all(24),
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade800,
                            Colors.blue.shade600,
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.wb_sunny,
                            color: Colors.yellow,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Bonjour !',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Character avatar
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.blue.shade400,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                _character.assetPath,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  // Fallback to icon if image not found
                                  return Container(
                                    color: Colors.blue.shade700,
                                    child: const Icon(
                                      Icons.person,
                                      size: 40,
                                      color: Colors.white,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Speech bubble
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade800,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _character.displayName,
                                    style: TextStyle(
                                      color: Colors.blue.shade300,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _message,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _dismiss,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Merci !',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Daily revenue tracker mixin for game state
mixin DailyRevenueTracker {
  int _dailyRevenueTracker = 0;
  int _lastDailyRevenue = 0;
  DateTime _lastRevenueResetDate = DateTime.now();

  int get dailyRevenueTracker => _dailyRevenueTracker;
  int get lastDailyRevenue => _lastDailyRevenue;

  /// Add revenue to daily tracker
  void addToDailyRevenue(int amount) {
    _checkAndResetDaily();
    _dailyRevenueTracker += amount;
  }

  /// Check if we need to reset the daily tracker (new day)
  void _checkAndResetDaily() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastReset = DateTime(
      _lastRevenueResetDate.year,
      _lastRevenueResetDate.month,
      _lastRevenueResetDate.day,
    );

    if (today.isAfter(lastReset)) {
      // New day - transfer to lastDailyRevenue and reset
      _lastDailyRevenue = _dailyRevenueTracker;
      _dailyRevenueTracker = 0;
      _lastRevenueResetDate = now;
    }
  }

  /// Load daily tracking data from JSON
  void loadDailyTracking(Map<String, dynamic> json) {
    _dailyRevenueTracker = json['dailyRevenueTracker'] as int? ?? 0;
    _lastDailyRevenue = json['lastDailyRevenue'] as int? ?? 0;
    _lastRevenueResetDate = json['lastRevenueResetDate'] != null
        ? DateTime.parse(json['lastRevenueResetDate'] as String)
        : DateTime.now();
    _checkAndResetDaily();
  }

  /// Export daily tracking data to JSON
  Map<String, dynamic> dailyTrackingToJson() {
    return {
      'dailyRevenueTracker': _dailyRevenueTracker,
      'lastDailyRevenue': _lastDailyRevenue,
      'lastRevenueResetDate': _lastRevenueResetDate.toIso8601String(),
    };
  }
}

/// Animated NPC icon button to show greeting message on demand
class NpcMessageButton extends StatefulWidget {
  final int lastDailyRevenue;
  final int population;
  final VoidCallback? onDismiss;

  const NpcMessageButton({
    super.key,
    required this.lastDailyRevenue,
    required this.population,
    this.onDismiss,
  });

  @override
  State<NpcMessageButton> createState() => _NpcMessageButtonState();
}

class _NpcMessageButtonState extends State<NpcMessageButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Pulse animation for the icon
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _showGreeting() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => DailyGreetingDialog(
        lastDailyRevenue: widget.lastDailyRevenue,
        population: widget.population,
        onDismiss: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: GestureDetector(
        onTap: _showGreeting,
        child: Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.orange.shade400,
                Colors.orange.shade700,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withValues(alpha: 0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
            border: Border.all(
              color: Colors.white,
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.person,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}
