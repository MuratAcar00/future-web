import 'package:flutter/foundation.dart';

import 'sensor_type.dart';

/// What produced a timeline entry.
enum EventKind {
  kitchen('Mutfak'),
  door('Giriş'),
  bedroom('Yatak odası'),
  routineDelayed('Rutin'),
  confirmationRequested('Cihaz'),
  deviceAdded('Cihaz'),
  confirmed('Onay'),
  demoScenario('Demo');

  const EventKind(this.tagLabel);

  final String tagLabel;

  /// Whether the event counts as daily-life activity for the routine engine.
  bool get isSensorActivity =>
      this == kitchen || this == door || this == bedroom;

  static EventKind fromSensor(SensorType type) => switch (type) {
    SensorType.kitchen => kitchen,
    SensorType.entrance => door,
    SensorType.bedroom => bedroom,
  };

  SensorType? get sensorType => switch (this) {
    kitchen => SensorType.kitchen,
    door => SensorType.entrance,
    bedroom => SensorType.bedroom,
    _ => null,
  };
}

enum EventSeverity {
  info(''),
  success('Olumlu'),
  alert('Uyarı');

  const EventSeverity(this.label);

  /// Text equivalent of the severity color (empty for neutral events).
  final String label;
}

/// One immutable entry in the activity timeline.
@immutable
class SensorEvent {
  const SensorEvent({
    required this.id,
    required this.kind,
    required this.title,
    required this.description,
    required this.timestamp,
    this.severity = EventSeverity.info,
    this.isSimulated = true,
    this.sequence = 0,
  });

  /// Deterministic id; the event log ignores duplicates with the same id.
  final String id;
  final EventKind kind;
  final String title;
  final String description;
  final DateTime timestamp;
  final EventSeverity severity;
  final bool isSimulated;

  /// Insertion order, used to keep ordering stable for equal timestamps.
  final int sequence;

  SensorEvent withSequence(int value) => SensorEvent(
    id: id,
    kind: kind,
    title: title,
    description: description,
    timestamp: timestamp,
    severity: severity,
    isSimulated: isSimulated,
    sequence: value,
  );

  /// Newest-first ordering with insertion order as tie breaker.
  static int newestFirst(SensorEvent a, SensorEvent b) {
    final byTime = b.timestamp.compareTo(a.timestamp);
    return byTime != 0 ? byTime : b.sequence.compareTo(a.sequence);
  }

  @override
  bool operator ==(Object other) =>
      other is SensorEvent && other.id == id && other.sequence == sequence;

  @override
  int get hashCode => Object.hash(id, sequence);
}
