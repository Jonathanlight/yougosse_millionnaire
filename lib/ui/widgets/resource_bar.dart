import 'package:flutter/material.dart';
import '../../utils/helpers.dart';

/// Widget displaying a single resource with icon and value
class ResourceDisplay extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color? iconColor;
  final String? label;
  final VoidCallback? onTap;

  const ResourceDisplay({
    super.key,
    required this.icon,
    required this.value,
    this.iconColor,
    this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      constraints: const BoxConstraints(maxWidth: 120),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: iconColor ?? Colors.white,
            size: 14,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (label != null)
                  Text(
                    label!,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 9,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }
    return content;
  }
}

/// Top resource bar showing money, population, happiness, and level
class ResourceBar extends StatelessWidget {
  final int money;
  final int population;
  final double happiness;
  final int level;
  final double levelProgress;
  final VoidCallback? onMoneyTap;
  final bool isInDebt;
  final bool canTakeCredit;
  final int remainingDebt;
  final VoidCallback? onCreditTap;

  const ResourceBar({
    super.key,
    required this.money,
    required this.population,
    required this.happiness,
    required this.level,
    required this.levelProgress,
    this.onMoneyTap,
    this.isInDebt = false,
    this.canTakeCredit = true,
    this.remainingDebt = 0,
    this.onCreditTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: _MoneyDisplay(
                money: money,
                isInDebt: isInDebt,
                onTap: onMoneyTap,
              ),
            ),
            const SizedBox(width: 4),

            // Bank credit button (if can take credit)
            if (canTakeCredit && onCreditTap != null)
              _BankCreditButton(onTap: onCreditTap!),

            // Remaining debt indicator
            if (!canTakeCredit && remainingDebt > 0) ...[
              const SizedBox(width: 4),
              _DebtIndicator(remainingDebt: remainingDebt),
            ],

            const SizedBox(width: 4),

            // Population
            Flexible(
              child: ResourceDisplay(
                icon: Icons.people,
                value: population.toCompact(),
                iconColor: Colors.blue,
              ),
            ),
            const SizedBox(width: 4),
            _buildLevelIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Level number
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.amber,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$level',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 3),

          // Progress bar
          SizedBox(
            width: 60,
            height: 8,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: levelProgress,
                backgroundColor: Colors.grey.shade800,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getHappinessIcon(double happiness) {
    if (happiness >= 0.8) return Icons.sentiment_very_satisfied;
    if (happiness >= 0.6) return Icons.sentiment_satisfied;
    if (happiness >= 0.4) return Icons.sentiment_neutral;
    if (happiness >= 0.2) return Icons.sentiment_dissatisfied;
    return Icons.sentiment_very_dissatisfied;
  }

  Color _getHappinessColor(double happiness) {
    if (happiness >= 0.8) return Colors.green;
    if (happiness >= 0.6) return Colors.lightGreen;
    if (happiness >= 0.4) return Colors.yellow;
    if (happiness >= 0.2) return Colors.orange;
    return Colors.red;
  }
}

/// Animated money counter
class AnimatedMoneyCounter extends StatefulWidget {
  final int value;
  final Duration duration;

  const AnimatedMoneyCounter({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  State<AnimatedMoneyCounter> createState() => _AnimatedMoneyCounterState();
}

class _AnimatedMoneyCounterState extends State<AnimatedMoneyCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _previousValue = widget.value;
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: _previousValue.toDouble(),
      end: widget.value.toDouble(),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void didUpdateWidget(AnimatedMoneyCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value;
      _animation = Tween<double>(
        begin: _previousValue.toDouble(),
        end: widget.value.toDouble(),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ));
      _controller.forward(from: 0);
    }
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
        return Text(
          _animation.value.round().toCurrency(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        );
      },
    );
  }
}

/// Money display widget with debt indicator
class _MoneyDisplay extends StatelessWidget {
  final int money;
  final bool isInDebt;
  final VoidCallback? onTap;

  const _MoneyDisplay({
    required this.money,
    required this.isInDebt,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      constraints: const BoxConstraints(maxWidth: 120),
      decoration: BoxDecoration(
        color: isInDebt
            ? Colors.red.withValues(alpha: 0.3)
            : Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isInDebt
              ? Colors.red.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.2),
          width: isInDebt ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.euro,
            color: isInDebt ? Colors.red : Colors.green,
            size: 14,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                money.toCurrency(),
                style: TextStyle(
                  color: isInDebt ? Colors.red : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }
    return content;
  }
}

/// Bank credit button
class _BankCreditButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BankCreditButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.amber.shade600, Colors.amber.shade800],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.3),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.account_balance,
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(width: 4),
            const Text(
              'Crédit',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Debt indicator showing remaining debt
class _DebtIndicator extends StatelessWidget {
  final int remainingDebt;

  const _DebtIndicator({required this.remainingDebt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber,
            color: Colors.orange.shade400,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            'Dette: ${remainingDebt.toCurrency()}',
            style: TextStyle(
              color: Colors.orange.shade400,
              fontWeight: FontWeight.bold,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}
