import 'package:flutter/foundation.dart';

import '../models/connected_device.dart';
import '../models/sensor_event.dart';
import 'sensor_provider.dart';

/// Device pairing and cloud account links are local simulations only.
class DeviceProvider extends ChangeNotifier {
  DeviceProvider({required this._sensors, required this._now});

  final SensorProvider _sensors;
  final DateTime Function() _now;
  final List<ConnectedDevice> _devices = [];
  final Set<String> _linkedAccounts = {};

  List<ConnectedDevice> get devices => List.unmodifiable(_devices);
  Set<String> get linkedAccounts => Set.unmodifiable(_linkedAccounts);

  bool addDevice(ConnectedDevice device) {
    if (_devices.any((existing) => existing.id == device.id)) return false;
    _devices.add(device);
    _sensors.addEvent(
      SensorEvent(
        id: 'device-added-${device.id}',
        kind: EventKind.deviceAdded,
        title: '${device.name} eklendi.',
        description:
            '${device.room} · ${device.category} · bağlantı simülasyonu tamamlandı.',
        timestamp: _now(),
      ),
    );
    notifyListeners();
    return true;
  }

  bool linkAccount(String account) {
    if (!_linkedAccounts.add(account)) return false;
    final imported = switch (account) {
      'Google Home' => const [
        ConnectedDevice(
          id: 'google-home-salon',
          name: 'Salon akıllı prizi',
          category: 'Akıllı priz',
          room: 'Salon',
          method: DeviceConnectionMethod.cloud,
          provider: 'Google Home',
        ),
      ],
      'Amazon Alexa' => const [
        ConnectedDevice(
          id: 'alexa-salon-tv',
          name: 'Akıllı TV',
          category: 'Akıllı TV',
          room: 'Salon',
          method: DeviceConnectionMethod.cloud,
          provider: 'Amazon Alexa',
        ),
      ],
      'Bosch Smart Home' => const [
        ConnectedDevice(
          id: 'bosch-entry-door',
          name: 'Giriş kapı sensörü',
          category: 'Kapı sensörü',
          room: 'Giriş',
          method: DeviceConnectionMethod.cloud,
          provider: 'Bosch Smart Home',
        ),
      ],
      'SmartThings' => const [
        ConnectedDevice(
          id: 'smartthings-kitchen-leak',
          name: 'Mutfak su kaçağı sensörü',
          category: 'Su kaçağı sensörü',
          room: 'Mutfak',
          method: DeviceConnectionMethod.cloud,
          provider: 'SmartThings',
        ),
      ],
      _ => const <ConnectedDevice>[],
    };
    for (final device in imported) {
      addDevice(device);
    }
    notifyListeners();
    return true;
  }

  bool unlinkAccount(String account) {
    if (!_linkedAccounts.remove(account)) return false;
    _devices.removeWhere((device) => device.provider == account);
    notifyListeners();
    return true;
  }

  void reset() {
    _devices.clear();
    _linkedAccounts.clear();
    notifyListeners();
  }
}
