import 'package:flame_audio/flame_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

/// Service for managing game audio
class AudioService {
  bool _isMusicEnabled = true;
  bool _isSfxEnabled = true;
  double _musicVolume = GameConstants.defaultMusicVolume;
  double _sfxVolume = GameConstants.defaultSfxVolume;
  bool _isInitialized = false;
  bool _isMusicPlaying = false;

  bool get isMusicEnabled => _isMusicEnabled;
  bool get isSfxEnabled => _isSfxEnabled;
  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;

  /// Initialize audio service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load saved volume settings
      await _loadVolumeSettings();

      // Preload audio files
      await FlameAudio.audioCache.loadAll([
        AssetPaths.backgroundMusic,
        AssetPaths.cashRegisterSound,
      ]);
      _isInitialized = true;
      print('Audio service initialized successfully');

      // Start playing music if enabled
      if (_isMusicEnabled) {
        await playMusic();
      }
    } catch (e) {
      print('Audio initialization failed: $e');
      _isInitialized = true; // Mark as initialized to prevent retry loops
    }
  }

  /// Load volume settings from SharedPreferences
  Future<void> _loadVolumeSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _musicVolume = prefs.getDouble('music_volume') ?? GameConstants.defaultMusicVolume;
      _sfxVolume = prefs.getDouble('sfx_volume') ?? GameConstants.defaultSfxVolume;
      final isMuted = prefs.getBool('is_muted') ?? false;
      _isMusicEnabled = !isMuted;
      _isSfxEnabled = !isMuted;
    } catch (e) {
      // SharedPreferences may fail on some platforms - use defaults
      print('Failed to load volume settings (using defaults): $e');
      _musicVolume = GameConstants.defaultMusicVolume;
      _sfxVolume = GameConstants.defaultSfxVolume;
    }
  }

  /// Play background music in loop with low volume
  Future<void> playMusic() async {
    if (!_isMusicEnabled || _isMusicPlaying) return;

    try {
      await FlameAudio.bgm.play(AssetPaths.backgroundMusic, volume: _musicVolume);
      _isMusicPlaying = true;
      print('Background music started playing');
    } catch (e) {
      print('Failed to play music: $e');
    }
  }

  /// Stop background music
  void stopMusic() {
    try {
      FlameAudio.bgm.stop();
      _isMusicPlaying = false;
    } catch (e) {
      print('Failed to stop music: $e');
    }
  }

  /// Pause background music
  void pauseMusic() {
    try {
      FlameAudio.bgm.pause();
    } catch (e) {
      print('Failed to pause music: $e');
    }
  }

  /// Resume background music
  void resumeMusic() {
    if (!_isMusicEnabled) return;

    try {
      FlameAudio.bgm.resume();
    } catch (e) {
      print('Failed to resume music: $e');
    }
  }

  /// Play cash register sound when collecting money
  void playCashRegister() {
    if (!_isSfxEnabled) return;

    try {
      FlameAudio.play(AssetPaths.cashRegisterSound, volume: _sfxVolume);
    } catch (e) {
      print('Failed to play cash register sound: $e');
    }
  }

  /// Play a sound effect
  void playSfx(SoundEffect effect) {
    if (!_isSfxEnabled) return;

    try {
      switch (effect) {
        case SoundEffect.moneyCollected:
          playCashRegister();
        default:
          break;
      }
    } catch (e) {
      print('Failed to play SFX: $e');
    }
  }

  /// Toggle music on/off
  void toggleMusic() {
    _isMusicEnabled = !_isMusicEnabled;
    if (_isMusicEnabled) {
      playMusic();
    } else {
      stopMusic();
    }
  }

  /// Toggle sound effects on/off
  void toggleSfx() {
    _isSfxEnabled = !_isSfxEnabled;
  }

  /// Set music volume (0.0 to 1.0)
  void setMusicVolume(double volume) {
    _musicVolume = volume.clamp(0.0, 1.0);
    try {
      if (_isMusicEnabled && _isMusicPlaying) {
        stopMusic();
        playMusic();
      }
    } catch (e) {
      print('Failed to set music volume: $e');
    }
  }

  /// Set sound effects volume (0.0 to 1.0)
  void setSfxVolume(double volume) {
    _sfxVolume = volume.clamp(0.0, 1.0);
  }

  /// Dispose audio resources
  Future<void> dispose() async {
    try {
      FlameAudio.bgm.dispose();
    } catch (e) {
      print('Failed to dispose audio: $e');
    }
  }
}

/// Sound effects enumeration
enum SoundEffect {
  buildingPlaced,
  buildingCompleted,
  moneyCollected,
  levelUp,
  buttonClick,
  error,
}

/// Global audio service instance
final audioService = AudioService();
