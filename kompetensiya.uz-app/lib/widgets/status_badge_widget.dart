import 'package:flutter/material.dart';

enum BadgeStyle { success, warning, error, info, neutral }

class StatusBadgeWidget extends StatelessWidget {
  final String label;
  final BadgeStyle style;
  final double fontSize;

  const StatusBadgeWidget({
    required this.label,
    this.style = BadgeStyle.neutral,
    this.fontSize = 11,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (style) {
      case BadgeStyle.success:
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        break;
      case BadgeStyle.warning:
        bg = const Color(0xFFFFF3E0);
        fg = const Color(0xFFF57C00);
        break;
      case BadgeStyle.error:
        bg = const Color(0xFFFFEBEE);
        fg = const Color(0xFFC62828);
        break;
      case BadgeStyle.info:
        bg = const Color(0xFFE3F2FD);
        fg = const Color(0xFF1565C0);
        break;
      case BadgeStyle.neutral:
        bg = const Color(0xFFF5F7FA);
        fg = const Color(0xFF5A6478);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
