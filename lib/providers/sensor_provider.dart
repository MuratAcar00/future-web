import 'package:flutter/foundation.dart';

import '../core/utils/date_time_format.dart';
import '../models/sensor.dart';
import '../models/sensor_event.dart';
import '../models/sensor_type.dart';
import '../services/demo_sensor_service.dart';

/// Simulated sensors and the event log shown in the timeline.
///
/// Events are kept newest-first with a stable tie breaker and are
/// de-duplicated by id.
class SensorProvider extends ChangeNotifier {
  SensorProvider({
    required DateTime initialTime,
    this._service = const DemoSensorService(),
    bool seed = true,
  }) {
    _load(initialTime, seed: seed);
  }

  final DemoSensorService _service;
  final List<SensorEvent> _events = [];
  final Set<String> _ids = {};
  final Map<SensorType, Sensor> _sensors = {};
  List<SensorEvent> _eventsView = const [];
  int _sequence = 0;

  /// Newest-first, unmodifiable.
  List<SensorEvent> get events => _eventsView;

  List<Sensor> get sensors => [
    for (final type in SensorType.values) sensor(type),
  ];

  Sensor sensor(SensorType type) => _sensors[type]!;

  int eventCountOn(DateTime day) =>
      _events.where((e) => e.timestamp.isSameDay(day)).length;

  /// Adds [event] unless an event with the same id exists.
  bool addEvent(SensorEvent event) {
    if (!_insert(event)) return false;
    _publish();
    return true;
  }

  /// Simulates a trigger of [type] at [at]. Repeated triggers within the
  /// same minute are ignored and return false.
  bool trigger(SensorType type, DateTime at) =>
      addEvent(_service.sensorEvent(type, at));

  /// Restores seed data relative to [now].
  void reset(DateTime now) {
    _load(now, seed: true);
    notifyListeners();
  }

  void _load(DateTime now, {required bool seed}) {
    _events.clear();
    _ids.clear();
    _sequence = 0;
    for (final type in SensorType.values) {
      _sensors[type] = Sensor(type: type);
    }
    if (seed) {
      final seeds = _service.seedEvents(now)
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      seeds.forEach(_insert);
    }
    _eventsView = List.unmodifiable(_events);
  }

  bool _insert(SensorEvent event) {
    if (_ids.contains(event.id)) return false;
    final entry = event.withSequence(++_sequence);
    var index = 0;
    while (index < _events.length &&
        SensorEvent.newestFirst(_events[index], entry) < 0) {
      index++;
    }
    _events.insert(index, entry);
    _ids.add(entry.id);

    final type = entry.kind.sensorType;
    if (type != null) {
      final current = _sensors[type]!;
      final last = current.lastTriggered;
      if (last == null || !entry.timestamp.isBefore(last)) {
        _sensors[type] = current.recordTrigger(entry.timestamp);
      }
    }
    return true;
  }

  void _publish() {
    _eventsView = List.unmodifiable(_events);
    notifyListeners();
  }
}
