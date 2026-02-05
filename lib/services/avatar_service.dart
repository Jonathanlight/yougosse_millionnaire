import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing user avatar selection
class AvatarService extends ChangeNotifier {
  static const String _avatarKey = 'selected_avatar_path';
  static const String _defaultAvatar = 'assets/avatar/Blaze.png';

  String _selectedAvatar = _defaultAvatar;
  List<String> _availableAvatars = [];
  bool _isInitialized = false;

  String get selectedAvatar => _selectedAvatar;
  List<String> get availableAvatars => _availableAvatars;
  bool get isInitialized => _isInitialized;

  /// Initialize the avatar service
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _loadAvailableAvatars();
    await _loadSelectedAvatar();
    _isInitialized = true;
    notifyListeners();
  }

  /// Load available avatars from the asset manifest
  Future<void> _loadAvailableAvatars() async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');

      // Parse the manifest to find avatar assets
      final RegExp avatarPattern = RegExp(r'assets/avatar/[^"]+\.png');
      final matches = avatarPattern.allMatches(manifestContent);

      _availableAvatars = matches
          .map((match) => match.group(0)!)
          .toSet() // Remove duplicates
          .toList()
        ..sort(); // Sort alphabetically

      // Ensure we have at least the default avatar
      if (_availableAvatars.isEmpty) {
        _availableAvatars = [_defaultAvatar];
      }
    } catch (e) {
      debugPrint('Failed to load avatar manifest: $e');
      // Fallback to hardcoded list
      _availableAvatars = [
        'assets/avatar/Blaze.png',
        'assets/avatar/Candy.png',
        'assets/avatar/Fenix.png',
        'assets/avatar/Kage.png',
        'assets/avatar/Kenji.png',
        'assets/avatar/Kira.png',
        'assets/avatar/Leonhart.png',
        'assets/avatar/Lumina.png',
        'assets/avatar/Marcus.png',
        'assets/avatar/Nova.png',
        'assets/avatar/Prophet.png',
        'assets/avatar/Ryuu.png',
        'assets/avatar/Seren.png',
        'assets/avatar/Shadow.png',
        'assets/avatar/Solana.png',
        'assets/avatar/Sylvara.png',
        'assets/avatar/Velvet.png',
        'assets/avatar/Victoria.png',
        'assets/avatar/Zephyr.png',
        'assets/avatar/Zyxara.png',
      ];
    }
  }

  /// Load the selected avatar from SharedPreferences
  Future<void> _loadSelectedAvatar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedAvatar = prefs.getString(_avatarKey);

      if (savedAvatar != null && _availableAvatars.contains(savedAvatar)) {
        _selectedAvatar = savedAvatar;
      } else {
        _selectedAvatar = _availableAvatars.isNotEmpty
            ? _availableAvatars.first
            : _defaultAvatar;
      }
    } catch (e) {
      debugPrint('Failed to load selected avatar: $e');
      _selectedAvatar = _defaultAvatar;
    }
  }

  /// Save the selected avatar
  Future<bool> saveSelectedAvatar(String avatarPath) async {
    if (!_availableAvatars.contains(avatarPath)) {
      debugPrint('Invalid avatar path: $avatarPath');
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_avatarKey, avatarPath);
      _selectedAvatar = avatarPath;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to save avatar: $e');
      return false;
    }
  }

  /// Get the avatar name from the path (without extension)
  String getAvatarName(String avatarPath) {
    final fileName = avatarPath.split('/').last;
    return fileName.replaceAll('.png', '');
  }

  /// Precache all avatar images for better performance
  Future<void> precacheAvatars(BuildContext context) async {
    for (final avatar in _availableAvatars) {
      try {
        await precacheImage(AssetImage(avatar), context);
      } catch (e) {
        debugPrint('Failed to precache avatar $avatar: $e');
      }
    }
  }
}

/// Global avatar service instance
final avatarService = AvatarService();
