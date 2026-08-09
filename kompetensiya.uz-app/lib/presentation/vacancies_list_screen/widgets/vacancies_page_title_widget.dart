import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class VacanciesPageTitleWidget extends StatelessWidget {
  final VoidCallback onFilter;

  const VacanciesPageTitleWidget({required this.onFilter, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            'Vakansiyalar\nBozori',
            style: theme.textTheme.displaySmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: onFilter,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.tune_rounded,
                  size: 14,
                  color: Color(0xFF1A1A2E),
                ),
                const SizedBox(width: 4),
                Text(
                  'Filtr',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
