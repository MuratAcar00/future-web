import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/motion.dart';
import '../../models/presentation_step.dart';
import '../../providers/presentation_provider.dart';

/// Marks an area the presentation can explain. While a step highlights
/// other areas this one is dimmed; when it is highlighted it gets a subtle
/// teal outline and the first highlighted area scrolls into view.
class PresentationHighlight extends StatefulWidget {
  const PresentationHighlight({
    super.key,
    required this.target,
    required this.child,
  });

  final PresentationTarget target;
  final Widget child;

  @override
  State<PresentationHighlight> createState() => _PresentationHighlightState();
}

class _PresentationHighlightState extends State<PresentationHighlight> {
  bool _wasLead = false;

  @override
  Widget build(BuildContext context) {
    final focus = context.select<PresentationProvider, Set<PresentationTarget>>(
      (p) => p.focus,
    );
    final highlighted = focus.contains(widget.target);
    final dimmed = focus.isNotEmpty && !highlighted;
    final lead = focus.isNotEmpty && focus.first == widget.target;
    final duration = context.motion(AppDurations.state);

    if (lead && !_wasLead) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Scrollable.maybeOf(context)?.position.ensureVisible(
          context.findRenderObject()!,
          alignment: 0.05,
          duration: duration,
          curve: Curves.easeOutCubic,
        );
      });
    }
    _wasLead = lead;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedOpacity(
          opacity: dimmed ? 0.35 : 1,
          duration: duration,
          child: widget.child,
        ),
        Positioned(
          left: -AppSpacing.sm,
          top: -AppSpacing.sm,
          right: -AppSpacing.sm,
          bottom: -AppSpacing.sm,
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: highlighted ? 1 : 0,
              duration: duration,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary, width: 2),
                  borderRadius: BorderRadius.circular(
                    AppRadius.lg + AppSpacing.sm,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
