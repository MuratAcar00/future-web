import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// Compact uppercase-friendly label with a thin border.
class TagChip extends StatelessWidget {
  const TagChip({
    super.key,
    required this.label,
    this.background = AppColors.background,
    this.foreground = AppColors.muted,
    this.borderColor = AppColors.border,
  });

  const TagChip.alert({super.key, required this.label})
    : background = AppColors.alertSurface,
      foreground = AppColors.alert,
      borderColor = AppColors.alertBorder;

  const TagChip.success({super.key, required this.label})
    : background = AppColors.successSurface,
      foreground = AppColors.success,
      borderColor = AppColors.successBorder;

  final String label;
  final Color background;
  final Color foreground;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: AppTextStyles.micro.copyWith(color: foreground),
      ),
    );
  }
}
