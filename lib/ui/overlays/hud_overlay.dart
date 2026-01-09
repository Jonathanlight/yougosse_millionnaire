import 'package:flutter/material.dart';
import '../../game/city_game.dart';
import '../../game/data/game_state.dart';
import '../../services/audio_service.dart';
import '../../utils/constants.dart';
import '../widgets/resource_bar.dart';

/// Main HUD overlay that displays game information
class HudOverlay extends StatefulWidget {
  final CityGame game;
  final GameState gameState;
  final VoidCallback onBuildMenuPressed;
  final VoidCallback onSettingsPressed;
  final VoidCallback onCollectAllPressed;

  const HudOverlay({
    super.key,
    required this.game,
    required this.gameState,
    required this.onBuildMenuPressed,
    required this.onSettingsPressed,
    required this.onCollectAllPressed,
  });

  @override
  State<HudOverlay> createState() => _HudOverlayState();
}

class _HudOverlayState extends State<HudOverlay> {
  bool _isSoundEnabled = true;

  @override
  void initState() {
    super.initState();
    widget.gameState.addListener(_onGameStateChanged);
    _isSoundEnabled = audioService.isMusicEnabled;
  }

  @override
  void dispose() {
    widget.gameState.removeListener(_onGameStateChanged);
    super.dispose();
  }

  void _onGameStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _toggleSound() {
    setState(() {
      _isSoundEnabled = !_isSoundEnabled;
      audioService.toggleMusic();
      audioService.toggleSfx();
    });
  }

  void _moveCamera(double dx, double dy) {
    // Move camera by a fixed amount (100 units)
    const moveAmount = 150.0;
    widget.game.centerOn(
      ((widget.game.camera.viewfinder.position.x + dx * moveAmount) / GameConstants.cellSize).floor(),
      ((widget.game.camera.viewfinder.position.y + dy * moveAmount) / GameConstants.cellSize).floor(),
    );
  }

  void _showCreditDialog() {
    showDialog(
      context: context,
      builder: (context) => _CreditDialog(
        onCreditTaken: (amount) {
          widget.gameState.takeCredit(amount);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top resource bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ResourceBar(
            money: widget.gameState.money,
            population: widget.gameState.population,
            happiness: widget.gameState.happiness,
            level: widget.gameState.level,
            levelProgress: widget.gameState.player.levelProgress,
            onMoneyTap: widget.onCollectAllPressed,
            isInDebt: widget.gameState.isInDebt,
            canTakeCredit: widget.gameState.canTakeCredit,
            remainingDebt: widget.gameState.remainingDebt,
            onCreditTap: _showCreditDialog,
          ),
        ),

        // Bottom action buttons
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Settings button
                  _ActionButton(
                    icon: Icons.settings,
                    onPressed: widget.onSettingsPressed,
                  ),

                  // Build button (main action)
                  _BuildButton(
                    isPlacementMode: widget.gameState.isPlacementMode,
                    onPressed: widget.gameState.isPlacementMode
                        ? () => widget.game.exitPlacementMode()
                        : widget.onBuildMenuPressed,
                  ),

                  // Zoom controls
                  Row(
                    children: [
                      _ActionButton(
                        icon: Icons.remove,
                        onPressed: widget.game.zoomOut,
                        size: 40,
                      ),
                      const SizedBox(width: 8),
                      _ActionButton(
                        icon: Icons.add,
                        onPressed: widget.game.zoomIn,
                        size: 40,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Placement mode indicator
        if (widget.gameState.isPlacementMode)
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.touch_app,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Touchez pour placer le bâtiment',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Revenue per minute indicator
        Positioned(
          top: 130,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.trending_up,
                  color: Colors.green.shade400,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '+${widget.gameState.revenuePerMinute}€/min',
                  style: TextStyle(
                    color: Colors.green.shade400,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        // D-Pad navigation controls (left side)
        Positioned(
          left: 16,
          bottom: 120,
          child: _DPadControls(
            onMove: _moveCamera,
          ),
        ),

        // Sound toggle button (top right)
        Positioned(
          top: 130,
          left: 16,
          child: _ActionButton(
            icon: _isSoundEnabled ? Icons.volume_up : Icons.volume_off,
            onPressed: _toggleSound,
            size: 44,
            backgroundColor: _isSoundEnabled
                ? Colors.green.withValues(alpha: 0.7)
                : Colors.red.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final Color? backgroundColor;

  const _ActionButton({
    required this.icon,
    required this.onPressed,
    this.size = 50,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.black.withValues(alpha: 0.6),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: size * 0.5,
        ),
      ),
    );
  }
}

class _BuildButton extends StatelessWidget {
  final bool isPlacementMode;
  final VoidCallback onPressed;

  const _BuildButton({
    required this.isPlacementMode,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isPlacementMode
                ? [Colors.red.shade400, Colors.red.shade700]
                : [Colors.blue.shade400, Colors.blue.shade700],
          ),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.5),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: (isPlacementMode ? Colors.red : Colors.blue)
                  .withValues(alpha: 0.4),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          isPlacementMode ? Icons.close : Icons.construction,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}

/// Credit dialog for requesting a bank loan
class _CreditDialog extends StatefulWidget {
  final void Function(int amount) onCreditTaken;

  const _CreditDialog({required this.onCreditTaken});

  @override
  State<_CreditDialog> createState() => _CreditDialogState();
}

class _CreditDialogState extends State<_CreditDialog> {
  double _selectedAmount = GameConstants.minCredit.toDouble();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey.shade900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.amber.withValues(alpha: 0.5), width: 2),
      ),
      title: Row(
        children: [
          Icon(Icons.account_balance, color: Colors.amber, size: 28),
          const SizedBox(width: 12),
          const Text(
            'Crédit Bancaire',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Text(
                  'Demander un crédit',
                  style: TextStyle(
                    color: Colors.grey.shade300,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_selectedAmount.round()}€',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Slider(
            value: _selectedAmount,
            min: GameConstants.minCredit.toDouble(),
            max: GameConstants.maxCredit.toDouble(),
            divisions: (GameConstants.maxCredit - GameConstants.minCredit) ~/ 1000,
            activeColor: Colors.amber,
            inactiveColor: Colors.grey.shade700,
            label: '${_selectedAmount.round()}€',
            onChanged: (value) {
              setState(() {
                _selectedAmount = value;
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${GameConstants.minCredit}€',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
              Text(
                '${GameConstants.maxCredit}€',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'Conditions:',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Crédit unique (une seule fois)',
                  style: TextStyle(color: Colors.grey.shade300, fontSize: 12),
                ),
                Text(
                  '• Remboursement: -${GameConstants.dailyCreditPayment}€/jour',
                  style: TextStyle(color: Colors.grey.shade300, fontSize: 12),
                ),
                Text(
                  '• Votre solde peut devenir négatif',
                  style: TextStyle(color: Colors.red.shade300, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Annuler',
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onCreditTaken(_selectedAmount.round());
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Crédit de ${_selectedAmount.round()}€ accordé!'),
                backgroundColor: Colors.green,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
          ),
          child: const Text('Demander'),
        ),
      ],
    );
  }
}

/// D-Pad style navigation controls
class _DPadControls extends StatelessWidget {
  final void Function(double dx, double dy) onMove;

  const _DPadControls({required this.onMove});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      height: 130,
      child: Stack(
        children: [
          // Center background
          Center(
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Up button
          Positioned(
            top: 0,
            left: 45,
            child: _DPadButton(
              icon: Icons.keyboard_arrow_up,
              onPressed: () => onMove(0, -1),
            ),
          ),
          // Down button
          Positioned(
            bottom: 0,
            left: 45,
            child: _DPadButton(
              icon: Icons.keyboard_arrow_down,
              onPressed: () => onMove(0, 1),
            ),
          ),
          // Left button
          Positioned(
            left: 0,
            top: 45,
            child: _DPadButton(
              icon: Icons.keyboard_arrow_left,
              onPressed: () => onMove(-1, 0),
            ),
          ),
          // Right button
          Positioned(
            right: 0,
            top: 45,
            child: _DPadButton(
              icon: Icons.keyboard_arrow_right,
              onPressed: () => onMove(1, 0),
            ),
          ),
        ],
      ),
    );
  }
}

class _DPadButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _DPadButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
