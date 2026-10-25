import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sessiz_komsu/models/app_mode.dart';
import 'package:sessiz_komsu/models/presentation_step.dart';
import 'package:sessiz_komsu/models/routine_status.dart';
import 'package:sessiz_komsu/models/sensor_event.dart';
import 'package:sessiz_komsu/providers/app_mode_provider.dart';
import 'package:sessiz_komsu/providers/clock_provider.dart';
import 'package:sessiz_komsu/providers/demo_provider.dart';
import 'package:sessiz_komsu/providers/device_provider.dart';
import 'package:sessiz_komsu/providers/presentation_provider.dart';
import 'package:sessiz_komsu/providers/routine_provider.dart';
import 'package:sessiz_komsu/providers/sensor_provider.dart';

import '../helpers/test_app.dart';

typedef _Harness = ({
  AppModeProvider appMode,
  ClockProvider clock,
  SensorProvider sensors,
  RoutineProvider routine,
  PresentationProvider presentation,
});

_Harness _harness() {
  final appMode = AppModeProvider();
  final clock = ClockProvider(now: () => fixedNow, autoTick: false);
  final sensors = SensorProvider(initialTime: fixedNow);
  final routine = RoutineProvider(clock: clock, sensors: sensors);
  final devices = DeviceProvider(clock: clock, sensors: sensors);
  final demo = DemoProvider(
    clock: clock,
    sensors: sensors,
    routine: routine,
    devices: devices,
  );
  final presentation = PresentationProvider(
    appMode: appMode,
    clock: clock,
    demo: demo,
    routine: routine,
  );
  addTearDown(() {
    presentation.dispose();
    demo.dispose();
    devices.dispose();
    routine.dispose();
    sensors.dispose();
    clock.dispose();
    appMode.dispose();
  });
  return (
    appMode: appMode,
    clock: clock,
    sensors: sensors,
    routine: routine,
    presentation: presentation,
  );
}

/// Story day is the day after [fixedNow].
final _storyDay = DateTime(2026, 10, 25);

Duration _stepTime(int index) => presentationSteps[index].duration;

List<String> _ids(SensorProvider sensors) => [
  for (final e in sensors.events) e.id,
];

void main() {
  group('PresentationProvider', () {
    test('start resets the demo and opens the first step', () {
      fakeAsync((async) {
        final h = _harness();
        h.clock.advance(const Duration(hours: 3));

        h.presentation.start();

        expect(h.presentation.isActive, isTrue);
        expect(h.presentation.index, 0);
        expect(h.presentation.stepCount, 7);
        expect(h.appMode.mode, AppMode.family);
        expect(
          h.clock.currentTime,
          _storyDay.add(const Duration(hours: 6, minutes: 50)),
        );
        expect(h.routine.status, RoutineStatus.normal);
      });
    });

    test('auto-plays every step in order and stops on the last one', () {
      fakeAsync((async) {
        final h = _harness();
        h.presentation.start();

        async.elapse(_stepTime(0));
        expect(h.presentation.index, 1);
        expect(h.presentation.focus, contains(PresentationTarget.banner));

        async.elapse(_stepTime(1));
        expect(h.presentation.index, 2);
        async.elapse(_stepTime(2) - const Duration(milliseconds: 1));
        final morning = h.sensors.events
            .where(
              (e) =>
                  e.kind.isSensorActivity && e.timestamp.day == _storyDay.day,
            )
            .toList()
            .reversed
            .map((e) => e.kind)
            .toList();
        expect(morning, [EventKind.bedroom, EventKind.kitchen, EventKind.door]);
        expect(h.routine.evaluation.hasActivityToday, isTrue);
        async.elapse(const Duration(milliseconds: 1));

        expect(h.presentation.index, 3);
        expect(h.routine.status, RoutineStatus.normal);
        expect(h.routine.evaluation.hasActivityToday, isFalse);
        async.elapse(_stepTime(3) - const Duration(milliseconds: 1));
        expect(h.routine.status, RoutineStatus.awaitingConfirmation);
        async.elapse(const Duration(milliseconds: 1));

        expect(h.presentation.index, 4);
        expect(h.appMode.mode, AppMode.device);
        async.elapse(_stepTime(4));

        expect(h.presentation.index, 5);
        expect(h.routine.status, RoutineStatus.confirmedOkay);
        expect(h.sensors.events.first.kind, EventKind.confirmed);
        async.elapse(_stepTime(5));

        expect(h.presentation.index, 6);
        expect(h.presentation.isLast, isTrue);
        expect(h.appMode.mode, AppMode.family);
        async.elapse(const Duration(minutes: 2));
        expect(h.presentation.index, 6);
        expect(h.presentation.isActive, isTrue);
      });
    });

    test('pause stops the timer and resume continues', () {
      fakeAsync((async) {
        final h = _harness();
        h.presentation.start();

        h.presentation.pause();
        async.elapse(const Duration(minutes: 1));
        expect(h.presentation.index, 0);
        expect(h.presentation.isPaused, isTrue);
        expect(async.pendingTimers, isEmpty);

        h.presentation.togglePause();
        expect(h.presentation.isPaused, isFalse);
        async.elapse(_stepTime(0));
        expect(h.presentation.index, 1);
      });
    });

    test('next and previous replay state without duplicate events', () {
      fakeAsync((async) {
        final h = _harness();
        h.presentation.start();
        for (var i = 0; i < 5; i++) {
          h.presentation.next();
        }
        expect(h.presentation.index, 5);
        expect(h.routine.status, RoutineStatus.confirmedOkay);
        final straight = _ids(h.sensors);
        expect(straight.toSet().length, straight.length);

        h.presentation.previous();
        expect(h.presentation.index, 4);
        expect(h.routine.status, RoutineStatus.awaitingConfirmation);
        expect(h.appMode.mode, AppMode.device);

        h.presentation.next();
        expect(_ids(h.sensors), straight);

        h.presentation
          ..previous()
          ..previous()
          ..previous();
        expect(h.presentation.index, 2);
        expect(h.routine.status, RoutineStatus.normal);
        expect(h.appMode.mode, AppMode.family);

        h.presentation.previous();
        h.presentation.previous();
        h.presentation.previous();
        expect(h.presentation.index, 0);

        // Only one timer is ever pending.
        expect(async.pendingTimers.length, 1);
      });
    });

    test('next on the last step is a no-op', () {
      fakeAsync((async) {
        final h = _harness();
        h.presentation.start();
        for (var i = 0; i < 10; i++) {
          h.presentation.next();
        }
        expect(h.presentation.index, 6);
        expect(async.pendingTimers, isEmpty);
      });
    });

    test('finish resets the demo and returns to the starting screen', () {
      fakeAsync((async) {
        final h = _harness();
        final seeded = _ids(h.sensors);
        expect(h.appMode.mode, AppMode.onboarding);

        h.presentation.start();
        h.presentation.start(); // idempotent
        async.elapse(const Duration(seconds: 30));
        expect(h.presentation.index, greaterThan(2));

        h.presentation.finish();
        expect(h.presentation.isActive, isFalse);
        expect(h.presentation.focus, isEmpty);
        expect(h.appMode.mode, AppMode.onboarding);
        expect(h.clock.isDemoTimeActive, isFalse);
        expect(h.routine.status, RoutineStatus.normal);
        expect(h.routine.confirmedAt, isNull);
        expect(_ids(h.sensors), seeded);
        expect(async.pendingTimers, isEmpty);
      });
    });

    test('finish returns to the family dashboard when started there', () {
      fakeAsync((async) {
        final h = _harness();
        h.appMode.selectMode(AppMode.family);
        h.presentation.start();
        h.presentation.next();
        h.presentation.next();
        h.presentation.next();
        h.presentation.next();
        expect(h.appMode.mode, AppMode.device);

        h.presentation.finish();
        expect(h.appMode.mode, AppMode.family);
      });
    });
  });
}
