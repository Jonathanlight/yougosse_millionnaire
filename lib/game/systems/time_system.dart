import '../data/game_state.dart';
import '../../utils/constants.dart';

/// Manages game time and auto-save functionality
class TimeSystem {
  final GameState gameState;
  final void Function()? onAutoSave;

  double _autoSaveTimer = 0;
  double _gameTime = 0;
  bool _isPaused = false;

  TimeSystem({
    required this.gameState,
    this.onAutoSave,
  });

  /// Total game time in seconds
  double get gameTime => _gameTime;

  /// Is the game paused
  bool get isPaused => _isPaused;

  /// Update the time system
  void update(double dt) {
    if (_isPaused) return;

    _gameTime += dt;
    _autoSaveTimer += dt;

    // Auto-save check
    if (_autoSaveTimer >= GameConstants.autoSaveIntervalSeconds) {
      _autoSaveTimer = 0;
      onAutoSave?.call();
    }
  }

  /// Pause the game
  void pause() {
    _isPaused = true;
  }

  /// Resume the game
  void resume() {
    _isPaused = false;
  }

  /// Toggle pause state
  void togglePause() {
    _isPaused = !_isPaused;
  }

  /// Reset the auto-save timer
  void resetAutoSaveTimer() {
    _autoSaveTimer = 0;
  }

  /// Get formatted game time
  String get formattedGameTime {
    final hours = (_gameTime / 3600).floor();
    final minutes = ((_gameTime % 3600) / 60).floor();
    final seconds = (_gameTime % 60).floor();

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Calculate time until next revenue cycle
  Duration get timeUntilNextRevenue {
    final elapsed = _gameTime % GameConstants.revenueIntervalSeconds;
    final remaining = GameConstants.revenueIntervalSeconds - elapsed;
    return Duration(seconds: remaining.round());
  }
}
