import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/cloud_account.dart';
import '../models/device.dart';
import '../services/demo_sensor_service.dart';
import '../services/device_pairing_service.dart';
import 'clock_provider.dart';
import 'sensor_provider.dart';

/// Progress of the simulated "Cihazları Tara" discovery.
enum DiscoveryStatus { idle, scanning, done }

/// Devices added through the (simulated) add-device flows and the linked
/// cloud accounts.
///
/// Devices are de-duplicated by hardware id. Adding, removing, linking and
/// unlinking log timeline events through [SensorProvider]. The seed state has
/// no added devices and no linked accounts; [reset] restores it.
class DeviceProvider extends ChangeNotifier {
  DeviceProvider({
    required this._clock,
    required this._sensors,
    this._pairing = const DevicePairingService(),
    this._events = const DemoSensorService(),
  });

  final ClockProvider _clock;
  final SensorProvider _sensors;
  final DevicePairingService _pairing;
  final DemoSensorService _events;

  final List<Device> _devices = [];
  final Map<CloudProvider, CloudAccount> _accounts = {};
  List<Device> _devicesView = const [];

  DiscoveryStatus _discoveryStatus = DiscoveryStatus.idle;
  List<DeviceCandidate> _discovered = const [];
  Timer? _discoveryTimer;
  CloudProvider? _linking;

  /// Bumped by [reset]; pending async work from before a reset is dropped.
  int _generation = 0;
  int _eventSequence = 0;
  bool _disposed = false;

  DevicePairingService get pairing => _pairing;

  /// Added devices in insertion order, unmodifiable.
  List<Device> get devices => _devicesView;

  Device? device(String id) {
    for (final device in _devices) {
      if (device.id == id) return device;
    }
    return null;
  }

  bool isAdded(String id) => device(id) != null;

  List<CloudAccount> get accounts => [
    for (final provider in CloudProvider.values) ?_accounts[provider],
  ];

  CloudAccount? account(CloudProvider provider) => _accounts[provider];
  bool isLinked(CloudProvider provider) => _accounts.containsKey(provider);

  /// Provider currently being linked, if any.
  CloudProvider? get linking => _linking;

  DiscoveryStatus get discoveryStatus => _discoveryStatus;

  /// Devices found by the current / latest discovery, in order.
  List<DeviceCandidate> get discovered => _discovered;

  // QR -------------------------------------------------------------------

  Future<DeviceCandidate> scanDemoQr() => _pairing.scanDemoQr();

  Future<DeviceCandidate> lookupSetupCode(String code) =>
      _pairing.lookupSetupCode(code);

  // Adding / editing -------------------------------------------------------

  /// Adds [candidate] in [room] (defaults to the suggested room). Returns
  /// null when a device with the same id already exists.
  Device? addDevice(
    DeviceCandidate candidate, {
    required DeviceSource source,
    Room? room,
    String? name,
  }) {
    final device = _insert(candidate, source: source, room: room, name: name);
    if (device != null) _publish();
    return device;
  }

  /// Adds several discovered devices; returns the ones actually added.
  List<Device> addDevices(
    Iterable<DeviceCandidate> candidates, {
    required DeviceSource source,
    Map<String, Room> rooms = const {},
  }) {
    final added = [
      for (final candidate in candidates)
        ?_insert(candidate, source: source, room: rooms[candidate.id]),
    ];
    if (added.isNotEmpty) _publish();
    return added;
  }

  /// Renames a device. Blank names are ignored and return false.
  bool rename(String id, String name) {
    final trimmed = name.trim();
    final index = _indexOf(id);
    if (index < 0 || trimmed.isEmpty || _devices[index].name == trimmed) {
      return false;
    }
    _devices[index] = _devices[index].copyWith(name: trimmed);
    _publish();
    return true;
  }

  bool changeRoom(String id, Room room) {
    final index = _indexOf(id);
    if (index < 0 || _devices[index].room == room) return false;
    _devices[index] = _devices[index].copyWith(room: room);
    _publish();
    return true;
  }

  /// Removes a device and logs it. Returns false when it does not exist.
  bool remove(String id) {
    final index = _indexOf(id);
    if (index < 0) return false;
    final device = _devices.removeAt(index);
    final account = device.account;
    if (account != null) {
      final linked = _accounts[account];
      if (linked != null) {
        _accounts[account] = CloudAccount(
          provider: account,
          linkedAt: linked.linkedAt,
          deviceIds: [
            for (final other in linked.deviceIds)
              if (other != id) other,
          ],
        );
      }
    }
    _sensors.addEvent(
      _events.deviceRemoved(device, _clock.currentTime, ++_eventSequence),
    );
    _publish();
    return true;
  }

  /// Simulates a trigger of a device whose kind maps to a sensor. Repeated
  /// triggers within the same minute are ignored and return false.
  bool trigger(String id) {
    final index = _indexOf(id);
    if (index < 0) return false;
    final device = _devices[index];
    final state = device.kind.triggeredState;
    if (state == null) return false;
    final now = _clock.currentTime;
    if (!_sensors.addEvent(_events.deviceActivity(device, now))) return false;
    _devices[index] = device.copyWith(lastTriggered: now, lastState: state);
    _publish();
    return true;
  }

  // Discovery --------------------------------------------------------------

  /// Starts (or restarts) the simulated discovery. Devices that are already
  /// added are not reported again.
  void startDiscovery() {
    _discoveryTimer?.cancel();
    final queue = [
      for (final candidate in _pairing.discoverableDevices)
        if (!isAdded(candidate.id)) candidate,
    ];
    _discoveryStatus = DiscoveryStatus.scanning;
    _discovered = const [];
    notifyListeners();
    _scheduleDiscovery(queue, _pairing.delays.discoveryStart);
  }

  void _scheduleDiscovery(List<DeviceCandidate> queue, Duration wait) {
    _discoveryTimer = Timer(wait, () {
      _discoveryTimer = null;
      if (queue.isEmpty) {
        _discoveryStatus = DiscoveryStatus.done;
      } else {
        _discovered = List.unmodifiable([..._discovered, queue.removeAt(0)]);
        if (queue.isEmpty) {
          _discoveryStatus = DiscoveryStatus.done;
        } else {
          _scheduleDiscovery(queue, _pairing.delays.discoveryInterval);
        }
      }
      notifyListeners();
    });
  }

  /// Stops discovery and forgets its results. Pass `notify: false` when
  /// calling from a widget's `dispose`.
  void clearDiscovery({bool notify = true}) {
    _discoveryTimer?.cancel();
    _discoveryTimer = null;
    if (_discoveryStatus == DiscoveryStatus.idle && _discovered.isEmpty) {
      return;
    }
    _discoveryStatus = DiscoveryStatus.idle;
    _discovered = const [];
    if (notify) notifyListeners();
  }

  // Cloud accounts ---------------------------------------------------------

  /// Simulates linking [provider] and imports its sample devices. Returns
  /// the account, or null if a reset happened meanwhile or another link is
  /// in progress.
  Future<CloudAccount?> linkAccount(CloudProvider provider) async {
    final existing = _accounts[provider];
    if (existing != null) return existing;
    if (_linking != null) return null;
    final generation = _generation;
    _linking = provider;
    notifyListeners();
    final candidates = await _pairing.linkAccount(provider);
    if (_disposed || generation != _generation) return null;
    _linking = null;

    final now = _clock.currentTime;
    final imported = <Device>[];
    for (final candidate in candidates) {
      final device = _insert(
        candidate,
        source: DeviceSource.cloud,
        account: provider,
      );
      if (device != null) imported.add(device);
    }
    final account = CloudAccount(
      provider: provider,
      linkedAt: now,
      deviceIds: [for (final device in imported) device.id],
    );
    _accounts[provider] = account;
    _sensors.addEvent(
      _events.accountLinked(provider, imported.length, now, ++_eventSequence),
    );
    _publish();
    return account;
  }

  /// Removes the link and every device imported from it.
  bool unlinkAccount(CloudProvider provider) {
    final account = _accounts.remove(provider);
    if (account == null) return false;
    final removed = _devices.where((d) => d.account == provider).length;
    _devices.removeWhere((d) => d.account == provider);
    _sensors.addEvent(
      _events.accountUnlinked(
        provider,
        removed,
        _clock.currentTime,
        ++_eventSequence,
      ),
    );
    _publish();
    return true;
  }

  // Reset --------------------------------------------------------------------

  /// Restores the seed state: no added devices, no linked accounts.
  void reset() {
    _generation++;
    _discoveryTimer?.cancel();
    _discoveryTimer = null;
    _devices.clear();
    _accounts.clear();
    _discoveryStatus = DiscoveryStatus.idle;
    _discovered = const [];
    _linking = null;
    _eventSequence = 0;
    _publish();
  }

  Device? _insert(
    DeviceCandidate candidate, {
    required DeviceSource source,
    Room? room,
    String? name,
    CloudProvider? account,
  }) {
    if (isAdded(candidate.id)) return null;
    final trimmed = name?.trim();
    final device = Device(
      id: candidate.id,
      name: trimmed == null || trimmed.isEmpty ? candidate.name : trimmed,
      kind: candidate.kind,
      protocol: candidate.protocol,
      source: source,
      room: room ?? candidate.room,
      account: account,
    );
    _devices.add(device);
    _sensors.addEvent(
      _events.deviceAdded(device, _clock.currentTime, ++_eventSequence),
    );
    return device;
  }

  int _indexOf(String id) => _devices.indexWhere((d) => d.id == id);

  void _publish() {
    _devicesView = List.unmodifiable(_devices);
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _discoveryTimer?.cancel();
    super.dispose();
  }
}
