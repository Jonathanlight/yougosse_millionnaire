import 'package:flutter/material.dart';
import '../../models/building_model.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

/// Overlay showing detailed information about a selected building
class BuildingInfoOverlay extends StatelessWidget {
  final BuildingModel building;
  final VoidCallback onClose;
  final VoidCallback? onCollect;
  final VoidCallback? onDemolish;
  final VoidCallback? onMove;

  const BuildingInfoOverlay({
    super.key,
    required this.building,
    required this.onClose,
    this.onCollect,
    this.onDemolish,
    this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    final config = building.config;
    final pendingRevenue = building.calculatePendingRevenue();

    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping dialog
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: config.color.withValues(alpha: 0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: config.color.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      // Building icon
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: config.color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: config.color,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            _getBuildingIcon(),
                            color: config.color,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Name and size
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              config.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${config.width}x${config.height} cases',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Close button
                      IconButton(
                        onPressed: onClose,
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(color: Colors.grey),
                  const SizedBox(height: 16),

                  // Stats
                  _StatRow(
                    icon: Icons.euro,
                    label: 'Revenus',
                    value: config.revenuePerMinute > 0
                        ? '${config.revenuePerMinute}€/min'
                        : 'Aucun',
                    valueColor: Colors.green,
                  ),

                  if (config.population > 0)
                    _StatRow(
                      icon: Icons.people,
                      label: 'Population',
                      value: '+${config.population}',
                      valueColor: Colors.blue,
                    ),

                  if (config.happinessBonus != 0)
                    _StatRow(
                      icon: config.happinessBonus > 0
                          ? Icons.sentiment_satisfied
                          : Icons.sentiment_dissatisfied,
                      label: 'Bonheur',
                      value: config.happinessBonus > 0
                          ? '+${(config.happinessBonus * 100).round()}%'
                          : '${(config.happinessBonus * 100).round()}%',
                      valueColor:
                          config.happinessBonus > 0 ? Colors.yellow : Colors.red,
                    ),

                  _StatRow(
                    icon: Icons.calendar_today,
                    label: 'Placé',
                    value: _formatDate(building.placedAt),
                    valueColor: Colors.grey.shade300,
                  ),

                  if (pendingRevenue > 0) ...[
                    const SizedBox(height: 16),
                    const Divider(color: Colors.grey),
                    const SizedBox(height: 16),

                    // Pending revenue
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.savings,
                            color: Colors.green.shade400,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Prêt à collecter',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  pendingRevenue.toCurrency(),
                                  style: TextStyle(
                                    color: Colors.green.shade400,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Action buttons
                  Row(
                    children: [
                      if (pendingRevenue > 0 && onCollect != null)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              onCollect?.call();
                              onClose();
                            },
                            icon: const Icon(Icons.monetization_on),
                            label: const Text('Collecter'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),

                      if (pendingRevenue > 0 && onMove != null)
                        const SizedBox(width: 8),

                      // Move button
                      if (onMove != null)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Call onMove first, then close (onMove handles closing)
                              onMove?.call();
                            },
                            icon: const Icon(Icons.open_with),
                            label: const Text('Déplacer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),

                      if (onDemolish != null)
                        const SizedBox(width: 8),

                      if (onDemolish != null)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              _showDemolishConfirmation(context);
                            },
                            icon: const Icon(Icons.delete_forever),
                            label: const Text('Démolir'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getBuildingIcon() {
    // Use category-based icons
    switch (building.config.category) {
      case BuildingCategory.residential:
        return Icons.home;
      case BuildingCategory.commercial:
        return Icons.store;
      case BuildingCategory.industrial:
        return Icons.factory;
      case BuildingCategory.decoration:
        return Icons.park;
      case BuildingCategory.monument:
        return Icons.account_balance;
      case BuildingCategory.infrastructure:
        return Icons.route;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 0) {
      return 'il y a ${diff.inDays}j';
    } else if (diff.inHours > 0) {
      return 'il y a ${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return 'il y a ${diff.inMinutes}m';
    } else {
      return 'À l\'instant';
    }
  }

  void _showDemolishConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          'Démolir le bâtiment ?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir démolir ce ${building.config.name} ? Vous ne serez pas remboursé.',
          style: TextStyle(color: Colors.grey.shade300),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDemolish?.call();
              onClose();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Démolir'),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
