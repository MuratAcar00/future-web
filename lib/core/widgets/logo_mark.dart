import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import '../theme/app_colors.dart';

/// Minimal brand mark: a quiet house outline with a single resting dot.
class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.size = 40, this.color = AppColors.heading});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${AppStrings.appName} logosu',
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          border: Border.all(color: color, width: size * 0.06),
          borderRadius: BorderRadius.circular(size * 0.28),
        ),
        alignment: Alignment.center,
        child: Container(
          width: size * 0.22,
          height: size * 0.22,
          decoration: const BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
