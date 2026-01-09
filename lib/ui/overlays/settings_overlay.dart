import 'package:flutter/material.dart';
import '../../game/data/game_state.dart';
import '../../utils/helpers.dart';

/// Settings overlay with game options and stats
class SettingsOverlay extends StatelessWidget {
  final GameState gameState;
  final VoidCallback onClose;
  final VoidCallback onSave;
  final VoidCallback onReset;

  const SettingsOverlay({
    super.key,
    required this.gameState,
    required this.onClose,
    required this.onSave,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.2),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.settings,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Paramètres',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: onClose,
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Stats section
                          const Text(
                            'Statistiques',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),

                          _StatsCard(
                            stats: [
                              _Stat(
                                icon: Icons.account_balance_wallet,
                                label: 'Total gagné',
                                value: gameState.player.totalMoneyEarned
                                    .toCurrency(),
                              ),
                              _Stat(
                                icon: Icons.home_work,
                                label: 'Bâtiments placés',
                                value:
                                    '${gameState.player.buildingsPlaced}',
                              ),
                              _Stat(
                                icon: Icons.star,
                                label: 'Niveau actuel',
                                value: '${gameState.level}',
                              ),
                              _Stat(
                                icon: Icons.people,
                                label: 'Population',
                                value: gameState.population.toCompact(),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // City stats
                          const Text(
                            'Aperçu de la ville',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),

                          _StatsCard(
                            stats: [
                              _Stat(
                                icon: Icons.grid_on,
                                label: 'Taille de la ville',
                                value:
                                    '${gameState.city.width}x${gameState.city.height}',
                              ),
                              _Stat(
                                icon: Icons.domain,
                                label: 'Total bâtiments',
                                value: '${gameState.city.buildings.length}',
                              ),
                              _Stat(
                                icon: Icons.trending_up,
                                label: 'Revenus/min',
                                value: '${gameState.revenuePerMinute}€',
                              ),
                              _Stat(
                                icon: Icons.sentiment_satisfied,
                                label: 'Bonheur',
                                value:
                                    '${(gameState.happiness * 100).round()}%',
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Actions',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Save button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                onSave();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Partie sauvegardée !'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.save),
                              label: const Text('Sauvegarder'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Reset button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _showResetConfirmation(context),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Nouvelle partie'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.orange,
                                side: const BorderSide(color: Colors.orange),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  'Yougosse Millionaire',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'v1.0.0',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          'Nouvelle partie ?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Cela supprimera toute votre progression. Cette action est irréversible !',
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
              onReset();
              onClose();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
  }
}

class _Stat {
  final IconData icon;
  final String label;
  final String value;

  _Stat({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _StatsCard extends StatelessWidget {
  final List<_Stat> stats;

  const _StatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade800,
        ),
      ),
      child: Column(
        children: stats.asMap().entries.map((entry) {
          final index = entry.key;
          final stat = entry.value;

          return Column(
            children: [
              Row(
                children: [
                  Icon(stat.icon, color: Colors.grey, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    stat.label,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    stat.value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (index < stats.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Divider(
                    color: Colors.grey.shade800,
                    height: 1,
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}