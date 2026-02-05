import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Types of celebrations that can be triggered
enum CelebrationType {
  avatarChanged,
  profileCompleted,
  firstBuildingPlaced,
  buildingCompleted,
  objectiveCompleted,
  levelUp,
  purchaseCompleted,
  dailyLogin,
  matchObtained,
  registrationCompleted,
}

/// Data class for a celebration
class Celebration {
  final CelebrationType type;
  final String title;
  final String message;
  final String emoji;
  final Duration displayDuration;
  final bool showConfetti;

  const Celebration({
    required this.type,
    required this.title,
    required this.message,
    required this.emoji,
    this.displayDuration = const Duration(seconds: 3),
    this.showConfetti = false,
  });
}

/// Service for managing celebration overlays
class CelebrationService extends ChangeNotifier {
  Celebration? _currentCelebration;
  bool _isVisible = false;
  Timer? _autoDismissTimer;

  Celebration? get currentCelebration => _currentCelebration;
  bool get isVisible => _isVisible;

  /// Map of celebration types to their configurations
  static final Map<CelebrationType, Celebration> celebrations = {
    CelebrationType.avatarChanged: const Celebration(
      type: CelebrationType.avatarChanged,
      title: 'Nouveau Look !',
      message: 'Tu es superbe avec ce nouvel avatar',
      emoji: '🎨',
      showConfetti: true,
    ),
    CelebrationType.profileCompleted: const Celebration(
      type: CelebrationType.profileCompleted,
      title: 'Profil Complet !',
      message: 'Tu es prêt pour l\'aventure',
      emoji: '✅',
      showConfetti: true,
    ),
    CelebrationType.firstBuildingPlaced: const Celebration(
      type: CelebrationType.firstBuildingPlaced,
      title: 'Premier Pas !',
      message: 'Ta ville commence à prendre forme',
      emoji: '🏗️',
      showConfetti: true,
    ),
    CelebrationType.buildingCompleted: const Celebration(
      type: CelebrationType.buildingCompleted,
      title: 'Construction Terminée !',
      message: 'Un nouveau bâtiment dans ta ville',
      emoji: '🏢',
    ),
    CelebrationType.objectiveCompleted: const Celebration(
      type: CelebrationType.objectiveCompleted,
      title: 'Objectif Atteint !',
      message: 'Continue comme ça, champion !',
      emoji: '🏆',
      showConfetti: true,
    ),
    CelebrationType.levelUp: const Celebration(
      type: CelebrationType.levelUp,
      title: 'Level Up !',
      message: 'Tu montes en puissance',
      emoji: '⭐',
      showConfetti: true,
    ),
    CelebrationType.purchaseCompleted: const Celebration(
      type: CelebrationType.purchaseCompleted,
      title: 'Merci !',
      message: 'Ton soutien est précieux',
      emoji: '💎',
      showConfetti: true,
    ),
    CelebrationType.dailyLogin: const Celebration(
      type: CelebrationType.dailyLogin,
      title: 'Bon Retour !',
      message: 'Ta fidélité est récompensée',
      emoji: '🔥',
    ),
    CelebrationType.matchObtained: const Celebration(
      type: CelebrationType.matchObtained,
      title: 'C\'est un Match !',
      message: 'Félicitations !',
      emoji: '❤️',
      showConfetti: true,
    ),
    CelebrationType.registrationCompleted: const Celebration(
      type: CelebrationType.registrationCompleted,
      title: 'Bienvenue !',
      message: 'L\'aventure commence maintenant',
      emoji: '🎊',
      showConfetti: true,
    ),
  };

  /// Trigger a celebration
  void celebrate(CelebrationType type, {Celebration? customCelebration}) {
    final celebration = customCelebration ?? celebrations[type];
    if (celebration == null) return;

    // Cancel any existing celebration
    _dismiss();

    _currentCelebration = celebration;
    _isVisible = true;

    // Schedule notification for next frame to avoid build conflicts
    _safeNotifyListeners();

    // Start auto-dismiss timer
    _autoDismissTimer = Timer(celebration.displayDuration, () {
      _dismiss();
    });
  }

  /// Safely notify listeners by scheduling for next frame if needed
  void _safeNotifyListeners() {
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
      notifyListeners();
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  /// Trigger a celebration with custom message
  void celebrateCustom({
    required CelebrationType type,
    required String title,
    required String message,
    String emoji = '🎉',
    bool showConfetti = false,
  }) {
    celebrate(
      type,
      customCelebration: Celebration(
        type: type,
        title: title,
        message: message,
        emoji: emoji,
        showConfetti: showConfetti,
      ),
    );
  }

  /// Dismiss the current celebration
  void dismiss() {
    _dismiss();
  }

  void _dismiss() {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = null;

    if (_isVisible) {
      _isVisible = false;
      _currentCelebration = null;
      _safeNotifyListeners();
    }
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    super.dispose();
  }
}

/// Global celebration service instance
final celebrationService = CelebrationService();
