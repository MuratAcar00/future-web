import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_time_format.dart';
import '../../../core/widgets/tag_chip.dart';
import '../../../models/sensor_event.dart';

/// One row of the activity timeline: time column, rail with dot, content.
class TimelineItem extends StatelessWidget {
  const TimelineItem({
    super.key,
    required this.event,
    required this.now,
    required this.isFirst,
    required this.isLast,
  });

  final SensorEvent event;
  final DateTime now;
  final bool isFirst;
  final bool isLast;

  static const _timeColumnWidth = 64.0;
  static const _railWidth = 24.0;

  /// Vertical center of the dot, aligned with the first title line.
  static const _dotCenterY = 11.0;

  Color get _dotColor => switch (event.severity) {
    EventSeverity.alert => AppColors.alert,
    EventSeverity.success => AppColors.success,
    EventSeverity.info => AppColors.text,
  };

  @override
  Widget build(BuildContext context) {
    final time = TurkishDateFormat.time(event.timestamp);
    final day = TurkishDateFormat.relativeDay(event.timestamp, now);
    final isToday = event.timestamp.isSameDay(now);
    final severity = event.severity.label;

    return MergeSemantics(
      child: Semantics(
        label:
            '$day $time. ${event.title} ${event.description}'
            '${severity.isEmpty ? '' : ' $severity.'}'
            '${event.isSimulated ? ' Simüle edilmiş olay.' : ''}',
        excludeSemantics: true,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: _timeColumnWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      time,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w500,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (!isToday) Text(day, style: AppTextStyles.secondary),
                  ],
                ),
              ),
              SizedBox(
                width: _railWidth,
                child: CustomPaint(
                  painter: _RailPainter(
                    isFirst: isFirst,
                    isLast: isLast,
                    dotColor: _dotColor,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: AppTextStyles.bodyStrong.copyWith(
                          color: event.severity == EventSeverity.alert
                              ? AppColors.alert
                              : AppColors.text,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(event.description, style: AppTextStyles.secondary),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          TagChip(label: event.kind.tagLabel),
                          if (event.severity == EventSeverity.alert)
                            const TagChip.alert(label: 'Uyarı'),
                          if (event.severity == EventSeverity.success)
                            const TagChip.success(label: 'Onay'),
                          if (event.isSimulated)
                            const TagChip(
                              label: 'Simüle',
                              background: AppColors.simulator,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailPainter extends CustomPainter {
  const _RailPainter({
    required this.isFirst,
    required this.isLast,
    required this.dotColor,
  });

  final bool isFirst;
  final bool isLast;
  final Color dotColor;

  static const _dotRadius = 4.5;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    const y = TimelineItem._dotCenterY;
    final line = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;

    // The line passes through every dot center; it starts at the first dot
    // and ends at the last one.
    if (!isFirst) canvas.drawLine(Offset(x, 0), Offset(x, y), line);
    if (!isLast) canvas.drawLine(Offset(x, y), Offset(x, size.height), line);

    canvas
      ..drawCircle(
        Offset(x, y),
        _dotRadius + 2,
        Paint()..color = AppColors.background,
      )
      ..drawCircle(Offset(x, y), _dotRadius, Paint()..color = dotColor);
  }

  @override
  bool shouldRepaint(_RailPainter oldDelegate) =>
      oldDelegate.isFirst != isFirst ||
      oldDelegate.isLast != isLast ||
      oldDelegate.dotColor != dotColor;
}
