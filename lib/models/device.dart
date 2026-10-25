import 'package:flutter/foundation.dart';

import 'cloud_account.dart';

/// Rooms a device can be assigned to.
enum Room {
  kitchen('Mutfak'),
  entrance('Giriş'),
  bedroom('Yatak Odası'),
  livingRoom('Salon'),
  bathroom('Banyo');

  const Room(this.label);

  final String label;
}

/// How a (simulated) device talks to the home hub.
enum DeviceProtocol {
  zigbee('Zigbee'),
  wifi('Wi-Fi'),
  bluetooth('Bluetooth'),
  cloud('Bulut');

  const DeviceProtocol(this.label);

  final String label;
}

/// Which add-device flow produced a device.
enum DeviceSource {
  qr('QR kod'),
  scan('Cihaz taraması'),
  cloud('Hesap bağlantısı');

  const DeviceSource(this.label);

  final String label;
}

/// Device types the demo knows about.
///
/// Kinds with a [triggeredState] behave like the built-in sensors: they can
/// be triggered from the demo panel and count as daily-life activity.
enum DeviceKind {
  doorSensor('Kapı sensörü', triggeredState: 'Kapı açıldı'),
  motionSensor('Hareket sensörü', triggeredState: 'Hareket algılandı'),
  smartPlug('Akıllı priz', triggeredState: 'Priz açıldı'),
  smartTv('Akıllı TV');

  const DeviceKind(this.label, {this.triggeredState});

  final String label;

  /// State text after a trigger; null when the kind cannot be triggered.
  final String? triggeredState;

  bool get canTrigger => triggeredState != null;
}

/// Signal strength reported by the simulated discovery, 1–4 bars.
enum SignalStrength {
  weak(1, 'zayıf'),
  fair(2, 'orta'),
  good(3, 'iyi'),
  excellent(4, 'çok iyi');

  const SignalStrength(this.bars, this.label);

  final int bars;
  final String label;
}

/// A device found by a pairing flow but not yet added.
@immutable
class DeviceCandidate {
  const DeviceCandidate({
    required this.id,
    required this.name,
    required this.kind,
    required this.protocol,
    required this.room,
    this.signal = SignalStrength.good,
  });

  /// Stable hardware id; adding the same id twice is ignored.
  final String id;
  final String name;
  final DeviceKind kind;
  final DeviceProtocol protocol;

  /// Suggested room; the user can change it before adding.
  final Room room;
  final SignalStrength signal;

  @override
  bool operator ==(Object other) =>
      other is DeviceCandidate &&
      other.id == id &&
      other.name == name &&
      other.kind == kind &&
      other.protocol == protocol &&
      other.room == room &&
      other.signal == signal;

  @override
  int get hashCode => Object.hash(id, name, kind, protocol, room, signal);
}

/// A device the family added through one of the (simulated) flows.
@immutable
class Device {
  const Device({
    required this.id,
    required this.name,
    required this.kind,
    required this.protocol,
    required this.source,
    required this.room,
    this.account,
    this.lastTriggered,
    this.lastState = 'Henüz olay yok',
  });

  final String id;
  final String name;
  final DeviceKind kind;
  final DeviceProtocol protocol;
  final DeviceSource source;
  final Room room;

  /// Cloud account the device was imported from, if any.
  final CloudProvider? account;
  final DateTime? lastTriggered;
  final String lastState;

  /// Every device in this demo is simulated; there is no real connection.
  bool get isSimulated => true;
  bool get canTrigger => kind.canTrigger;
  String get statusLabel => 'Simülasyon · çevrimiçi';

  /// Where the device came from, e.g. `QR kod` or `Google Home hesabı`.
  String get sourceLabel {
    final account = this.account;
    return account == null ? source.label : '${account.label} hesabı';
  }

  Device copyWith({
    String? name,
    Room? room,
    DateTime? lastTriggered,
    String? lastState,
  }) => Device(
    id: id,
    name: name ?? this.name,
    kind: kind,
    protocol: protocol,
    source: source,
    room: room ?? this.room,
    account: account,
    lastTriggered: lastTriggered ?? this.lastTriggered,
    lastState: lastState ?? this.lastState,
  );

  @override
  bool operator ==(Object other) =>
      other is Device &&
      other.id == id &&
      other.name == name &&
      other.kind == kind &&
      other.protocol == protocol &&
      other.source == source &&
      other.room == room &&
      other.account == account &&
      other.lastTriggered == lastTriggered &&
      other.lastState == lastState;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    kind,
    protocol,
    source,
    room,
    account,
    lastTriggered,
    lastState,
  );
}
