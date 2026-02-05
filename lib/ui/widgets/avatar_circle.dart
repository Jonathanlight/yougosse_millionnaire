import 'package:flutter/material.dart';
import '../../services/avatar_service.dart';

/// Reusable avatar circle widget that displays the user's selected avatar
/// Can be tapped to trigger an action (e.g., open avatar selector)
class AvatarCircle extends StatelessWidget {
  final double radius;
  final VoidCallback? onTap;
  final String? avatarPath;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;

  const AvatarCircle({
    super.key,
    this.radius = 40,
    this.onTap,
    this.avatarPath,
    this.showBorder = true,
    this.borderColor,
    this.borderWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: avatarService,
      builder: (context, _) {
        final currentAvatar = avatarPath ?? avatarService.selectedAvatar;
        final effectiveBorderColor =
            borderColor ?? Theme.of(context).colorScheme.primary;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: showBorder
                  ? Border.all(
                      color: effectiveBorderColor.withValues(alpha: 0.7),
                      width: borderWidth,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: effectiveBorderColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                currentAvatar,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade800,
                    child: Icon(
                      Icons.person,
                      size: radius,
                      color: Colors.grey.shade400,
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Small avatar circle for use in lists, headers, etc.
class AvatarCircleSmall extends StatelessWidget {
  final String? avatarPath;
  final VoidCallback? onTap;

  const AvatarCircleSmall({
    super.key,
    this.avatarPath,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AvatarCircle(
      radius: 20,
      avatarPath: avatarPath,
      onTap: onTap,
      borderWidth: 1.5,
    );
  }
}

/// Large avatar circle for profile pages
class AvatarCircleLarge extends StatelessWidget {
  final String? avatarPath;
  final VoidCallback? onTap;
  final bool showEditIndicator;

  const AvatarCircleLarge({
    super.key,
    this.avatarPath,
    this.onTap,
    this.showEditIndicator = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AvatarCircle(
          radius: 50,
          avatarPath: avatarPath,
          onTap: onTap,
          borderWidth: 3,
        ),
        if (showEditIndicator)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey.shade900,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.edit,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}
