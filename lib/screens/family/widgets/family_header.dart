import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/logo_mark.dart';
import '../../../core/widgets/status_dot.dart';
import '../../../core/widgets/tag_chip.dart';
import '../../../providers/clock_provider.dart';
import 'family_page.dart';

/// Home title, honest live-demo label and the current (demo) time.
class FamilyHeader extends StatelessWidget {
  const FamilyHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final date = context.select<ClockProvider, String>((c) => c.formattedDate);
    final time = context.select<ClockProvider, String>((c) => c.formattedTime);
    final demoTime = context.select<ClockProvider, bool>(
      (c) => c.isDemoTimeActive,
    );
    // Phones have no sidebar, so the brand lockup leads the page instead.
    final showLockup = MediaQuery.sizeOf(context).width < AppBreakpoints.mobile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLockup) ...[
          const LogoLockup(markSize: 22, fontSize: 15),
          const SizedBox(height: AppSpacing.xl),
        ],
        Semantics(
          header: true,
          child: Text(AppStrings.homeName, style: familyTitleStyle(context)),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Tooltip(
              message: AppStrings.demoLiveTooltip,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StatusDot(color: AppColors.success),
                  SizedBox(width: AppSpacing.sm),
                  Text(AppStrings.demoLive, style: AppTextStyles.secondary),
                ],
              ),
            ),
            Text('$date · $time', style: AppTextStyles.secondary),
            if (demoTime)
              const Tooltip(
                message: 'Saat demo panelinden ileri alındı.',
                child: TagChip(
                  label: 'DEMO SAATİ',
                  background: AppColors.simulator,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
