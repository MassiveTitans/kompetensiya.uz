import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class LoginLogoWidget extends StatelessWidget {
  const LoginLogoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primary, Color(0xFF1E88E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withAlpha(77),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Image.asset(
            // Ko'k gradient ustida oq logo
            'assets/images/logo.png',
            fit: BoxFit.contain,
            semanticLabel: 'Istiqbolli Kadrlar logotipi',
          ),
        ),
      ],
    );
  }
}
