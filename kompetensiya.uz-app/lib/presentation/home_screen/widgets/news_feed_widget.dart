import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

// Map from cardColor string to actual Color
final Map<String, Color> _cardColorMap = {
  'blue': AppTheme.primary,
  'orange': AppTheme.secondary,
  'dark': const Color(0xFF212121),
  'green': const Color(0xFF2E7D32),
  'purple': const Color(0xFF6A1B9A),
  'teal': const Color(0xFF00695C),
  'red': const Color(0xFFC62828),
  'indigo': const Color(0xFF283593),
};

class NewsFeedCardWidget extends StatelessWidget {
  final Map<String, dynamic> newsMap;

  const NewsFeedCardWidget({required this.newsMap, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor =
        _cardColorMap[newsMap['cardColor'] as String? ?? 'blue'] ??
        AppTheme.primary;
    final isUrgent = newsMap['isUrgent'] as bool? ?? false;

    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: cardColor.withAlpha(64),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Background image
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 120,
              child: Opacity(
                opacity: 0.25,
                child: CustomImageWidget(
                  imageUrl: newsMap['imageUrl'] as String,
                  width: 120,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  semanticLabel: newsMap['semanticLabel'] as String,
                ),
              ),
            ),
            // Gradient
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 120,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cardColor, cardColor.withAlpha(0)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(51),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                newsMap['category'] as String,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (isUrgent) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withAlpha(204),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'Muhim',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          newsMap['title'] as String,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 12,
                              color: Colors.white.withAlpha(179),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              newsMap['timeAgo'] as String,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withAlpha(179),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Arrow button
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
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
            ),
          ],
        ),
      ),
    );
  }
}
