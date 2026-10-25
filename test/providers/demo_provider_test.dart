import 'package:flutter_test/flutter_test.dart';
import 'package:sessiz_komsu/models/routine_status.dart';
import 'package:sessiz_komsu/models/sensor_event.dart';
import 'package:sessiz_komsu/models/sensor_type.dart';
import 'package:sessiz_komsu/providers/clock_provider.dart';
import 'package:sessiz_komsu/providers/demo_provider.dart';
import 'package:sessiz_komsu/providers/routine_provider.dart';
import 'package:sessiz_komsu/providers/sensor_provider.dart';

import '../helpers/test_app.dart';

typedef _Harness = ({
  ClockProvider clock,
  SensorProvider sensors,
  RoutineProvider routine,
  DemoProvider demo,
});

_Harness _harness({bool seed = true, DateTime? start}) {
  final now = start ?? fixedNow;
  final clock = ClockProvider(now: () => now, autoTick: false);
  final sensors = SensorProvider(initialTime: now, seed: seed);
  final routine = RoutineProvider(clock: clock, sensors: sensors);
  final demo = DemoProvider(clock: clock, sensors: sensors, routine: routine);
  addTearDown(() {
    demo.dispose();
    routine.dispose();
    sensors.dispose();
    clock.dispose();
  });
  return (clock: clock, sensors: sensors, routine: routine, demo: demo);
}

void main() {
  group('DemoProvider', () {
    test('sensor buttons add events and ignore same-minute repeats', () {
      final h = _harness();

      expect(h.demo.triggerSensor(SensorType.entrance), isTrue);
      expect(h.demo.triggerSensor(SensorType.entrance), isFalse);

      expect(h.sensors.events, hasLength(5));
      expect(h.demo.lastAction, contains('zaten tetiklendi'));
    });

    test('alert scenario jumps to the next late morning without activity', () {
      final h = _harness();

      expect(h.demo.startAlertScenario(), isTrue);

      expect(h.clock.currentTime, DateTime(2026, 10, 25, 10, 30));
      expect(h.routine.status, RoutineStatus.awaitingConfirmation);
      final kinds = h.sensors.events.take(3).map((e) => e.kind).toList();
      expect(kinds, [
        EventKind.confirmationRequested,
        EventKind.routineDelayed,
        EventKind.demoScenario,
      ]);
    });

    test('alert scenario uses today when the morning is still quiet', () {
      final h = _harness(seed: false);

      expect(h.demo.alertScenarioTarget(), DateTime(2026, 10, 24, 10, 30));
    });

    test('alert scenario is idempotent while the alert is active', () {
      final h = _harness();
      h.demo.startAlertScenario();
      final before = h.sensors.events.length;
      final time = h.clock.currentTime;

      expect(h.demo.startAlertScenario(), isFalse);

      expect(h.sensors.events, hasLength(before));
      expect(h.clock.currentTime, time);
    });

    test('+1 hour advances demo time and re-evaluates the routine', () {
      final h = _harness(seed: false, start: DateTime(2026, 10, 24, 8, 15));

      h.demo.advanceOneHour();

      expect(h.clock.currentTime, DateTime(2026, 10, 24, 9, 15));
      expect(h.routine.status, RoutineStatus.delayed);
    });

    test('reset restores every provider', () {
      final h = _harness();
      h.demo
        ..triggerSensor(SensorType.entrance)
        ..startAlertScenario();
      h.routine.confirmOkay();
      expect(h.routine.status, RoutineStatus.confirmedOkay);

      h.demo.reset();

      expect(h.clock.isDemoTimeActive, isFalse);
      expect(h.clock.currentTime, fixedNow);
      expect(h.sensors.events, hasLength(4));
      expect(h.routine.status, RoutineStatus.normal);
      expect(h.routine.confirmedAt, isNull);
      expect(h.demo.lastAction, isNull);

      h.demo.reset();
      expect(h.sensors.events, hasLength(4), reason: 'reset is idempotent');
    });
  });
}
