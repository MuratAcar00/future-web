import 'package:flutter/foundation.dart';

import 'sensor_type.dart';

/// Current snapshot of one simulated sensor.
@immutable
class Sensor {
  const Sensor({
    required this.type,
    this.lastTriggered,
    this.lastState = 'Henüz olay yok',
    this.isSimulated = true,
    this.isOnline = true,
  });

  final SensorType type;
  final DateTime? lastTriggered;
  final String lastState;
  final bool isSimulated;
  final bool isOnline;

  String get id => type.id;
  String get name => type.name;
  String get location => type.location;

  /// Connection status text. Always honest about the simulation.
  String get statusLabel =>
      isSimulated ? 'Simülasyon · çevrimiçi' : 'Çevrimiçi';

  Sensor recordTrigger(DateTime at) => Sensor(
    type: type,
    lastTriggered: at,
    lastState: type.triggeredState,
    isSimulated: isSimulated,
    isOnline: isOnline,
  );

  @override
  bool operator ==(Object other) =>
      other is Sensor &&
      other.type == type &&
      other.lastTriggered == lastTriggered &&
      other.lastState == lastState &&
      other.isSimulated == isSimulated &&
      other.isOnline == isOnline;

  @override
  int get hashCode =>
      Object.hash(type, lastTriggered, lastState, isSimulated, isOnline);
}
