import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class ProfileMenuItemWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool isDestructive;
  final Color? iconColor;
  final Widget? trailing;

  const ProfileMenuItemWidget({
    required this.icon,
    required this.label,
    this.subtitle,
    this.onTap,
    this.isDestructive = false,
    this.iconColor,
    this.trailing,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = isDestructive
        ? AppTheme.errorColor
        : (iconColor ?? AppTheme.primary);
    final effectiveLabelColor = isDestructive
        ? AppTheme.errorColor
        : theme.colorScheme.onSurface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDestructive
              ? AppTheme.errorColor.withAlpha(13)
              : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDestructive
                    ? AppTheme.errorColor.withAlpha(26)
                    : effectiveIconColor.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: effectiveIconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: effectiveLabelColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing ??
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDestructive
                      ? AppTheme.errorColor.withAlpha(128)
                      : theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
          ],
        ),
      ),
    );
  }
}
