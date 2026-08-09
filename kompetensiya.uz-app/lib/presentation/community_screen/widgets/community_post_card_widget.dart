import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/custom_image_widget.dart';

class CommunityPostCardWidget extends StatefulWidget {
  final Map<String, dynamic> postMap;

  const CommunityPostCardWidget({required this.postMap, super.key});

  @override
  State<CommunityPostCardWidget> createState() =>
      _CommunityPostCardWidgetState();
}

class _CommunityPostCardWidgetState extends State<CommunityPostCardWidget> {
  bool _liked = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEvent = widget.postMap['type'] == 'event';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primaryContainer,
                  child: Text(
                    (widget.postMap['authorName'] as String? ?? 'A')[0]
                        .toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.postMap['authorName'] as String? ?? '',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        widget.postMap['timeAgo'] as String? ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isEvent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.event_rounded,
                          size: 12,
                          color: AppTheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Tadbir',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppTheme.secondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Post image
          if (widget.postMap['imageUrl'] != null)
            ClipRRect(
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: CustomImageWidget(
                  imageUrl: widget.postMap['imageUrl'] as String,
                  semanticLabel:
                      widget.postMap['semanticLabel'] as String? ?? '',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isEvent) ...[
                  Text(
                    widget.postMap['title'] as String? ?? '',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.postMap['location'] as String? ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 13,
                        color: AppTheme.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.postMap['date'] as String? ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ] else
                  Text(
                    widget.postMap['content'] as String? ?? '',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // Actions row
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _liked = !_liked),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            _liked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            key: ValueKey(_liked),
                            size: 18,
                            color: _liked
                                ? Colors.red
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${(widget.postMap['likes'] as int? ?? 0) + (_liked ? 1 : 0)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.postMap['comments'] ?? 0}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (isEvent)
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Qatnashish',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
