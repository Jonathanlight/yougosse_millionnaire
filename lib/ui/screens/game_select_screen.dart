import 'package:flutter/material.dart';
import '../../models/cloud_game_save.dart';
import '../../services/auth_service.dart';
import '../../services/cloud_save_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/sync_service.dart';

/// Ecran de selection de partie
class GameSelectScreen extends StatefulWidget {
  final Function(String gameId) onGameSelected;
  final VoidCallback onNewGame;
  final VoidCallback? onLogout;

  const GameSelectScreen({
    super.key,
    required this.onGameSelected,
    required this.onNewGame,
    this.onLogout,
  });

  @override
  State<GameSelectScreen> createState() => _GameSelectScreenState();
}

class _GameSelectScreenState extends State<GameSelectScreen> {
  List<GameMetadata>? _games;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isCreatingGame = false;

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  Future<void> _loadGames() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (connectivityService.isOnline && authService.isAuthenticated) {
        // Charger depuis le cloud
        final result = await cloudSaveService.getGamesList();
        if (result.success) {
          setState(() {
            _games = result.gamesList;
            _isLoading = false;
          });
        } else {
          // Fallback sur cache local
          _games = await syncService.getLocalGamesList();
          setState(() {
            _errorMessage = result.errorMessage;
            _isLoading = false;
          });
        }
      } else {
        // Mode offline - charger depuis le cache
        _games = await syncService.getLocalGamesList();
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _createNewGame() async {
    final name = await _showNameDialog(
      title: 'Nouvelle partie',
      hint: 'Nom de la ville',
      defaultValue: 'Ma Ville ${(_games?.length ?? 0) + 1}',
    );

    if (name == null || name.trim().isEmpty) return;

    setState(() {
      _isCreatingGame = true;
    });

    try {
      final result = await cloudSaveService.createGame(name: name.trim());

      if (!mounted) return;

      if (result.success && result.save != null) {
        await syncService.setCurrentGame(result.save!.gameId);
        widget.onGameSelected(result.save!.gameId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Erreur de création'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingGame = false;
        });
      }
    }
  }

  Future<void> _deleteGame(GameMetadata game) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la partie ?'),
        content: Text(
          'Voulez-vous vraiment supprimer "${game.name}" ?\n\n'
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final result = await cloudSaveService.deleteGame(game.gameId);

      if (!mounted) return;

      if (result.success) {
        _loadGames();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Partie supprimée'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Erreur'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _renameGame(GameMetadata game) async {
    final newName = await _showNameDialog(
      title: 'Renommer la partie',
      hint: 'Nouveau nom',
      defaultValue: game.name,
    );

    if (newName == null || newName.trim().isEmpty || newName == game.name) {
      return;
    }

    try {
      final result = await cloudSaveService.renameGame(
        game.gameId,
        newName.trim(),
      );

      if (!mounted) return;

      if (result.success) {
        _loadGames();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Erreur'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _duplicateGame(GameMetadata game) async {
    final newName = await _showNameDialog(
      title: 'Dupliquer la partie',
      hint: 'Nom de la copie',
      defaultValue: '${game.name} (copie)',
    );

    if (newName == null || newName.trim().isEmpty) return;

    try {
      final result = await cloudSaveService.duplicateGame(
        game.gameId,
        newName.trim(),
      );

      if (!mounted) return;

      if (result.success) {
        _loadGames();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Partie dupliquée'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Erreur'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _showNameDialog({
    required String title,
    required String hint,
    String? defaultValue,
  }) async {
    final controller = TextEditingController(text: defaultValue);

    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showGameOptions(GameMetadata game) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('Jouer'),
              onTap: () {
                Navigator.pop(context);
                syncService.setCurrentGame(game.gameId);
                widget.onGameSelected(game.gameId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Renommer'),
              onTap: () {
                Navigator.pop(context);
                _renameGame(game);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Dupliquer'),
              onTap: () {
                Navigator.pop(context);
                _duplicateGame(game);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Supprimer', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteGame(game);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1a237e),
              Color(0xFF0d47a1),
              Color(0xFF01579b),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isCreatingGame ? null : _createNewGame,
        icon: _isCreatingGame
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.add),
        label: const Text('Nouvelle partie'),
        backgroundColor: const Color(0xFF4caf50),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Avatar utilisateur
          GestureDetector(
            onTap: () => _showUserMenu(),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white24,
              backgroundImage: authService.currentUser?.photoUrl != null
                  ? NetworkImage(authService.currentUser!.photoUrl!)
                  : null,
              child: authService.currentUser?.photoUrl == null
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),

          // Info utilisateur
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authService.currentUser?.displayName ?? 'Joueur',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      connectivityService.isOnline
                          ? Icons.cloud_done
                          : Icons.cloud_off,
                      color: connectivityService.isOnline
                          ? Colors.green.shade300
                          : Colors.orange.shade300,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      connectivityService.isOnline
                          ? 'Synchronisé'
                          : 'Mode hors-ligne',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bouton refresh
          IconButton(
            onPressed: _isLoading ? null : _loadGames,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _showUserMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue.shade100,
                    backgroundImage: authService.currentUser?.photoUrl != null
                        ? NetworkImage(authService.currentUser!.photoUrl!)
                        : null,
                    child: authService.currentUser?.photoUrl == null
                        ? const Icon(Icons.person, size: 30)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authService.currentUser?.displayName ?? 'Joueur',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (authService.currentUser?.email != null)
                          Text(
                            authService.currentUser!.email!,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            if (authService.isAnonymous)
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('Créer un compte'),
                subtitle: const Text('Sauvegardez votre progression'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Afficher dialog de liaison de compte
                },
              ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Déconnexion'),
              onTap: () async {
                Navigator.pop(context);
                await authService.signOut();
                widget.onLogout?.call();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_errorMessage != null && (_games == null || _games!.isEmpty)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white70,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadGames,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_games == null || _games!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videogame_asset_off,
              color: Colors.white.withValues(alpha: 0.5),
              size: 80,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune partie',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Créez votre première ville !',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGames,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        itemCount: _games!.length,
        itemBuilder: (context, index) {
          final game = _games![index];
          return _buildGameCard(game);
        },
      ),
    );
  }

  Widget _buildGameCard(GameMetadata game) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          syncService.setCurrentGame(game.gameId);
          widget.onGameSelected(game.gameId);
        },
        onLongPress: () => _showGameOptions(game),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icone ville
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.location_city,
                  color: Colors.blue.shade700,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),

              // Info partie
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildStatChip(
                          Icons.monetization_on,
                          _formatNumber(game.money),
                          Colors.amber,
                        ),
                        const SizedBox(width: 8),
                        _buildStatChip(
                          Icons.people,
                          '${game.population}',
                          Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        _buildStatChip(
                          Icons.star,
                          'Niv. ${game.level}',
                          Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dernière partie: ${_formatDate(game.lastPlayedAt)}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Menu options
              IconButton(
                onPressed: () => _showGameOptions(game),
                icon: const Icon(Icons.more_vert),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'À l\'instant';
    } else if (diff.inHours < 1) {
      return 'Il y a ${diff.inMinutes} min';
    } else if (diff.inDays < 1) {
      return 'Il y a ${diff.inHours}h';
    } else if (diff.inDays < 7) {
      return 'Il y a ${diff.inDays} j';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
