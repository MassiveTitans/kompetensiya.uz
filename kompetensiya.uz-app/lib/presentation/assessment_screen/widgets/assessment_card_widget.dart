import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class AssessmentCardWidget extends StatelessWidget {
  final Map<String, dynamic> assessment;
  final VoidCallback? onTap;

  const AssessmentCardWidget({super.key, required this.assessment, this.onTap});

  Color _getAccentColor(String color) {
    switch (color) {
      case 'blue':
        return AppTheme.cardBlue;
      case 'orange':
        return AppTheme.cardOrange;
      case 'purple':
        return AppTheme.cardPurple;
      case 'teal':
        return AppTheme.cardTeal;
      case 'green':
        return AppTheme.cardGreen;
      case 'indigo':
        return AppTheme.cardIndigo;
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _getAccentColor(assessment['color'] ?? 'blue');
    final bool isCompleted = assessment['isCompleted'] == true;
    final double? score = assessment['score'];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left accent bar + icon
            Container(
              width: 72,
              height: 88,
              decoration: BoxDecoration(
                color: accent.withAlpha(20),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accent.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _resolveIcon(assessment['icon'] ?? 'quiz'),
                      color: accent,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            assessment['title'] ?? '',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.successContainer,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${score?.toInt() ?? 0}%',
                              style: TextStyle(
                                color: AppTheme.success,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          assessment['duration'] ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.help_outline_rounded,
                          size: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${assessment['questions'] ?? 0} ta savol',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withAlpha(20),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            assessment['level'] ?? '',
                            style: TextStyle(
                              color: accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? AppTheme.successContainer
                                : accent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            isCompleted ? 'Qayta topshirish' : 'Boshlash',
                            style: TextStyle(
                              color: isCompleted
                                  ? AppTheme.success
                                  : Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _resolveIcon(String name) {
    switch (name) {
      case 'code':
        return Icons.code_rounded;
      case 'analytics':
        return Icons.analytics_outlined;
      case 'language':
        return Icons.language_rounded;
      case 'design':
        return Icons.design_services_outlined;
      case 'management':
        return Icons.manage_accounts_outlined;
      case 'brain':
        return Icons.psychology_outlined;
      case 'emotion':
        return Icons.favorite_border_rounded;
      case 'stress':
        return Icons.self_improvement_rounded;
      case 'leadership':
        return Icons.groups_outlined;
      case 'motivation':
        return Icons.bolt_outlined;
      default:
        return Icons.quiz_outlined;
    }
  }
}
