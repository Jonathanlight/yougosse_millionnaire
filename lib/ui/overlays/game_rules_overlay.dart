import 'package:flutter/material.dart';

/// Overlay showing game rules and instructions
class GameRulesOverlay extends StatelessWidget {
  final VoidCallback onClose;

  const GameRulesOverlay({
    super.key,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.8),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.shade700, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade700, Colors.blue.shade900],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.menu_book, color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Regles du Jeu',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: onClose,
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                  // Rules content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSection(
                            icon: Icons.flag,
                            title: 'Objectif',
                            content: 'Construisez une ville prospere et devenez millionnaire ! '
                                'Gerez vos finances, construisez des batiments et faites grandir votre population.',
                            color: Colors.amber,
                          ),

                          _buildSection(
                            icon: Icons.construction,
                            title: 'Construction',
                            content: '• Appuyez sur le bouton marteau pour construire\n'
                                '• Choisissez un batiment dans le menu\n'
                                '• Placez-le sur la carte (vert = valide, rouge = invalide)\n'
                                '• Certains batiments sont en construction pendant quelques secondes',
                            color: Colors.blue,
                          ),

                          _buildSection(
                            icon: Icons.euro,
                            title: 'Revenus',
                            content: '• Les batiments generent des revenus toutes les 60 secondes\n'
                                '• Un minuteur s\'affiche au-dessus du batiment\n'
                                '• Quand il est plein, appuyez pour collecter l\'argent\n'
                                '• Ou appuyez sur votre solde pour tout collecter d\'un coup',
                            color: Colors.green,
                          ),

                          _buildSection(
                            icon: Icons.open_with,
                            title: 'Deplacement',
                            content: '• Maintenez appuye sur un batiment et glissez pour le deplacer\n'
                                '• Ou appuyez sur un batiment puis "Deplacer"\n'
                                '• Le batiment revient a sa place si la position est invalide',
                            color: Colors.purple,
                          ),

                          _buildSection(
                            icon: Icons.delete,
                            title: 'Demolition',
                            content: '• Appuyez sur un batiment puis "Demolir"\n'
                                '• Vous recuperez 50% de la valeur du batiment\n'
                                '• Attention: action irreversible !',
                            color: Colors.red,
                          ),

                          _buildSection(
                            icon: Icons.people,
                            title: 'Population',
                            content: '• Les batiments residentiels attirent des habitants\n'
                                '• Plus de population = plus de revenus potentiels\n'
                                '• La population augmente le niveau de votre ville',
                            color: Colors.cyan,
                          ),

                          _buildSection(
                            icon: Icons.mood,
                            title: 'Bonheur',
                            content: '• Les decorations et monuments augmentent le bonheur\n'
                                '• Un bonheur eleve attire plus d\'habitants\n'
                                '• Equilibrez batiments commerciaux et espaces verts',
                            color: Colors.pink,
                          ),

                          _buildSection(
                            icon: Icons.account_balance,
                            title: 'Credit Bancaire',
                            content: '• Besoin d\'argent ? Demandez un credit a la banque\n'
                                '• Remboursement automatique de 500€/jour\n'
                                '• Attention: votre solde peut devenir negatif !',
                            color: Colors.orange,
                          ),

                          _buildSection(
                            icon: Icons.mail,
                            title: 'Objectifs Hebdomadaires',
                            content: '• Ouvrez l\'enveloppe pour voir vos objectifs\n'
                                '• Completez-les pour gagner des recompenses\n'
                                '• Nouveaux objectifs chaque semaine',
                            color: Colors.amber,
                          ),

                          _buildSection(
                            icon: Icons.cloud,
                            title: 'Meteo',
                            content: '• La meteo change aleatoirement\n'
                                '• Soleil, nuages, pluie, neige et nuit\n'
                                '• C\'est juste pour l\'ambiance !',
                            color: Colors.lightBlue,
                          ),

                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              'Bonne chance, futur millionnaire !',
                              style: TextStyle(
                                color: Colors.amber.shade400,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              color: Colors.grey.shade300,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Button for game rules
class GameRulesButton extends StatelessWidget {
  final VoidCallback onTap;

  const GameRulesButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 37,
        height: 37,
        decoration: BoxDecoration(
          color: Colors.blue.shade700,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.blue.shade300,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.4),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Icon(
          Icons.help_outline,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}
