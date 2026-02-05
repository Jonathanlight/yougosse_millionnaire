import 'package:flutter/material.dart';
import '../../services/avatar_service.dart';
import '../../services/celebration_service.dart';

/// Bottom sheet for selecting an avatar from the available options
class AvatarSelectorBottomSheet extends StatefulWidget {
  final VoidCallback? onAvatarChanged;

  const AvatarSelectorBottomSheet({
    super.key,
    this.onAvatarChanged,
  });

  @override
  State<AvatarSelectorBottomSheet> createState() =>
      _AvatarSelectorBottomSheetState();
}

class _AvatarSelectorBottomSheetState extends State<AvatarSelectorBottomSheet> {
  String? _selectedAvatar;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedAvatar = avatarService.selectedAvatar;
  }

  Future<void> _confirmSelection() async {
    if (_selectedAvatar == null ||
        _selectedAvatar == avatarService.selectedAvatar) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final success = await avatarService.saveSelectedAvatar(_selectedAvatar!);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      widget.onAvatarChanged?.call();

      // Trigger celebration after frame to avoid build conflicts
      WidgetsBinding.instance.addPostFrameCallback((_) {
        celebrationService.celebrate(CelebrationType.avatarChanged);
      });
    } else {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la sauvegarde'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatars = avatarService.availableAvatars;
    final hasChanges = _selectedAvatar != avatarService.selectedAvatar;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Text(
                    '🖼️',
                    style: TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Choisis ton avatar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
            ),

            // Avatar grid
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: GridView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemCount: avatars.length,
                  itemBuilder: (context, index) {
                    final avatar = avatars[index];
                    final isSelected = avatar == _selectedAvatar;
                    final avatarName = avatarService.getAvatarName(avatar);

                    return _AvatarGridItem(
                      avatarPath: avatar,
                      avatarName: avatarName,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          _selectedAvatar = avatar;
                        });
                      },
                    );
                  },
                ),
              ),
            ),

            // Confirm button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: hasChanges && !_isSaving ? _confirmSelection : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade800,
                    disabledForegroundColor: Colors.grey.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              hasChanges ? 'Confirmer' : 'Aucun changement',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual avatar item in the selection grid
class _AvatarGridItem extends StatelessWidget {
  final String avatarPath;
  final String avatarName;
  final bool isSelected;
  final VoidCallback onTap;

  const _AvatarGridItem({
    required this.avatarPath,
    required this.avatarName,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Semantics(
        label: 'Avatar $avatarName',
        selected: isSelected,
        button: true,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: Matrix4.diagonal3Values(
            isSelected ? 1.05 : 1.0,
            isSelected ? 1.05 : 1.0,
            1.0,
          ),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 3,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  avatarPath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade800,
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.grey.shade600,
                      ),
                    );
                  },
                ),
                // Selection indicator overlay
                if (isSelected)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Show the avatar selector bottom sheet
Future<void> showAvatarSelector(BuildContext context,
    {VoidCallback? onAvatarChanged}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AvatarSelectorBottomSheet(
      onAvatarChanged: onAvatarChanged,
    ),
  );
}
