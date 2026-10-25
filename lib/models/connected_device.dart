import 'package:flutter/foundation.dart';

enum DeviceConnectionMethod { qrCode, discovery, cloud }

@immutable
class ConnectedDevice {
  const ConnectedDevice({
    required this.id,
    required this.name,
    required this.category,
    required this.room,
    required this.method,
    this.provider,
  });

  final String id;
  final String name;
  final String category;
  final String room;
  final DeviceConnectionMethod method;
  final String? provider;

  String get connectionLabel => switch (method) {
    DeviceConnectionMethod.qrCode => 'Yerel Wi-Fi / Bluetooth',
    DeviceConnectionMethod.discovery => 'Zigbee / yerel ağ',
    DeviceConnectionMethod.cloud => 'Hesap: $provider',
  };
}
