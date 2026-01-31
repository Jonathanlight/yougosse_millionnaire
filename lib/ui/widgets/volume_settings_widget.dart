import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/audio_service.dart';
import '../../utils/constants.dart';

/// Widget for controlling music and SFX volume with sliders
class VolumeSettingsWidget extends StatefulWidget {
  const VolumeSettingsWidget({super.key});

  @override
  State<VolumeSettingsWidget> createState() => _VolumeSettingsWidgetState();
}

class _VolumeSettingsWidgetState extends State<VolumeSettingsWidget> {
  double _musicVolume = GameConstants.defaultMusicVolume;
  double _sfxVolume = GameConstants.defaultSfxVolume;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _musicVolume = prefs.getDouble('music_volume') ?? GameConstants.defaultMusicVolume;
        _sfxVolume = prefs.getDouble('sfx_volume') ?? GameConstants.defaultSfxVolume;
        _isMuted = prefs.getBool('is_muted') ?? false;
      });
      _applySettings();
    } catch (e) {
      // Use defaults if SharedPreferences fails
      _applySettings();
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('music_volume', _musicVolume);
      await prefs.setDouble('sfx_volume', _sfxVolume);
      await prefs.setBool('is_muted', _isMuted);
    } catch (e) {
      // Ignore save errors
    }
  }

  void _applySettings() {
    if (_isMuted) {
      audioService.setMusicVolume(0);
      audioService.setSfxVolume(0);
    } else {
      audioService.setMusicVolume(_musicVolume);
      audioService.setSfxVolume(_sfxVolume);
    }
  }

  void _onMusicVolumeChanged(double value) {
    setState(() {
      _musicVolume = value;
      if (_isMuted) _isMuted = false;
    });
    _applySettings();
    _saveSettings();
  }

  void _onSfxVolumeChanged(double value) {
    setState(() {
      _sfxVolume = value;
      if (_isMuted) _isMuted = false;
    });
    _applySettings();
    _saveSettings();
  }

  void _onMuteToggle() {
    setState(() {
      _isMuted = !_isMuted;
    });
    _applySettings();
    _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with mute button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Audio',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: _onMuteToggle,
                icon: Icon(
                  _isMuted ? Icons.volume_off : Icons.volume_up,
                  color: _isMuted ? Colors.red : Colors.white,
                ),
                tooltip: _isMuted ? 'Unmute' : 'Mute All',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Music volume slider
          _VolumeSlider(
            icon: Icons.music_note,
            label: 'Musique',
            value: _isMuted ? 0 : _musicVolume,
            onChanged: _isMuted ? null : _onMusicVolumeChanged,
            activeColor: Colors.purple,
          ),
          const SizedBox(height: 12),

          // SFX volume slider
          _VolumeSlider(
            icon: Icons.graphic_eq,
            label: 'Effets sonores',
            value: _isMuted ? 0 : _sfxVolume,
            onChanged: _isMuted ? null : _onSfxVolumeChanged,
            activeColor: Colors.cyan,
          ),
        ],
      ),
    );
  }
}

class _VolumeSlider extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final ValueChanged<double>? onChanged;
  final Color activeColor;

  const _VolumeSlider({
    required this.icon,
    required this.label,
    required this.value,
    this.onChanged,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onChanged == null;
    final displayValue = (value * 100).round();

    return Row(
      children: [
        Icon(
          icon,
          color: isDisabled ? Colors.grey : activeColor,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isDisabled ? Colors.grey : Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '$displayValue%',
                    style: TextStyle(
                      color: isDisabled ? Colors.grey : Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: isDisabled ? Colors.grey : activeColor,
                  inactiveTrackColor: Colors.grey.shade800,
                  thumbColor: isDisabled ? Colors.grey : activeColor,
                  overlayColor: activeColor.withValues(alpha: 0.2),
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                ),
                child: Slider(
                  value: value,
                  min: GameConstants.minVolume,
                  max: GameConstants.maxVolume,
                  divisions: (GameConstants.maxVolume / GameConstants.volumeStep).round(),
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Compact inline volume controls for quick access
class CompactVolumeControls extends StatefulWidget {
  const CompactVolumeControls({super.key});

  @override
  State<CompactVolumeControls> createState() => _CompactVolumeControlsState();
}

class _CompactVolumeControlsState extends State<CompactVolumeControls> {
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _loadMuteState();
  }

  Future<void> _loadMuteState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _isMuted = prefs.getBool('is_muted') ?? false;
      });
    } catch (e) {
      // SharedPreferences may fail on some platforms - use default (not muted)
    }
  }

  Future<void> _toggleMute() async {
    setState(() {
      _isMuted = !_isMuted;
    });

    // Apply audio changes immediately regardless of SharedPreferences success
    if (_isMuted) {
      audioService.setMusicVolume(0);
      audioService.setSfxVolume(0);
    } else {
      // Try to get saved volumes, use defaults if SharedPreferences fails
      double musicVol = GameConstants.defaultMusicVolume;
      double sfxVol = GameConstants.defaultSfxVolume;
      try {
        final prefs = await SharedPreferences.getInstance();
        musicVol = prefs.getDouble('music_volume') ?? GameConstants.defaultMusicVolume;
        sfxVol = prefs.getDouble('sfx_volume') ?? GameConstants.defaultSfxVolume;
        await prefs.setBool('is_muted', _isMuted);
      } catch (e) {
        // SharedPreferences may fail - continue with defaults
      }
      audioService.setMusicVolume(musicVol);
      audioService.setSfxVolume(sfxVol);
    }

    // Try to persist the mute state
    if (_isMuted) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_muted', _isMuted);
      } catch (e) {
        // Ignore save errors
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _toggleMute,
      icon: Icon(
        _isMuted ? Icons.volume_off : Icons.volume_up,
        color: _isMuted ? Colors.red : Colors.white,
      ),
      tooltip: _isMuted ? 'Activer le son' : 'Couper le son',
    );
  }
}
