import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/motion.dart';
import '../../models/routine_status.dart';
import '../../providers/app_mode_provider.dart';
import '../../providers/clock_provider.dart';
import '../../providers/routine_provider.dart';

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

class _ClockView extends StatelessWidget {
  const _ClockView({super.key});

  @override
  Widget build(BuildContext context) {
    final time = context.select<ClockProvider, String>((c) => c.formattedTime);
    final date = context.select<ClockProvider, String>((c) => c.formattedDate);
    final confirmed = context.select<RoutineProvider, bool>(
      (r) => r.status == RoutineStatus.confirmedOkay,
    );

    return SafeArea(
      child: Stack(
        children: [
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
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              time,
                              style: TextStyle(
                                fontSize: clockSize,
                                fontWeight: FontWeight.w300,
                                height: 1,
                                letterSpacing: -clockSize * 0.03,
                                color: AppColors.deviceText,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            date,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: dateSize,
                              color: AppColors.deviceMuted,
                            ),
                          ),
                          if (confirmed) ...[
                            const SizedBox(height: AppSpacing.xxl),
                            const Text(
                              AppStrings.confirmThanks,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const _DeviceTopBar(foreground: AppColors.deviceMuted),
        ],
      ),
    );
  }
}

class _DeviceTopBar extends StatelessWidget {
  const _DeviceTopBar({required this.foreground});

  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
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
    );
  }
}

class _ConfirmationPrompt extends StatefulWidget {
  const _ConfirmationPrompt({super.key});

  @override
  State<_ConfirmationPrompt> createState() => _ConfirmationPromptState();
}

class _ConfirmationPromptState extends State<_ConfirmationPrompt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: AppDurations.pulse,
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 1,
    end: 1.025,
  ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  bool _submitted = false;

  void _syncPulse(bool reduceMotion) {
    if (reduceMotion || _submitted) {
      if (_pulse.isAnimating) _pulse.stop();
      _pulse.value = 0;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  void _confirm() {
    // Debounce: the first press wins, later taps during the exit transition
    // are ignored.
    if (_submitted) return;
    setState(() => _submitted = true);
    context.read<RoutineProvider>().confirmOkay();
  }

  @override
  void dispose() {
    _pulse.dispose();
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
              hoverColor: const Color(0x14FFFFFF),
              focusColor: const Color(0x1FFFFFFF),
              child: Center(
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
                        const Text(
                          AppStrings.confirmHint,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            color: AppColors.deviceText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
