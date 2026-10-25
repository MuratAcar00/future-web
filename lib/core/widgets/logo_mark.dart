import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// Brand mark: a single-stroke geometric house with a soft resting dot
/// inside — a quiet presence. Drawn on a 24-unit grid so it stays crisp from
/// 16px favicons up to large hero sizes, and works in monochrome.
///
/// The web icons in `web/` are generated from the same geometry.
class LogoMark extends StatelessWidget {
  const LogoMark({
    super.key,
    this.size = 40,
    this.color = AppColors.heading,
    this.accent = AppColors.primary,
  }) : tile = false;

  /// App-icon style: brand tile with a white mark.
  const LogoMark.tile({
    super.key,
    this.size = 40,
    this.color = AppColors.onPrimary,
    this.accent = AppColors.primary,
  }) : tile = true;

  final double size;

  /// Stroke color of the house (and the dot on a tile).
  final Color color;

  /// Dot color, or the tile background for [LogoMark.tile].
  final Color accent;
  final bool tile;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${AppStrings.appName} logosu',
      image: true,
      child: CustomPaint(
        size: Size.square(size),
        painter: LogoMarkPainter(color: color, accent: accent, tile: tile),
      ),
    );
  }
}

class LogoMarkPainter extends CustomPainter {
  const LogoMarkPainter({
    required this.color,
    required this.accent,
    this.tile = false,
  });

  final Color color;
  final Color accent;
  final bool tile;

  /// House outline on the 24-unit grid: walls, eaves and a centered peak.
  static const housePoints = [
    Offset(5, 20.5),
    Offset(5, 10.75),
    Offset(12, 4.25),
    Offset(19, 10.75),
    Offset(19, 20.5),
  ];
  static const strokeWidth = 2.25;
  static const dotCenter = Offset(12, 15);
  static const dotRadius = 2.35;

  /// Tile corner radius and the share of the tile the mark occupies.
  static const tileRadius = 0.25;
  static const tileMarkScale = 0.68;

  @override
  void paint(Canvas canvas, Size size) {
    final extent = size.shortestSide;
    if (tile) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(extent * tileRadius),
        ),
        Paint()..color = accent,
      );
      final inset = extent * (1 - tileMarkScale) / 2;
      canvas.translate(inset, inset);
      _paintMark(canvas, extent * tileMarkScale / 24, color, color);
    } else {
      _paintMark(canvas, extent / 24, color, accent);
    }
  }

  void _paintMark(Canvas canvas, double unit, Color stroke, Color dot) {
    final path = Path()
      ..moveTo(housePoints.first.dx * unit, housePoints.first.dy * unit);
    for (final point in housePoints.skip(1)) {
      path.lineTo(point.dx * unit, point.dy * unit);
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * unit
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(dotCenter * unit, dotRadius * unit, Paint()..color = dot);
  }

  @override
  bool shouldRepaint(LogoMarkPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.accent != accent ||
      oldDelegate.tile != tile;
}

/// Mark + "Sessiz Komşu" wordmark.
class LogoLockup extends StatelessWidget {
  const LogoLockup({super.key, this.markSize = 24, this.fontSize = 16});

  final double markSize;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppStrings.appName,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LogoMark(size: markSize),
          SizedBox(width: math.max(AppSpacing.sm, markSize * 0.4)),
          Text(
            AppStrings.appName,
            style: AppTextStyles.wordmark.copyWith(
              fontSize: fontSize,
              letterSpacing: -fontSize * 0.025,
            ),
          ),
        ],
      ),
    );
  }
}
