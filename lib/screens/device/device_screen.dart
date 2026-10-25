import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/motion.dart';
import '../../core/widgets/logo_mark.dart';
import '../../models/routine_status.dart';
import '../../models/sensor_type.dart';
import '../../providers/app_mode_provider.dart';
import '../../providers/clock_provider.dart';
import '../../providers/routine_provider.dart';
import '../../providers/sensor_provider.dart';

/// Living-space screen for the resident: a large clock, and a full-screen
/// İYİYİM button while the routine engine awaits confirmation.
class DeviceScreen extends StatelessWidget {
  const DeviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final awaiting = context.select<RoutineProvider, bool>(
      (r) => r.status == RoutineStatus.awaitingConfirmation,
    );
    return Scaffold(
      backgroundColor: AppColors.deviceBackground,
      body: AnimatedSwitcher(
        duration: context.motion(AppDurations.deviceSwitch),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.97, end: 1).animate(animation),
            child: child,
          ),
        ),
        child: awaiting
            ? const _ConfirmationPrompt(key: ValueKey('prompt'))
            : const _ClockView(key: ValueKey('clock')),
      ),
    );
  }
}

// ── Clock view ────────────────────────────────────────────────────────────────

class _ClockView extends StatelessWidget {
  const _ClockView({super.key});

  @override
  Widget build(BuildContext context) {
    final time = context.select<ClockProvider, String>((c) => c.formattedTime);
    final date = context.select<ClockProvider, String>((c) => c.formattedDate);
    final status = context.select<RoutineProvider, RoutineStatus>(
      (r) => r.status,
    );
    final confirmed = status == RoutineStatus.confirmedOkay;
    final delayed = status == RoutineStatus.delayed;

    return SafeArea(
      child: Stack(
        children: [
          // Ambient glow behind clock
          const _AmbientGlow(),

          // Main content
          LayoutBuilder(
            builder: (context, constraints) {
              final clockSize = math
                  .min(
                    constraints.maxWidth * 0.24,
                    constraints.maxHeight * 0.34,
                  )
                  .clamp(72.0, 220.0);
              final dateSize = (constraints.maxWidth * 0.025).clamp(18.0, 30.0);

              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Semantics(
                    liveRegion: true,
                    label: 'Saat $time. $date',
                    child: ExcludeSemantics(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Time
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              time,
                              style: TextStyle(
                                fontSize: clockSize,
                                fontWeight: FontWeight.w200,
                                height: 1,
                                letterSpacing: -clockSize * 0.04,
                                color: AppColors.deviceText,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          // Date
                          Text(
                            date,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: dateSize,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 0.4,
                              color: AppColors.deviceMuted,
                            ),
                          ),
                          if (confirmed) ...[
                            const SizedBox(height: AppSpacing.xxl),
                            _ConfirmedBadge(),
                          ],
                          if (delayed) ...[
                            const SizedBox(height: AppSpacing.xxl),
                            _DelayedBadge(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Top bar
          const _DeviceTopBar(foreground: AppColors.deviceMuted),

          // Bottom sensor status
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: _SensorStatusBar(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ambient glow ──────────────────────────────────────────────────────────────

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.85,
            colors: [
              const Color(0xFF0F766E).withAlpha(18), // subtle teal center
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

// ── Status badges (clock view) ────────────────────────────────────────────────

class _ConfirmedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.success.withAlpha(20),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.success.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.success, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Text(
            AppStrings.confirmThanks,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DelayedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.alert.withAlpha(20),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.alert.withAlpha(60)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, color: AppColors.alert, size: 18),
          SizedBox(width: AppSpacing.sm),
          Text(
            'Sabah rutini gecikiyor',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.alert,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom sensor status bar ───────────────────────────────────────────────────

class _SensorStatusBar extends StatelessWidget {
  const _SensorStatusBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final type in SensorType.values) ...[
            _SensorDot(type: type),
            if (type != SensorType.values.last)
              const SizedBox(width: AppSpacing.xl),
          ],
        ],
      ),
    );
  }
}

class _SensorDot extends StatelessWidget {
  const _SensorDot({required this.type});

  final SensorType type;

  @override
  Widget build(BuildContext context) {
    final isOnline = context.select<SensorProvider, bool>(
      (p) => p.sensor(type).isOnline,
    );

    final (icon, label) = switch (type) {
      SensorType.kitchen => (Icons.kitchen_outlined, 'Mutfak'),
      SensorType.entrance => (Icons.door_front_door_outlined, 'Kapı'),
      SensorType.bedroom => (Icons.bedroom_parent_outlined, 'Yatak'),
    };

    return Tooltip(
      message: label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isOnline
                ? AppColors.primaryOnDark.withAlpha(180)
                : AppColors.deviceSubtle,
          ),
          const SizedBox(height: 4),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: isOnline ? AppColors.primaryOnDark.withAlpha(180) : AppColors.deviceSubtle,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _DeviceTopBar extends StatelessWidget {
  const _DeviceTopBar({required this.foreground});

  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const ExcludeSemantics(
            child: LogoMark(
              size: 20,
              color: AppColors.deviceSubtle,
              accent: AppColors.primaryOnDark,
            ),
          ),
          Row(
            children: [
              IconButton(
                tooltip: AppStrings.backToModeSelection,
                onPressed: () =>
                    context.read<AppModeProvider>().returnToModeSelection(),
                icon: Icon(Icons.arrow_back, color: foreground),
              ),
              const Spacer(),
              Tooltip(
                message: 'Bu ekrandaki uyarılar simüle edilen verilere dayanır.',
                child: Text(
                  'Demo · simüle veri',
                  style: TextStyle(fontSize: 12, color: foreground),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Confirmation prompt ───────────────────────────────────────────────────────

class _ConfirmationPrompt extends StatefulWidget {
  const _ConfirmationPrompt({super.key});

  @override
  State<_ConfirmationPrompt> createState() => _ConfirmationPromptState();
}

class _ConfirmationPromptState extends State<_ConfirmationPrompt>
    with TickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: AppDurations.pulse,
  );
  late final AnimationController _ring = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 1,
    end: 1.025,
  ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  late final Animation<double> _ringScale = Tween<double>(
    begin: 1.0,
    end: 1.12,
  ).animate(CurvedAnimation(parent: _ring, curve: Curves.easeOut));
  late final Animation<double> _ringOpacity = Tween<double>(
    begin: 0.35,
    end: 0.0,
  ).animate(CurvedAnimation(parent: _ring, curve: Curves.easeOut));

  bool _submitted = false;

  void _syncPulse(bool reduceMotion) {
    if (reduceMotion || _submitted) {
      if (_pulse.isAnimating) _pulse.stop();
      if (_ring.isAnimating) _ring.stop();
      _pulse.value = 0;
      return;
    }
    if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    if (!_ring.isAnimating) _ring.repeat();
  }

  void _confirm() {
    if (_submitted) return;
    setState(() => _submitted = true);
    context.read<RoutineProvider>().confirmOkay();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _syncPulse(context.reduceMotion);
    final width = MediaQuery.sizeOf(context).width;
    final labelSize = (width * 0.14).clamp(64.0, 160.0);

    return Stack(
      fit: StackFit.expand,
      children: [
        Semantics(
          button: true,
          label: '${AppStrings.confirmButton}. ${AppStrings.confirmHint}',
          excludeSemantics: true,
          onTap: _submitted ? null : _confirm,
          child: Material(
            color: AppColors.deviceButton,
            child: InkWell(
              autofocus: true,
              onTap: _submitted ? null : _confirm,
              splashFactory: NoSplash.splashFactory,
              hoverColor: AppColors.deviceOverlayHover,
              focusColor: AppColors.deviceOverlayFocus,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Pulsing ring behind text
                  if (!context.reduceMotion)
                    AnimatedBuilder(
                      animation: _ring,
                      builder: (context, _) => Transform.scale(
                        scale: _ringScale.value,
                        child: Opacity(
                          opacity: _ringOpacity.value,
                          child: SizedBox(
                            width: labelSize * 1.6,
                            height: labelSize * 1.6,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Main content
                  Center(
                    child: ScaleTransition(
                      scale: _scale,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                AppStrings.confirmButton,
                                style: TextStyle(
                                  fontSize: labelSize,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2,
                                  color: AppColors.deviceText,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              AppStrings.confirmHint,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: (width * 0.022).clamp(15.0, 22.0),
                                color: AppColors.deviceText.withAlpha(200),
                                fontWeight: FontWeight.w300,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: _DeviceTopBar(foreground: AppColors.deviceText),
          ),
        ),
      ],
    );
  }
}
