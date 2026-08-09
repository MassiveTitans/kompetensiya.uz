import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class QuickAccessWidget extends StatelessWidget {
  final VoidCallback onKurslar;
  final VoidCallback onVakansiyalar;

  const QuickAccessWidget({
    required this.onKurslar,
    required this.onVakansiyalar,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _QuickChip(
            icon: Icons.school_rounded,
            label: 'Kurslar',
            color: AppTheme.primary,
            onTap: onKurslar,
          ),
          const SizedBox(width: 10),
          _QuickChip(
            icon: Icons.work_rounded,
            label: 'Vakansiyalar',
            color: AppTheme.secondary,
            onTap: onVakansiyalar,
          ),
          const SizedBox(width: 10),
          _QuickChip(
            icon: Icons.groups_rounded,
            label: 'Hamjamiyat',
            color: const Color(0xFF6A1B9A),
            onTap: () {},
          ),
          const SizedBox(width: 10),
          _QuickChip(
            icon: Icons.event_rounded,
            label: 'Tadbirlar',
            color: const Color(0xFF00695C),
            onTap: () {},
          ),
          const SizedBox(width: 10),
          _QuickChip(
            icon: Icons.assessment_rounded,
            label: 'Baholash',
            color: const Color(0xFF283593),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withAlpha(51), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
