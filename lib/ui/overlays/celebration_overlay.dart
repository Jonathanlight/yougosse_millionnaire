import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../services/celebration_service.dart';

/// Overlay widget for displaying celebration animations
class CelebrationOverlay extends StatelessWidget {
  const CelebrationOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: celebrationService,
      builder: (context, _) {
        if (!celebrationService.isVisible ||
            celebrationService.currentCelebration == null) {
          return const SizedBox.shrink();
        }

        return _CelebrationContent(
          celebration: celebrationService.currentCelebration!,
          onDismiss: celebrationService.dismiss,
        );
      },
    );
  }
}

class _CelebrationContent extends StatefulWidget {
  final Celebration celebration;
  final VoidCallback onDismiss;

  const _CelebrationContent({
    required this.celebration,
    required this.onDismiss,
  });

  @override
  State<_CelebrationContent> createState() => _CelebrationContentState();
}

class _CelebrationContentState extends State<_CelebrationContent>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _emojiController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _emojiScaleAnimation;

  @override
  void initState() {
    super.initState();

    // Fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    // Scale animation
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.elasticOut,
      ),
    );

    // Emoji bounce animation
    _emojiController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _emojiScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _emojiController,
        curve: Curves.elasticOut,
      ),
    );

    // Start animations
    _fadeController.forward();
    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _emojiController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _emojiController.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await Future.wait([
      _fadeController.reverse(),
      _scaleController.animateTo(0.9,
          duration: const Duration(milliseconds: 200)),
    ]);
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _dismiss,
      child: AnimatedBuilder(
        animation: Listenable.merge([_fadeAnimation, _scaleAnimation]),
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              color: Colors.black.withValues(alpha: 0.7 * _fadeAnimation.value),
              child: Center(
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
              ),
            ),
          );
        },
        child: _buildCard(),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade900,
            Colors.grey.shade800,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
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
          // Confetti particles (if enabled)
          if (widget.celebration.showConfetti) _buildConfettiDecoration(),

          // Emoji with bounce animation
          AnimatedBuilder(
            animation: _emojiScaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _emojiScaleAnimation.value,
                child: child,
              );
            },
            child: Text(
              widget.celebration.emoji,
              style: const TextStyle(fontSize: 64),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            widget.celebration.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),

          // Message
          Text(
            widget.celebration.message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 16,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),

          // Continue button
          OutlinedButton(
            onPressed: _dismiss,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.5),
                width: 1.5,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Continuer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfettiDecoration() {
    return SizedBox(
      height: 30,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) {
          final colors = [
            Colors.amber,
            Colors.pink,
            Colors.blue,
            Colors.green,
            Colors.purple,
          ];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _ConfettiParticle(
              color: colors[index],
              delay: Duration(milliseconds: index * 100),
            ),
          );
        }),
      ),
    );
  }
}

/// Simple confetti particle animation
class _ConfettiParticle extends StatefulWidget {
  final Color color;
  final Duration delay;

  const _ConfettiParticle({
    required this.color,
    required this.delay,
  });

  @override
  State<_ConfettiParticle> createState() => _ConfettiParticleState();
}

class _ConfettiParticleState extends State<_ConfettiParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -10 * math.sin(_animation.value * math.pi)),
          child: Transform.rotate(
            angle: _animation.value * math.pi * 2,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}
