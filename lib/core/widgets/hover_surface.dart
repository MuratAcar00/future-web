import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/motion.dart';

/// Flat interactive surface: hover/pressed background, keyboard focus ring,
/// pointer cursor, Enter/Space activation and button semantics.
class HoverSurface extends StatefulWidget {
  const HoverSurface({
    super.key,
    required this.child,
    this.onTap,
    this.color = Colors.transparent,
    this.hoverColor = AppColors.simulator,
    this.pressedColor = AppColors.border,
    this.borderRadius = AppRadius.md,
    this.border,
    this.hoverBorderColor,
    this.padding,
    this.semanticLabel,
    this.tooltip,
    this.selected = false,
    this.autofocus = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final Color hoverColor;
  final Color pressedColor;
  final double borderRadius;
  final BoxBorder? border;

  /// Replaces the color of a uniform [border] while hovered.
  final Color? hoverBorderColor;
  final EdgeInsetsGeometry? padding;
  final String? semanticLabel;
  final String? tooltip;
  final bool selected;
  final bool autofocus;

  @override
  State<HoverSurface> createState() => _HoverSurfaceState();
}

class _HoverSurfaceState extends State<HoverSurface> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final radius = BorderRadius.circular(widget.borderRadius);
    final hoverBorder = widget.hoverBorderColor;
    final border = widget.border;
    final showHoverBorder =
        enabled && _hovered && hoverBorder != null && border is Border;
    final showFocus =
        _focused &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

    Widget result = AnimatedContainer(
      duration: context.motion(AppDurations.hover),
      curve: Curves.easeOut,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: !enabled
            ? widget.color
            : _pressed
            ? widget.pressedColor
            : _hovered
            ? widget.hoverColor
            : widget.color,
        borderRadius: radius,
        border: showHoverBorder
            ? Border.all(color: hoverBorder, width: border.top.width)
            : border,
      ),
      foregroundDecoration: showFocus
          ? BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: AppColors.focus, width: 2),
            )
          : null,
      child: widget.child,
    );

    result = Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: widget.onTap,
        autofocus: widget.autofocus,
        borderRadius: radius,
        mouseCursor: enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        splashFactory: NoSplash.splashFactory,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onHover: (value) => setState(() => _hovered = value),
        onHighlightChanged: (value) => setState(() => _pressed = value),
        onFocusChange: (value) => setState(() => _focused = value),
        child: result,
      ),
    );

    result = Semantics(
      button: true,
      enabled: enabled,
      selected: widget.selected,
      label: widget.semanticLabel,
      child: result,
    );

    final tooltip = widget.tooltip;
    if (tooltip != null) {
      result = Tooltip(message: tooltip, child: result);
    }
    return result;
  }
}
