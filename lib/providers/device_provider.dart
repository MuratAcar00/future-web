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

  /// Returns the number of simulated devices imported for [account].
  int importedDeviceCount(String account) =>
      _devices.where((d) => d.provider == account).length;

  bool linkAccount(String account) {
    if (!_linkedAccounts.add(account)) return false;
    final imported = switch (account) {
      'Google Home' => const [
        ConnectedDevice(
          id: 'google-home-salon-plug',
          name: 'Salon akıllı prizi',
          category: 'Akıllı priz',
          room: 'Salon',
          method: DeviceConnectionMethod.cloud,
          provider: 'Google Home',
        ),
        ConnectedDevice(
          id: 'google-home-kitchen-light',
          name: 'Mutfak tavan lambası',
          category: 'Akıllı lamba',
          room: 'Mutfak',
          method: DeviceConnectionMethod.cloud,
          provider: 'Google Home',
        ),
        ConnectedDevice(
          id: 'google-home-thermostat',
          name: 'Akıllı termostat',
          category: 'Termostat',
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
        ConnectedDevice(
          id: 'alexa-bedroom-plug',
          name: 'Yatak odası prizi',
          category: 'Akıllı priz',
          room: 'Yatak odası',
          method: DeviceConnectionMethod.cloud,
          provider: 'Amazon Alexa',
        ),
      ],
      'Apple HomeKit' => const [
        ConnectedDevice(
          id: 'homekit-bathroom-light',
          name: 'Banyo aydınlatması',
          category: 'Akıllı lamba',
          room: 'Banyo',
          method: DeviceConnectionMethod.cloud,
          provider: 'Apple HomeKit',
        ),
        ConnectedDevice(
          id: 'homekit-door-lock',
          name: 'Akıllı kapı kilidi',
          category: 'Akıllı kilit',
          room: 'Giriş',
          method: DeviceConnectionMethod.cloud,
          provider: 'Apple HomeKit',
        ),
      ],
      'Siemens KNX' => const [
        ConnectedDevice(
          id: 'knx-heating-controller',
          name: 'Merkezi ısıtma kontrolör',
          category: 'KNX aktüatör',
          room: 'Teknik oda',
          method: DeviceConnectionMethod.cloud,
          provider: 'Siemens KNX',
        ),
        ConnectedDevice(
          id: 'knx-blind-motor',
          name: 'Salon panjur motoru',
          category: 'KNX panjur',
          room: 'Salon',
          method: DeviceConnectionMethod.cloud,
          provider: 'Siemens KNX',
        ),
        ConnectedDevice(
          id: 'knx-light-scene',
          name: 'Sahne kontrolcüsü',
          category: 'KNX ışık',
          room: 'Salon',
          method: DeviceConnectionMethod.cloud,
          provider: 'Siemens KNX',
        ),
      ],
      'Bosch Smart Home' => const [
        ConnectedDevice(
          id: 'bosch-hall-motion',
          name: 'Koridor hareket sensörü',
          category: 'Hareket sensörü',
          room: 'Koridor',
          method: DeviceConnectionMethod.cloud,
          provider: 'Bosch Smart Home',
        ),
        ConnectedDevice(
          id: 'bosch-window-contact',
          name: 'Pencere kontak sensörü',
          category: 'Kontak sensörü',
          room: 'Yatak odası',
          method: DeviceConnectionMethod.cloud,
          provider: 'Bosch Smart Home',
        ),
      ],
      'Somfy' => const [
        ConnectedDevice(
          id: 'somfy-salon-curtain',
          name: 'Salon perdesi',
          category: 'Motorlu perde',
          room: 'Salon',
          method: DeviceConnectionMethod.cloud,
          provider: 'Somfy',
        ),
        ConnectedDevice(
          id: 'somfy-bedroom-blind',
          name: 'Yatak odası güneşlik',
          category: 'Motorlu stor',
          room: 'Yatak odası',
          method: DeviceConnectionMethod.cloud,
          provider: 'Somfy',
        ),
      ],
      'Philips Hue' => const [
        ConnectedDevice(
          id: 'hue-kitchen-bulb',
          name: 'Mutfak tezgah lambası',
          category: 'Akıllı ampul',
          room: 'Mutfak',
          method: DeviceConnectionMethod.cloud,
          provider: 'Philips Hue',
        ),
        ConnectedDevice(
          id: 'hue-salon-strip',
          name: 'Salon LED şerit',
          category: 'LED şerit',
          room: 'Salon',
          method: DeviceConnectionMethod.cloud,
          provider: 'Philips Hue',
        ),
        ConnectedDevice(
          id: 'hue-bedside-lamp',
          name: 'Başucu lambası',
          category: 'Akıllı ampul',
          room: 'Yatak odası',
          method: DeviceConnectionMethod.cloud,
          provider: 'Philips Hue',
        ),
      ],
      'IKEA Trådfri' => const [
        ConnectedDevice(
          id: 'tradfri-study-bulb',
          name: 'Çalışma odası ampulü',
          category: 'Akıllı ampul',
          room: 'Çalışma odası',
          method: DeviceConnectionMethod.cloud,
          provider: 'IKEA Trådfri',
        ),
        ConnectedDevice(
          id: 'tradfri-desk-lamp',
          name: 'Masa lambası',
          category: 'Akıllı lamba',
          room: 'Çalışma odası',
          method: DeviceConnectionMethod.cloud,
          provider: 'IKEA Trådfri',
        ),
      ],
      'Tuya / Smart Life' => const [
        ConnectedDevice(
          id: 'tuya-kitchen-plug',
          name: 'Mutfak çoklu priz',
          category: 'Akıllı priz',
          room: 'Mutfak',
          method: DeviceConnectionMethod.cloud,
          provider: 'Tuya / Smart Life',
        ),
        ConnectedDevice(
          id: 'tuya-bathroom-humidity',
          name: 'Banyo nem sensörü',
          category: 'Ortam sensörü',
          room: 'Banyo',
          method: DeviceConnectionMethod.cloud,
          provider: 'Tuya / Smart Life',
        ),
        ConnectedDevice(
          id: 'tuya-hallway-camera',
          name: 'Giriş hareket algılayıcı',
          category: 'Hareket sensörü',
          room: 'Giriş',
          method: DeviceConnectionMethod.cloud,
          provider: 'Tuya / Smart Life',
        ),
      ],
      'SmartThings' => const [
        ConnectedDevice(
          id: 'smartthings-bedroom-sensor',
          name: 'Yatak odası sensörü',
          category: 'Çok fonksiyonlu sensör',
          room: 'Yatak odası',
          method: DeviceConnectionMethod.cloud,
          provider: 'SmartThings',
        ),
        ConnectedDevice(
          id: 'smartthings-hub-plug',
          name: 'Akıllı priz izleyici',
          category: 'Enerji izleme prizi',
          room: 'Salon',
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
