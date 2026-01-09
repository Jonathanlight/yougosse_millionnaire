import 'package:flutter/material.dart';
import '../../models/objective_model.dart';
import '../../services/objectives_service.dart';

/// Envelope button that shows objectives
class ObjectivesButton extends StatelessWidget {
  final ObjectivesService objectivesService;
  final VoidCallback onTap;

  const ObjectivesButton({
    super.key,
    required this.objectivesService,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: objectivesService,
      builder: (context, _) {
        final hasNew = objectivesService.hasNewObjectives;
        final hasRewards = objectivesService.hasClaimableRewards;

        return GestureDetector(
          onTap: onTap,
          child: Stack(
            children: [
              Container(
                width: 37,
                height: 37,
                decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber.shade300,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  hasNew ? Icons.mail : Icons.mail_outline,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              // Notification badge
              if (hasNew || hasRewards)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: hasRewards ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(
                      child: Icon(
                        hasRewards ? Icons.check : Icons.priority_high,
                        color: Colors.white,
                        size: 10,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Full screen objectives overlay
class ObjectivesOverlay extends StatefulWidget {
  final ObjectivesService objectivesService;
  final VoidCallback onClose;
  final void Function(int reward) onRewardClaimed;

  const ObjectivesOverlay({
    super.key,
    required this.objectivesService,
    required this.onClose,
    required this.onRewardClaimed,
  });

  @override
  State<ObjectivesOverlay> createState() => _ObjectivesOverlayState();
}

class _ObjectivesOverlayState extends State<ObjectivesOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  bool _isEnvelopeOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _rotationAnimation = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();

    // Check if envelope was already opened
    _isEnvelopeOpen = widget.objectivesService.currentWeek?.isOpened ?? false;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openEnvelope() {
    setState(() {
      _isEnvelopeOpen = true;
    });
    widget.objectivesService.openEnvelope();
  }

  void _claimAllRewards() {
    final reward = widget.objectivesService.claimAllRewards();
    if (reward > 0) {
      widget.onRewardClaimed(reward);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recompense de $reward€ recue !'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Transform.rotate(
                    angle: _rotationAnimation.value,
                    child: child,
                  ),
                );
              },
              child: _isEnvelopeOpen
                  ? _buildOpenedEnvelope()
                  : _buildClosedEnvelope(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClosedEnvelope() {
    return GestureDetector(
      onTap: _openEnvelope,
      child: Container(
        width: 300,
        height: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.amber.shade300,
              Colors.amber.shade600,
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Envelope flap
            ClipPath(
              clipper: _EnvelopeFlapClipper(),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.amber.shade400,
                      Colors.amber.shade700,
                    ],
                  ),
                ),
              ),
            ),
            // Seal
            Positioned(
              top: 60,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.red.shade700,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 32,
                  ),
                ),
              ),
            ),
            // Text
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  const Text(
                    'OBJECTIFS DE LA SEMAINE',
                    style: TextStyle(
                      color: Colors.brown,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Appuyez pour ouvrir',
                    style: TextStyle(
                      color: Colors.brown.shade400,
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
  }

  Widget _buildOpenedEnvelope() {
    final currentWeek = widget.objectivesService.currentWeek;
    if (currentWeek == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.shade700, width: 3),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade700, Colors.amber.shade900],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(17),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.flag, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Objectifs de la semaine',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        '${currentWeek.completedCount}/${currentWeek.objectives.length} completes',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),

          // Time remaining
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.black.withValues(alpha: 0.3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Temps restant: ${_formatDuration(currentWeek.timeRemaining)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Objectives list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(12),
              itemCount: currentWeek.objectives.length,
              itemBuilder: (context, index) {
                return _ObjectiveCard(
                  objective: currentWeek.objectives[index],
                  onClaim: () {
                    final reward = widget.objectivesService
                        .claimReward(currentWeek.objectives[index].id);
                    if (reward > 0) {
                      widget.onRewardClaimed(reward);
                    }
                  },
                );
              },
            ),
          ),

          // Claim all button
          if (currentWeek.claimableReward > 0)
            Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton.icon(
                onPressed: _claimAllRewards,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                icon: const Icon(Icons.redeem),
                label: Text(
                  'Reclamer tout (+${currentWeek.claimableReward}€)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}j ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }
}

class _ObjectiveCard extends StatelessWidget {
  final Objective objective;
  final VoidCallback onClaim;

  const _ObjectiveCard({
    required this.objective,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final canClaim = objective.isCompleted && !objective.isRewardClaimed;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: objective.isRewardClaimed
            ? Colors.green.withValues(alpha: 0.2)
            : Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: objective.isCompleted
              ? Colors.green.withValues(alpha: 0.5)
              : Colors.grey.shade700,
        ),
      ),
      child: Row(
        children: [
          // Checkbox
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: objective.isCompleted ? Colors.green : Colors.grey.shade700,
              shape: BoxShape.circle,
            ),
            child: objective.isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Center(
                    child: Text(
                      '${(objective.progress * 100).round()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  objective.title,
                  style: TextStyle(
                    color: objective.isRewardClaimed
                        ? Colors.white60
                        : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    decoration: objective.isRewardClaimed
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  objective.description,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                // Progress bar
                if (!objective.isCompleted)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: objective.progress,
                      backgroundColor: Colors.grey.shade700,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.amber.shade400,
                      ),
                      minHeight: 6,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Reward
          if (canClaim)
            GestureDetector(
              onTap: onClaim,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '+${objective.reward}€',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${objective.reward}€',
                style: TextStyle(
                  color: objective.isRewardClaimed
                      ? Colors.grey
                      : Colors.amber.shade400,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EnvelopeFlapClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height * 0.4);
    path.lineTo(size.width / 2, 0);
    path.lineTo(size.width, size.height * 0.4);
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
