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

/// Large status card for the morning routine.
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
          constraints: const BoxConstraints(minHeight: AppLayout.bannerMinHeight),
          padding: EdgeInsets.all(compact ? AppSpacing.xl : AppSpacing.xxl),
          decoration: BoxDecoration(
            color: look.background,
            border: Border.all(color: look.border, width: look.isAlert ? 1.5 : 1),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: AnimatedSwitcher(
            duration: context.motion(AppDurations.state),
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topLeft,
              children: [...previous, ?current],
            ),
            child: _BannerContent(
              key: ValueKey(look.key),
              look: look,
              reason: evaluation.reason,
              compact: compact,
            ),
          ),
        ),
      ),
    );
  }
}

class _BannerContent extends StatelessWidget {
  const _BannerContent({
    super.key,
    required this.look,
    required this.reason,
    required this.compact,
  });

  final _BannerLook look;
  final String reason;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon circle
        Container(
          width: compact ? 44 : 52,
          height: compact ? 44 : 52,
          decoration: BoxDecoration(
            color: look.accent.withValues(alpha: (look.isAlert ? 30 : 20) / 255.0),
            shape: BoxShape.circle,
            border: Border.all(color: look.accent.withValues(alpha: (look.isAlert ? 80 : 50) / 255.0)),
          ),
          child: Icon(look.icon, color: look.accent, size: compact ? 20 : 24),
        ),
        const SizedBox(width: AppSpacing.lg),
        // Text block
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Label pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: look.accent.withValues(alpha: (look.isAlert ? 25 : 15) / 255.0),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  look.label,
                  style: AppTextStyles.micro.copyWith(
                    color: look.accent,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Main message
              Text(
                look.message,
                style: TextStyle(
                  fontSize: compact ? 22 : 28,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  letterSpacing: -0.5,
                  color: look.messageColor,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Reason / detail
              Text(
                reason,
                style: AppTextStyles.secondary.copyWith(
                  color: look.isAlert
                      ? look.accent.withValues(alpha: 180 / 255.0)
                      : AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Look factory ──────────────────────────────────────────────────────────────

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
    this.isAlert = false,
  });

  factory _BannerLook.of(RoutineEvaluation evaluation) {
    switch (evaluation.status) {
      case RoutineStatus.normal:
        final active = evaluation.hasActivityToday;
        return _BannerLook(
          key: active ? 'normal' : 'waiting',
          label: active ? 'DURUM NORMAL' : 'SABAH RUTİNİ BEKLENİYOR',
          message: active ? AppStrings.bannerNormal : AppStrings.bannerWaiting,
          icon: active ? Icons.check_circle_outline : Icons.schedule_outlined,
          accent: active ? AppColors.success : AppColors.muted,
          messageColor: AppColors.heading,
          background: AppColors.background,
          border: AppColors.border,
        );
      case RoutineStatus.delayed:
        return const _BannerLook(
          key: 'delayed',
          label: 'GECİKME UYARISI',
          message: AppStrings.bannerDelayed,
          icon: Icons.warning_amber_rounded,
          accent: AppColors.alert,
          messageColor: AppColors.alert,
          background: AppColors.alertSurface,
          border: AppColors.alertBorder,
          isAlert: true,
        );
      case RoutineStatus.awaitingConfirmation:
        return const _BannerLook(
          key: 'awaiting',
          label: 'UYARI · CİHAZDA ONAY BEKLENİYOR',
          message: AppStrings.bannerDelayed,
          icon: Icons.notification_important_outlined,
          accent: AppColors.alert,
          messageColor: AppColors.alert,
          background: AppColors.alertSurface,
          border: AppColors.alertBorder,
          isAlert: true,
        );
      case RoutineStatus.confirmedOkay:
        return const _BannerLook(
          key: 'confirmed',
          label: 'ONAYLANDI',
          message: AppStrings.bannerConfirmed,
          icon: Icons.verified_outlined,
          accent: AppColors.success,
          messageColor: AppColors.heading,
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
  final bool isAlert;
}
