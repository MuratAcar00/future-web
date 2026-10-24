import 'package:flutter_test/flutter_test.dart';
import 'package:sessiz_komsu/providers/clock_provider.dart';

import '../helpers/test_app.dart';

void main() {
  group('ClockProvider', () {
    test('formats Turkish date and time', () {
      final clock = ClockProvider(
        now: () => DateTime(2026, 10, 24, 7, 30),
        autoTick: false,
      );
      addTearDown(clock.dispose);

      expect(clock.formattedDate, '24 Ekim 2026, Cumartesi');
      expect(clock.formattedTime, '07:30');
      expect(clock.isDemoTimeActive, isFalse);
    });

    test('keeps real time and demo time separate', () {
      final fake = FakeClock(DateTime(2026, 10, 24, 7, 30));
      final clock = ClockProvider(now: fake.call, autoTick: false);
      addTearDown(clock.dispose);

      clock.advance(const Duration(hours: 1));
      expect(clock.currentTime, DateTime(2026, 10, 24, 8, 30));
      expect(clock.realNow, DateTime(2026, 10, 24, 7, 30));
      expect(clock.demoOffset, const Duration(hours: 1));
      expect(clock.isDemoTimeActive, isTrue);

      fake.now = DateTime(2026, 10, 24, 7, 31);
      clock.tick();
      expect(clock.currentTime, DateTime(2026, 10, 24, 8, 31));

      clock.resetDemoTime();
      expect(clock.currentTime, DateTime(2026, 10, 24, 7, 31));
      expect(clock.isDemoTimeActive, isFalse);
    });

    test('setDemoTime jumps exactly to the target', () {
      final clock = ClockProvider(now: () => fixedNow, autoTick: false);
      addTearDown(clock.dispose);

      final target = DateTime(2026, 10, 25, 10, 30);
      clock.setDemoTime(target);
      expect(clock.currentTime, target);
      expect(clock.formattedDate, '25 Ekim 2026, Pazar');
    });

    test('tick notifies only when the minute changes', () {
      final fake = FakeClock(DateTime(2026, 10, 24, 7, 30, 10));
      final clock = ClockProvider(now: fake.call, autoTick: false);
      addTearDown(clock.dispose);
      var notifications = 0;
      clock.addListener(() => notifications++);

      fake.now = DateTime(2026, 10, 24, 7, 30, 40);
      clock.tick();
      expect(notifications, 0);

      fake.now = DateTime(2026, 10, 24, 7, 31, 1);
      clock.tick();
      expect(notifications, 1);
      expect(clock.formattedTime, '07:31');
    });

    testWidgets('periodic timer ticks and is cancelled on dispose', (
      tester,
    ) async {
      var current = DateTime(2026, 10, 24, 7, 30);
      DateTime now() {
        final value = current;
        current = current.add(const Duration(seconds: 1));
        return value;
      }

      final clock = ClockProvider(now: now);
      var notifications = 0;
      clock.addListener(() => notifications++);

      await tester.pump(const Duration(seconds: 61));
      expect(notifications, greaterThanOrEqualTo(1));

      clock.dispose();
      final afterDispose = current;
      await tester.pump(const Duration(seconds: 10));
      expect(current, afterDispose, reason: 'no ticks after dispose');
    });
  });
}
