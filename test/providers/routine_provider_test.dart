import 'package:flutter_test/flutter_test.dart';
import 'package:sessiz_komsu/models/routine_status.dart';
import 'package:sessiz_komsu/models/sensor_event.dart';
import 'package:sessiz_komsu/models/sensor_type.dart';
import 'package:sessiz_komsu/providers/clock_provider.dart';
import 'package:sessiz_komsu/providers/routine_provider.dart';
import 'package:sessiz_komsu/providers/sensor_provider.dart';
import 'package:sessiz_komsu/services/routine_engine.dart';

import '../helpers/test_app.dart';

typedef _Harness = ({
  FakeClock fake,
  ClockProvider clock,
  SensorProvider sensors,
  RoutineProvider routine,
});

_Harness _harness(DateTime start, {bool seed = true}) {
  final fake = FakeClock(start);
  final clock = ClockProvider(now: fake.call, autoTick: false);
  final sensors = SensorProvider(initialTime: start, seed: seed);
  final routine = RoutineProvider(clock: clock, sensors: sensors);
  addTearDown(() {
    routine.dispose();
    sensors.dispose();
    clock.dispose();
  });
  return (fake: fake, clock: clock, sensors: sensors, routine: routine);
}

int _count(SensorProvider sensors, EventKind kind) =>
    sensors.events.where((e) => e.kind == kind).length;

void main() {
  group('RoutineEngine', () {
    const engine = RoutineEngine();

    test('ignores activity from previous days and from the future', () {
      final now = DateTime(2026, 10, 24, 9, 10);
      final events = [
        SensorEvent(
          id: 'yesterday',
          kind: EventKind.kitchen,
          title: '',
          description: '',
          timestamp: DateTime(2026, 10, 23, 23),
        ),
        SensorEvent(
          id: 'later',
          kind: EventKind.kitchen,
          title: '',
          description: '',
          timestamp: DateTime(2026, 10, 24, 11),
        ),
      ];
      expect(
        engine.evaluate(now: now, events: events).status,
        RoutineStatus.delayed,
      );
    });

    test('non-sensor events do not count as activity', () {
      final now = DateTime(2026, 10, 24, 9, 45);
      final events = [
        SensorEvent(
          id: 'scenario',
          kind: EventKind.demoScenario,
          title: '',
          description: '',
          timestamp: DateTime(2026, 10, 24, 9),
        ),
      ];
      expect(
        engine.evaluate(now: now, events: events).status,
        RoutineStatus.awaitingConfirmation,
      );
    });
  });

  group('RoutineProvider', () {
    test('is normal when the morning routine has started', () {
      final h = _harness(fixedNow);

      expect(h.routine.status, RoutineStatus.normal);
      expect(h.routine.evaluation.hasActivityToday, isTrue);
      expect(h.routine.evaluation.reason, 'Son aktivite: Mutfak · 07:30');
    });

    test('is normal but waiting before 09:00 without activity', () {
      final h = _harness(DateTime(2026, 10, 24, 8, 30), seed: false);

      expect(h.routine.status, RoutineStatus.normal);
      expect(h.routine.evaluation.hasActivityToday, isFalse);
      expect(h.sensors.events, isEmpty);
    });

    test('re-evaluates on the same clock when demo time advances', () {
      final h = _harness(DateTime(2026, 10, 24, 8, 10), seed: false);

      h.clock.advance(const Duration(hours: 1));
      expect(h.routine.status, RoutineStatus.delayed);
      expect(_count(h.sensors, EventKind.routineDelayed), 1);
      expect(_count(h.sensors, EventKind.confirmationRequested), 0);

      h.clock.advance(const Duration(hours: 1));
      expect(h.routine.status, RoutineStatus.awaitingConfirmation);
      expect(h.routine.isAlertActive, isTrue);
      expect(_count(h.sensors, EventKind.routineDelayed), 1);
      expect(_count(h.sensors, EventKind.confirmationRequested), 1);
    });

    test('repeated evaluation does not duplicate alert events', () {
      final h = _harness(DateTime(2026, 10, 24, 9, 45), seed: false);

      h.routine
        ..evaluate()
        ..evaluate();
      h.fake.now = DateTime(2026, 10, 24, 9, 46);
      h.clock.tick();

      expect(_count(h.sensors, EventKind.routineDelayed), 1);
      expect(_count(h.sensors, EventKind.confirmationRequested), 1);
    });

    test('İYİYİM confirms, records an event and closes the alert', () {
      final h = _harness(DateTime(2026, 10, 24, 9, 45), seed: false);
      h.clock.advance(const Duration(minutes: 5));

      expect(h.routine.confirmOkay(), isTrue);

      expect(h.routine.status, RoutineStatus.confirmedOkay);
      expect(h.routine.isAlertActive, isFalse);
      expect(h.routine.confirmedAt, DateTime(2026, 10, 24, 9, 50));
      final confirmation = h.sensors.events.first;
      expect(confirmation.kind, EventKind.confirmed);
      expect(confirmation.timestamp, DateTime(2026, 10, 24, 9, 50));
      expect(confirmation.severity, EventSeverity.success);

      expect(h.routine.confirmOkay(), isFalse, reason: 'no active alert');
      expect(_count(h.sensors, EventKind.confirmed), 1);
    });

    test('sensor activity during a delay returns to normal', () {
      final h = _harness(DateTime(2026, 10, 24, 9, 10), seed: false);
      expect(h.routine.status, RoutineStatus.delayed);

      h.sensors.trigger(SensorType.kitchen, h.clock.currentTime);

      expect(h.routine.status, RoutineStatus.normal);
      expect(h.routine.evaluation.hasActivityToday, isTrue);
    });

    test('a confirmation only covers its own day', () {
      final h = _harness(DateTime(2026, 10, 24, 9, 45), seed: false);
      h.routine.confirmOkay();

      h.clock.advance(const Duration(days: 1));

      expect(h.routine.status, RoutineStatus.awaitingConfirmation);
    });
  });
}
