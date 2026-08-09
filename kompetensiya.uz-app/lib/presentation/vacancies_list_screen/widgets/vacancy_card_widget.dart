import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

final Map<String, Color> _vacancyCardColors = {
  'blue': AppTheme.primary,
  'orange': AppTheme.secondary,
  'dark': const Color(0xFF212121),
  'green': const Color(0xFF2E7D32),
  'purple': const Color(0xFF6A1B9A),
  'teal': const Color(0xFF00695C),
  'red': const Color(0xFFC62828),
  'indigo': const Color(0xFF283593),
};

class VacancyCardWidget extends StatelessWidget {
  final Map<String, dynamic> vacancyMap;
  final VoidCallback onApply;

  const VacancyCardWidget({
    required this.vacancyMap,
    required this.onApply,
    super.key,
  });

  String _formatSalary(Map<String, dynamic> v) {
    final currency = v['currency'] as String;
    final min = v['salaryMin'] as int;
    final max = v['salaryMax'] as int;

    if (currency == 'USD') {
      return '\$$min\\\$${max}k' == '\$$min\\\$${max}k'
          ? '\$$min–\$$max'
          : '\$$min–\$$max';
    } else {
      // UZS — format in millions
      final minM = (min / 1000000).toStringAsFixed(1);
      final maxM = (max / 1000000).toStringAsFixed(1);
      return '$minM–$maxM mln so\'m';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final v = vacancyMap;
    final cardColor =
        _vacancyCardColors[v['cardColor'] as String? ?? 'blue'] ??
        AppTheme.primary;
    final isUrgent = v['isUrgent'] as bool? ?? false;
    final isNew = v['isNew'] as bool? ?? false;

    return GestureDetector(
      onTap: onApply,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: cardColor.withAlpha(71),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: logo circle + arrow circle
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Company logo circle
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ClipOval(
                      child: CustomImageWidget(
                        imageUrl: v['logoUrl'] as String,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        semanticLabel: v['logoSemanticLabel'] as String,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Company name + badges
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          v['company'] as String,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (isNew)
                              _CardBadge(label: 'Yangi', color: Colors.white),
                            if (isNew && isUrgent) const SizedBox(width: 6),
                            if (isUrgent)
                              _CardBadge(
                                label: 'Shoshilinch',
                                color: Colors.red.shade300,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Arrow circle button
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_outward_rounded,
                      size: 18,
                      color: cardColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Position title
              Text(
                v['position'] as String,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Info chips row
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _InfoChip(
                    icon: Icons.attach_money_rounded,
                    label: _formatSalary(v),
                  ),
                  _InfoChip(
                    icon: Icons.location_on_outlined,
                    label: v['location'] as String,
                  ),
                  _InfoChip(
                    icon: Icons.business_center_outlined,
                    label: v['workType'] as String,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Bottom row: applicants + apply button
              Row(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline_rounded,
                        size: 14,
                        color: Colors.white.withAlpha(179),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${v['applicants']} ariza',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withAlpha(179),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onApply,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Ariza topshirish',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: cardColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(51),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _CardBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(64),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(128), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
