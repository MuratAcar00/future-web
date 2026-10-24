import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';

/// Shown when the event log is empty.
class EventEmptyState extends StatelessWidget {
  const EventEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: const Column(
        children: [
          Icon(Icons.inbox_outlined, color: AppColors.icon, size: 28),
          SizedBox(height: AppSpacing.md),
          Text('Henüz etkinlik yok', style: AppTextStyles.bodyStrong),
          SizedBox(height: AppSpacing.xs),
          Text(
            'Demo panelindeki sensör butonlarıyla simüle edilmiş bir olay '
            'oluşturabilirsiniz.',
            textAlign: TextAlign.center,
            style: AppTextStyles.secondary,
          ),
        ],
      ),
    );
  }
}
