import '../models/cloud_account.dart';
import '../models/device.dart';

/// Wait times of the simulated pairing steps. Tests inject [instant].
class DevicePairingDelays {
  const DevicePairingDelays({
    this.qrScan = const Duration(milliseconds: 1400),
    this.codeLookup = const Duration(milliseconds: 700),
    this.discoveryStart = const Duration(milliseconds: 900),
    this.discoveryInterval = const Duration(milliseconds: 800),
    this.cloudLink = const Duration(milliseconds: 1200),
  });

  static const instant = DevicePairingDelays(
    qrScan: Duration.zero,
    codeLookup: Duration.zero,
    discoveryStart: Duration.zero,
    discoveryInterval: Duration.zero,
    cloudLink: Duration.zero,
  );

  final Duration qrScan;
  final Duration codeLookup;
  final Duration discoveryStart;
  final Duration discoveryInterval;
  final Duration cloudLink;
}

/// Simulated pairing. Never uses the camera, Bluetooth, Wi-Fi, Zigbee or any
/// network service: every result is deterministic sample data.
class DevicePairingService {
  const DevicePairingService({this.delays = const DevicePairingDelays()});

  final DevicePairingDelays delays;

  /// Code "read" by the demo QR scan.
  static const demoQrCode = 'SK-BT42-7A19';

  static final _codePattern = RegExp(r'^SK-[A-Z0-9]{4}-[A-Z0-9]{4}$');

  /// Upper-cases and trims user input.
  static String normalizeCode(String raw) => raw.trim().toUpperCase();

  /// Error text for an invalid setup code, null when the format is valid.
  static String? validateSetupCode(String raw) {
    final code = normalizeCode(raw);
    if (code.isEmpty) return 'Kurulum kodunu girin.';
    if (!_codePattern.hasMatch(code)) {
      return 'Kod SK-XXXX-XXXX biçiminde olmalı (harf ve rakam).';
    }
    return null;
  }

  /// Local device described by a valid setup [code]. The same code always
  /// yields the same device, so adding it twice is detected as a duplicate.
  DeviceCandidate candidateForCode(String code) {
    final normalized = normalizeCode(code);
    if (normalized == demoQrCode) {
      return const DeviceCandidate(
        id: 'qr-$demoQrCode',
        name: 'Bluetooth Hareket Sensörü',
        kind: DeviceKind.motionSensor,
        protocol: DeviceProtocol.bluetooth,
        room: Room.livingRoom,
        signal: SignalStrength.excellent,
      );
    }
    const kinds = [
      DeviceKind.doorSensor,
      DeviceKind.motionSensor,
      DeviceKind.smartPlug,
    ];
    final checksum = normalized.codeUnits.fold<int>(0, (a, b) => a + b);
    final kind = kinds[checksum % kinds.length];
    final protocol = checksum.isEven
        ? DeviceProtocol.wifi
        : DeviceProtocol.bluetooth;
    return DeviceCandidate(
      id: 'qr-$normalized',
      name: '${protocol.label} ${kind.label}',
      kind: kind,
      protocol: protocol,
      room: Room.livingRoom,
      signal: SignalStrength.values[checksum % SignalStrength.values.length],
    );
  }

  /// Simulated scan of the demo QR code (no camera access).
  Future<DeviceCandidate> scanDemoQr() async {
    await Future<void>.delayed(delays.qrScan);
    return candidateForCode(demoQrCode);
  }

  /// Simulated lookup of a typed setup code. Throws [FormatException] for
  /// an invalid code.
  Future<DeviceCandidate> lookupSetupCode(String code) async {
    final error = validateSetupCode(code);
    if (error != null) throw FormatException(error);
    await Future<void>.delayed(delays.codeLookup);
    return candidateForCode(code);
  }

  /// Devices the simulated Zigbee / Wi-Fi discovery finds, in order.
  List<DeviceCandidate> get discoverableDevices => const [
    DeviceCandidate(
      id: 'zb-door-00158d0001',
      name: 'Zigbee Kapı Sensörü',
      kind: DeviceKind.doorSensor,
      protocol: DeviceProtocol.zigbee,
      room: Room.entrance,
      signal: SignalStrength.excellent,
    ),
    DeviceCandidate(
      id: 'zb-motion-00158d0002',
      name: 'Zigbee Hareket Sensörü',
      kind: DeviceKind.motionSensor,
      protocol: DeviceProtocol.zigbee,
      room: Room.bathroom,
    ),
    DeviceCandidate(
      id: 'wifi-plug-a4cf12',
      name: 'Akıllı Priz',
      kind: DeviceKind.smartPlug,
      protocol: DeviceProtocol.wifi,
      room: Room.kitchen,
      signal: SignalStrength.fair,
    ),
    DeviceCandidate(
      id: 'wifi-tv-salon',
      name: 'Akıllı TV (Salon)',
      kind: DeviceKind.smartTv,
      protocol: DeviceProtocol.wifi,
      room: Room.livingRoom,
    ),
  ];

  /// Simulated account linking; returns the devices the account "imports".
  Future<List<DeviceCandidate>> linkAccount(CloudProvider provider) async {
    await Future<void>.delayed(delays.cloudLink);
    return cloudDevices(provider);
  }

  /// Sample devices of each cloud platform.
  List<DeviceCandidate> cloudDevices(CloudProvider provider) =>
      switch (provider) {
        CloudProvider.googleHome => const [
          DeviceCandidate(
            id: 'cloud-google-motion-salon',
            name: 'Salon Hareket Sensörü',
            kind: DeviceKind.motionSensor,
            protocol: DeviceProtocol.cloud,
            room: Room.livingRoom,
          ),
          DeviceCandidate(
            id: 'cloud-google-tv-salon',
            name: 'Salon Televizyonu',
            kind: DeviceKind.smartTv,
            protocol: DeviceProtocol.cloud,
            room: Room.livingRoom,
          ),
        ],
        CloudProvider.amazonAlexa => const [
          DeviceCandidate(
            id: 'cloud-alexa-plug-kitchen',
            name: 'Çaydanlık Prizi',
            kind: DeviceKind.smartPlug,
            protocol: DeviceProtocol.cloud,
            room: Room.kitchen,
          ),
        ],
        CloudProvider.boschSmartHome => const [
          DeviceCandidate(
            id: 'cloud-bosch-door-balcony',
            name: 'Balkon Kapısı Sensörü',
            kind: DeviceKind.doorSensor,
            protocol: DeviceProtocol.cloud,
            room: Room.livingRoom,
          ),
          DeviceCandidate(
            id: 'cloud-bosch-motion-hall',
            name: 'Koridor Hareket Sensörü',
            kind: DeviceKind.motionSensor,
            protocol: DeviceProtocol.cloud,
            room: Room.entrance,
          ),
        ],
        CloudProvider.smartThings => const [
          DeviceCandidate(
            id: 'cloud-st-motion-bath',
            name: 'Banyo Hareket Sensörü',
            kind: DeviceKind.motionSensor,
            protocol: DeviceProtocol.cloud,
            room: Room.bathroom,
          ),
        ],
      };
}
