import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class VacancySearchBarWidget extends StatefulWidget {
  final ValueChanged<String> onChanged;

  const VacancySearchBarWidget({required this.onChanged, super.key});

  @override
  State<VacancySearchBarWidget> createState() => _VacancySearchBarWidgetState();
}

class _VacancySearchBarWidgetState extends State<VacancySearchBarWidget> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _hasText = _controller.text.isNotEmpty);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: 'Lavozim yoki kompaniya qidiring...',
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 8),
            child: Icon(
              Icons.search_rounded,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 0,
          ),
          suffixIcon: _hasText
              ? GestureDetector(
                  onTap: () {
                    _controller.clear();
                    widget.onChanged('');
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Icon(
                      Icons.cancel_rounded,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : null,
          suffixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 0,
          ),
          border: InputBorder.none,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
