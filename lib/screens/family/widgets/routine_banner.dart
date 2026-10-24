import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/motion.dart';
import '../../../models/routine_status.dart';
import '../../../providers/routine_provider.dart';

/// Large status message for the morning routine. Keeps a stable minimum
/// height so the feed below does not jump between states.
class RoutineBanner extends StatelessWidget {
  const RoutineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final evaluation = context.select<RoutineProvider, RoutineEvaluation>(
      (r) => r.evaluation,
    );
    final look = _BannerLook.of(evaluation);
    final compact = MediaQuery.sizeOf(context).width < AppBreakpoints.mobile;

    return Semantics(
      container: true,
      liveRegion: true,
      label: '${look.label}. ${look.message} ${evaluation.reason}',
      child: ExcludeSemantics(
        child: AnimatedContainer(
          duration: context.motion(AppDurations.state),
          curve: Curves.easeInOut,
          constraints: const BoxConstraints(
            minHeight: AppLayout.bannerMinHeight,
          ),
          padding: EdgeInsets.all(compact ? AppSpacing.xl : AppSpacing.xxl),
          decoration: BoxDecoration(
            color: look.background,
            border: Border.all(color: look.border),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: AnimatedSwitcher(
            duration: context.motion(AppDurations.state),
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topLeft,
              children: [...previous, ?current],
            ),
            child: Column(
              key: ValueKey(look.key),
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(look.icon, size: 16, color: look.accent),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        look.label,
                        style: AppTextStyles.micro.copyWith(color: look.accent),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  look.message,
                  style: TextStyle(
                    fontSize: compact ? 26 : 34,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    letterSpacing: -0.6,
                    color: look.messageColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(evaluation.reason, style: AppTextStyles.secondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BannerLook {
  const _BannerLook({
    required this.key,
    required this.label,
    required this.message,
    required this.icon,
    required this.accent,
    required this.messageColor,
    required this.background,
    required this.border,
  });

  factory _BannerLook.of(RoutineEvaluation evaluation) {
    switch (evaluation.status) {
      case RoutineStatus.normal:
        final active = evaluation.hasActivityToday;
        return _BannerLook(
          key: active ? 'normal' : 'waiting',
          label: active ? 'DURUM NORMAL' : 'SABAH RUTİNİ BEKLENİYOR',
          message: active ? AppStrings.bannerNormal : AppStrings.bannerWaiting,
          icon: active ? Icons.check_circle_outline : Icons.schedule,
          accent: active ? AppColors.success : AppColors.muted,
          messageColor: AppColors.text,
          background: AppColors.background,
          border: AppColors.border,
        );
      case RoutineStatus.delayed:
        return const _BannerLook(
          key: 'delayed',
          label: 'GECİKME',
          message: AppStrings.bannerDelayed,
          icon: Icons.warning_amber_rounded,
          accent: AppColors.alert,
          messageColor: AppColors.alert,
          background: AppColors.alertSurface,
          border: AppColors.alertBorder,
        );
      case RoutineStatus.awaitingConfirmation:
        return const _BannerLook(
          key: 'awaiting',
          label: 'UYARI · CİHAZDA ONAY BEKLENİYOR',
          message: AppStrings.bannerDelayed,
          icon: Icons.warning_amber_rounded,
          accent: AppColors.alert,
          messageColor: AppColors.alert,
          background: AppColors.alertSurface,
          border: AppColors.alertBorder,
        );
      case RoutineStatus.confirmedOkay:
        return const _BannerLook(
          key: 'confirmed',
          label: 'ONAYLANDI',
          message: AppStrings.bannerConfirmed,
          icon: Icons.verified_outlined,
          accent: AppColors.success,
          messageColor: AppColors.text,
          background: AppColors.successSurface,
          border: AppColors.successBorder,
        );
    }
  }

  final String key;
  final String label;
  final String message;
  final IconData icon;
  final Color accent;
  final Color messageColor;
  final Color background;
  final Color border;
}
