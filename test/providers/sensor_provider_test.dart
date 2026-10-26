import 'package:flutter_test/flutter_test.dart';
import 'package:sessiz_komsu/models/sensor_event.dart';
import 'package:sessiz_komsu/models/sensor_type.dart';
import 'package:sessiz_komsu/providers/sensor_provider.dart';

import '../helpers/test_app.dart';

void main() {
  group('SensorProvider', () {
    test('seeds simulated events relative to the current demo date', () {
      final sensors = SensorProvider(initialTime: fixedNow);
      final events = sensors.events;

      expect(events.map((e) => e.timestamp), [
        DateTime(2026, 10, 24, 7, 30),
        DateTime(2026, 10, 24, 7, 12),
        DateTime(2026, 10, 23, 22, 18),
        DateTime(2026, 10, 23, 21, 45),
      ]);
      expect(events.every((e) => e.isSimulated), isTrue);
      expect(events.first.title, 'Mutfak sensörü tetiklendi.');
      expect(
        sensors.sensor(SensorType.kitchen).lastTriggered,
        DateTime(2026, 10, 24, 7, 30),
      );
      expect(
        sensors.sensor(SensorType.entrance).lastTriggered,
        DateTime(2026, 10, 24, 7, 12),
      );
    });

    test('never seeds events in the future (before 07:30)', () {
      final early = DateTime(2026, 10, 24, 6);
      final sensors = SensorProvider(initialTime: early);

      expect(sensors.events.first.timestamp, DateTime(2026, 10, 23, 7, 30));
      expect(sensors.events.every((e) => e.timestamp.isBefore(early)), isTrue);
    });

    test('trigger inserts newest-first and updates the sensor', () {
      final sensors = SensorProvider(initialTime: fixedNow);
      var notifications = 0;
      sensors.addListener(() => notifications++);

      expect(sensors.trigger(SensorType.entrance, fixedNow), isTrue);

      expect(sensors.events, hasLength(5));
      expect(sensors.events.first.kind, EventKind.door);
      expect(sensors.events.first.title, 'Dış kapı açıldı.');
      expect(sensors.sensor(SensorType.entrance).lastTriggered, fixedNow);
      expect(sensors.sensor(SensorType.entrance).lastState, 'Kapı açıldı');
      expect(notifications, 1);
    });

    test('de-duplicates repeated triggers within the same minute', () {
      final sensors = SensorProvider(initialTime: fixedNow);

      expect(sensors.trigger(SensorType.kitchen, fixedNow), isTrue);
      expect(
        sensors.trigger(
          SensorType.kitchen,
          fixedNow.add(const Duration(seconds: 20)),
        ),
        isFalse,
      );
      expect(sensors.events, hasLength(5));
    });

    test('keeps a stable order for identical timestamps', () {
      final sensors = SensorProvider(initialTime: fixedNow, seed: false);

      sensors
        ..trigger(SensorType.kitchen, fixedNow)
        ..trigger(SensorType.entrance, fixedNow);

      expect(sensors.events.map((e) => e.kind), [
        EventKind.door,
        EventKind.kitchen,
      ]);
    });

    test('an older event does not overwrite a newer sensor state', () {
      final sensors = SensorProvider(initialTime: fixedNow);
      sensors.trigger(SensorType.kitchen, DateTime(2026, 10, 24, 6));

      expect(
        sensors.sensor(SensorType.kitchen).lastTriggered,
        DateTime(2026, 10, 24, 7, 30),
      );
      expect(sensors.events.last.timestamp, DateTime(2026, 10, 23, 21, 45));
    });

    test('reset restores seed data and sensor states', () {
      final sensors = SensorProvider(initialTime: fixedNow);
      sensors.trigger(SensorType.entrance, fixedNow);

      sensors.reset(fixedNow);

      expect(sensors.events, hasLength(4));
      expect(sensors.sensor(SensorType.entrance).lastTriggered, isNull);
      expect(sensors.eventCountOn(fixedNow), 2);
    });
  });
}
