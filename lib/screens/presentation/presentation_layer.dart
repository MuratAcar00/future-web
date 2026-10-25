import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/motion.dart';
import '../../core/widgets/tag_chip.dart';
import '../../providers/presentation_provider.dart';

/// Wraps the app (via `MaterialApp.builder`). While the presentation runs the
/// app underneath is driven by the script, so it ignores pointer and focus
/// input, and the caption overlay owns the keyboard.
class PresentationLayer extends StatelessWidget {
  const PresentationLayer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final active = context.select<PresentationProvider, bool>(
      (p) => p.isActive,
    );
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            ignoring: active,
            child: ExcludeFocus(excluding: active, child: child),
          ),
        ),
        if (active)
          // Tooltips need an Overlay; the navigator's one is below this layer.
          Positioned.fill(
            child: Overlay(
              initialEntries: [
                OverlayEntry(builder: (_) => const PresentationCaption()),
              ],
            ),
          ),
      ],
    );
  }
}

/// Caption card: step title, description, counter, progress and controls.
/// Keys: Space pause/resume, ←/→ previous/next, Esc finish.
class PresentationCaption extends StatefulWidget {
  const PresentationCaption({super.key});

  @override
  State<PresentationCaption> createState() => _PresentationCaptionState();
}

class _PresentationCaptionState extends State<PresentationCaption> {
  final _focusNode = FocusNode(debugLabel: 'presentation');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final presentation = context.read<PresentationProvider>();
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.space) {
      presentation.togglePause();
    } else if (key == LogicalKeyboardKey.arrowRight) {
      presentation.next();
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      presentation.previous();
    } else if (key == LogicalKeyboardKey.escape) {
      presentation.finish();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PresentationProvider>();
    final step = p.step;
    final duration = context.motion(AppDurations.state);
    final compact = MediaQuery.sizeOf(context).width < AppBreakpoints.mobile;

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _onKey,
      includeSemantics: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Material(
                color: AppColors.background,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: AppColors.primaryBorder),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      container: true,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(end: p.progress),
                        duration: duration,
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) => LinearProgressIndicator(
                          value: value,
                          minHeight: 3,
                          semanticsLabel:
                              'Sunum ilerlemesi, adım '
                              '${p.index + 1} / ${p.stepCount}',
                          semanticsValue: '${(p.progress * 100).round()}',
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(
                        compact ? AppSpacing.lg : AppSpacing.xl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const TagChip(
                                label: 'SUNUM · SİMÜLE VERİ',
                                background: AppColors.primarySurface,
                                foreground: AppColors.primary,
                                borderColor: AppColors.primaryBorder,
                              ),
                              const Spacer(),
                              Text(
                                '${p.index + 1} / ${p.stepCount}',
                                style: AppTextStyles.secondary.copyWith(
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AnimatedSwitcher(
                            duration: duration,
                            layoutBuilder: (current, previous) => Stack(
                              alignment: Alignment.topLeft,
                              children: [...previous, ?current],
                            ),
                            child: Semantics(
                              key: ValueKey(p.index),
                              liveRegion: true,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    step.title,
                                    style: AppTextStyles.section.copyWith(
                                      fontSize: compact ? 17 : 20,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    step.description,
                                    style: AppTextStyles.body.copyWith(
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _Controls(presentation: p),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.presentation});

  final PresentationProvider presentation;

  @override
  Widget build(BuildContext context) {
    final p = presentation;
    final paused = p.isPaused || p.isLast;
    return Row(
      children: [
        IconButton(
          tooltip: 'Önceki adım (←)',
          onPressed: p.isFirst ? null : p.previous,
          icon: const Icon(Icons.chevron_left),
        ),
        const SizedBox(width: AppSpacing.xs),
        if (!p.isLast)
          FilledButton.icon(
            onPressed: p.togglePause,
            icon: Icon(paused ? Icons.play_arrow : Icons.pause, size: 18),
            label: Text(paused ? 'Devam' : 'Duraklat'),
          ),
        const SizedBox(width: AppSpacing.xs),
        IconButton(
          tooltip: 'Sonraki adım (→)',
          onPressed: p.isLast ? null : p.next,
          icon: const Icon(Icons.chevron_right),
        ),
        const Spacer(),
        Tooltip(
          message: 'Sunumu bitir ve demoyu sıfırla (Esc)',
          child: p.isLast
              ? FilledButton(onPressed: p.finish, child: const Text('Bitir'))
              : OutlinedButton(onPressed: p.finish, child: const Text('Bitir')),
        ),
      ],
    );
  }
}

/// "Sunum Modunu Başlat" — starts the guided walkthrough.
class StartPresentationButton extends StatelessWidget {
  const StartPresentationButton({super.key, this.expand = false});

  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = Tooltip(
      message: AppStrings.presentationTooltip,
      child: FilledButton.icon(
        onPressed: () => context.read<PresentationProvider>().start(),
        icon: const Icon(Icons.play_circle_outline, size: 20),
        label: const Text(AppStrings.presentationStart),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
