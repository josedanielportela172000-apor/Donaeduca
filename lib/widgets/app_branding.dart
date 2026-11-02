import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// Identidad de la app (logo + nombre) para mostrar en la barra superior.
class AppBranding extends StatelessWidget {
  final String subtitle;
  final bool light;
  final double logoHeight;

  const AppBranding({
    super.key,
    this.subtitle = '',
    this.light = false,
    this.logoHeight = 26,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brandStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: light ? Colors.white : (isDark ? Colors.white : AppColors.dark),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo.png', height: logoHeight),
            const SizedBox(width: 8),
            Text.rich(
              TextSpan(
                text: 'Dona',
                style: brandStyle,
                children: [
                  TextSpan(
                    text: 'Educa',
                    style: brandStyle.copyWith(color: AppColors.accent),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (subtitle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: light ? Colors.white70 : AppColors.grey,
              ),
            ),
          ),
      ],
    );
  }
}