import '../core/utils/date_time_format.dart';
import '../models/routine_status.dart';
import '../models/sensor_event.dart';

/// Pure, deterministic morning-routine rules. Widgets never decide status.
///
/// For the day of `now`:
/// 1. A confirmation (İYİYİM) on that day → [RoutineStatus.confirmedOkay].
/// 2. Any sensor activity since [windowStart] → [RoutineStatus.normal].
/// 3. Before [delayAfter] → [RoutineStatus.normal] (still waiting).
/// 4. Before [confirmationAfter] → [RoutineStatus.delayed].
/// 5. Otherwise → [RoutineStatus.awaitingConfirmation].
class RoutineEngine {
  const RoutineEngine({
    this.windowStart = const Duration(hours: 5),
    this.delayAfter = const Duration(hours: 9),
    this.confirmationAfter = const Duration(hours: 9, minutes: 30),
  });

  /// Earliest time of day an event counts as the start of the routine.
  final Duration windowStart;

  /// Without activity by this time of day the routine is delayed.
  final Duration delayAfter;

  /// Without activity by this time of day the device asks for confirmation.
  final Duration confirmationAfter;

  /// Time of day used by the demo alert scenario ("late morning").
  Duration get lateMorning => confirmationAfter + const Duration(hours: 1);

  RoutineEvaluation evaluate({
    required DateTime now,
    required Iterable<SensorEvent> events,
    DateTime? confirmedAt,
  }) {
    if (confirmedAt != null &&
        confirmedAt.isSameDay(now) &&
        !confirmedAt.isAfter(now)) {
      return RoutineEvaluation(
        status: RoutineStatus.confirmedOkay,
        reason:
            'Onay ${TurkishDateFormat.time(confirmedAt)} saatinde cihaz '
            'ekranından alındı.',
      );
    }

    final activity = latestActivity(now: now, events: events);
    if (activity != null) {
      return RoutineEvaluation(
        status: RoutineStatus.normal,
        hasActivityToday: true,
        reason:
            'Son hareket: ${activity.tag} · '
            '${TurkishDateFormat.time(activity.timestamp)}',
      );
    }

    final windowLabel = TurkishDateFormat.timeOfDay(windowStart);
    final delayLabel = TurkishDateFormat.timeOfDay(delayAfter);
    final confirmLabel = TurkishDateFormat.timeOfDay(confirmationAfter);

    if (now.isBefore(now.atTimeOfDay(delayAfter))) {
      return RoutineEvaluation(
        status: RoutineStatus.normal,
        reason:
            'Bugün henüz hareket yok. Sabah hareketi için beklenen son '
            'saat: $delayLabel.',
      );
    }
    if (now.isBefore(now.atTimeOfDay(confirmationAfter))) {
      return RoutineEvaluation(
        status: RoutineStatus.delayed,
        reason:
            'Saat $windowLabel sonrası hareket algılanmadı. Cihazdan onay '
            'isteği: $confirmLabel.',
      );
    }
    return RoutineEvaluation(
      status: RoutineStatus.awaitingConfirmation,
      reason:
          'Saat $windowLabel sonrası hareket algılanmadı. Cihaz ekranında '
          'İYİYİM onayı bekleniyor.',
    );
  }

  /// Most recent sensor activity on the day of [now], within the window.
  SensorEvent? latestActivity({
    required DateTime now,
    required Iterable<SensorEvent> events,
  }) {
    final from = now.atTimeOfDay(windowStart);
    SensorEvent? latest;
    for (final event in events) {
      if (!event.kind.isSensorActivity) continue;
      final t = event.timestamp;
      if (t.isBefore(from) || t.isAfter(now)) continue;
      if (latest == null || t.isAfter(latest.timestamp)) latest = event;
    }
    return latest;
  }
}
