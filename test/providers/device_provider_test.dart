import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sessiz_komsu/models/app_mode.dart';
import 'package:sessiz_komsu/models/cloud_account.dart';
import 'package:sessiz_komsu/models/device.dart';
import 'package:sessiz_komsu/models/sensor_event.dart';
import 'package:sessiz_komsu/providers/app_mode_provider.dart';
import 'package:sessiz_komsu/providers/clock_provider.dart';
import 'package:sessiz_komsu/providers/demo_provider.dart';
import 'package:sessiz_komsu/providers/device_provider.dart';
import 'package:sessiz_komsu/providers/presentation_provider.dart';
import 'package:sessiz_komsu/providers/routine_provider.dart';
import 'package:sessiz_komsu/providers/sensor_provider.dart';
import 'package:sessiz_komsu/services/device_pairing_service.dart';

import '../helpers/test_app.dart';

typedef _Harness = ({
  ClockProvider clock,
  SensorProvider sensors,
  DeviceProvider devices,
  DemoProvider demo,
  RoutineProvider routine,
});

_Harness _harness({DevicePairingService pairing = instantPairing}) {
  final clock = ClockProvider(now: () => fixedNow, autoTick: false);
  final sensors = SensorProvider(initialTime: fixedNow);
  final routine = RoutineProvider(clock: clock, sensors: sensors);
  final devices = DeviceProvider(
    clock: clock,
    sensors: sensors,
    pairing: pairing,
  );
  final demo = DemoProvider(
    clock: clock,
    sensors: sensors,
    routine: routine,
    devices: devices,
  );
  addTearDown(() {
    demo.dispose();
    devices.dispose();
    routine.dispose();
    sensors.dispose();
    clock.dispose();
  });
  return (
    clock: clock,
    sensors: sensors,
    devices: devices,
    demo: demo,
    routine: routine,
  );
}

List<String> _titles(SensorProvider sensors) => [
  for (final e in sensors.events) e.title,
];

const _pairing = instantPairing;

void main() {
  group('setup codes', () {
    test('validates the SK-XXXX-XXXX format', () {
      expect(DevicePairingService.validateSetupCode(''), isNotNull);
      expect(DevicePairingService.validateSetupCode('SK-12-34'), isNotNull);
      expect(DevicePairingService.validateSetupCode('AB-1234-5678'), isNotNull);
      expect(DevicePairingService.validateSetupCode('SK-12_4-5678'), isNotNull);
      expect(DevicePairingService.validateSetupCode('sk-ab12-cd34'), isNull);
      expect(DevicePairingService.validateSetupCode(' SK-AB12-CD34 '), isNull);
    });

    test('resolves the same code to the same device', () {
      final a = _pairing.candidateForCode('SK-AB12-CD34');
      final b = _pairing.candidateForCode('sk-ab12-cd34');
      expect(a, b);
      expect(a.id, 'qr-SK-AB12-CD34');
      expect(a.protocol, anyOf(DeviceProtocol.wifi, DeviceProtocol.bluetooth));
    });

    test('lookup rejects invalid codes', () {
      expect(
        () => _pairing.lookupSetupCode('nope'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('DeviceProvider', () {
    test('starts with no added devices or accounts', () {
      final h = _harness();
      expect(h.devices.devices, isEmpty);
      expect(h.devices.accounts, isEmpty);
      expect(h.devices.discoveryStatus, DiscoveryStatus.idle);
    });

    test('QR: adds the demo device once and logs it', () async {
      final h = _harness();
      final candidate = await h.devices.scanDemoQr();
      expect(candidate.name, 'Bluetooth Hareket Sensörü');
      final before = h.sensors.events.length;

      final added = h.devices.addDevice(
        candidate,
        source: DeviceSource.qr,
        room: Room.bathroom,
        name: '  Banyo Sensörü ',
      );

      expect(added, isNotNull);
      expect(added!.name, 'Banyo Sensörü');
      expect(added.room, Room.bathroom);
      expect(added.source, DeviceSource.qr);
      expect(h.sensors.events, hasLength(before + 1));
      expect(h.sensors.events.first.title, 'Yeni cihaz eklendi: Banyo Sensörü');
      expect(h.sensors.events.first.kind, EventKind.deviceSetup);
      expect(h.sensors.events.first.kind.isSensorActivity, isFalse);

      // Repeated add of the same hardware id is ignored.
      expect(h.devices.addDevice(candidate, source: DeviceSource.qr), isNull);
      expect(h.devices.devices, hasLength(1));
      expect(h.sensors.events, hasLength(before + 1));
    });

    test('QR: blank name falls back to the recognised name', () async {
      final h = _harness();
      final candidate = await h.devices.lookupSetupCode('SK-AB12-CD34');
      final added = h.devices.addDevice(
        candidate,
        source: DeviceSource.qr,
        name: '   ',
      );
      expect(added!.name, candidate.name);
      expect(added.room, candidate.room);
    });

    test('scan: reports devices one by one, then excludes added ones', () {
      fakeAsync((async) {
        final h = _harness(
          pairing: const DevicePairingService(
            delays: DevicePairingDelays(
              discoveryStart: Duration(seconds: 1),
              discoveryInterval: Duration(seconds: 1),
            ),
          ),
        );
        h.devices.startDiscovery();
        expect(h.devices.discoveryStatus, DiscoveryStatus.scanning);
        expect(h.devices.discovered, isEmpty);

        async.elapse(const Duration(seconds: 1));
        expect(h.devices.discovered.map((c) => c.name), [
          'Zigbee Kapı Sensörü',
        ]);
        async.elapse(const Duration(seconds: 3));
        expect(h.devices.discoveryStatus, DiscoveryStatus.done);
        expect(h.devices.discovered.map((c) => c.name), [
          'Zigbee Kapı Sensörü',
          'Zigbee Hareket Sensörü',
          'Akıllı Priz',
          'Akıllı TV (Salon)',
        ]);

        final found = h.devices.discovered;
        final added = h.devices.addDevices(
          found.take(2),
          source: DeviceSource.scan,
          rooms: {found.first.id: Room.kitchen},
        );
        expect(added, hasLength(2));
        expect(added.first.room, Room.kitchen);
        expect(added.last.room, found[1].room);
        expect(
          h.devices.addDevices(found.take(2), source: DeviceSource.scan),
          isEmpty,
        );

        h.devices.startDiscovery();
        async.elapse(const Duration(seconds: 10));
        expect(h.devices.discovered.map((c) => c.name), [
          'Akıllı Priz',
          'Akıllı TV (Salon)',
        ]);

        h.devices.addDevices(h.devices.discovered, source: DeviceSource.scan);
        h.devices.startDiscovery();
        async.elapse(const Duration(seconds: 10));
        expect(h.devices.discoveryStatus, DiscoveryStatus.done);
        expect(h.devices.discovered, isEmpty);
      });
    });

    test('rename, change room and remove (logged)', () {
      final h = _harness();
      final device = h.devices.addDevice(
        _pairing.discoverableDevices.first,
        source: DeviceSource.scan,
      )!;

      expect(h.devices.rename(device.id, '  '), isFalse);
      expect(h.devices.rename(device.id, 'Balkon Kapısı'), isTrue);
      expect(h.devices.changeRoom(device.id, Room.livingRoom), isTrue);
      expect(h.devices.changeRoom(device.id, Room.livingRoom), isFalse);
      final updated = h.devices.device(device.id)!;
      expect(updated.name, 'Balkon Kapısı');
      expect(updated.room, Room.livingRoom);

      expect(h.devices.remove(device.id), isTrue);
      expect(h.devices.remove(device.id), isFalse);
      expect(h.devices.devices, isEmpty);
      expect(h.sensors.events.first.title, 'Cihaz kaldırıldı: Balkon Kapısı');

      // Can be added again after removal, with a fresh timeline entry.
      expect(
        h.devices.addDevice(
          _pairing.discoverableDevices.first,
          source: DeviceSource.scan,
        ),
        isNotNull,
      );
      expect(
        _titles(h.sensors)
            .where((t) => t == 'Yeni cihaz eklendi: Zigbee Kapı Sensörü'),
        hasLength(2),
      );
    });

    test('triggerable devices log activity like the built-in sensors', () {
      final h = _harness();
      final added = h.devices.addDevices(
        _pairing.discoverableDevices,
        source: DeviceSource.scan,
      );
      final motion = added.firstWhere((d) => d.kind == DeviceKind.motionSensor);
      final tv = added.firstWhere((d) => d.kind == DeviceKind.smartTv);

      expect(h.demo.triggerDevice(motion.id), isTrue);
      expect(h.demo.triggerDevice(motion.id), isFalse);
      expect(h.demo.lastAction, contains('zaten tetiklendi'));
      expect(h.demo.triggerDevice(tv.id), isFalse);

      final event = h.sensors.events.first;
      expect(event.kind, EventKind.deviceActivity);
      expect(event.kind.isSensorActivity, isTrue);
      expect(event.tag, motion.room.label);
      expect(event.title, 'Zigbee Hareket Sensörü: Hareket algılandı.');
      final updated = h.devices.device(motion.id)!;
      expect(updated.lastTriggered, fixedNow);
      expect(updated.lastState, 'Hareket algılandı');
    });

    test('cloud: link imports devices, unlink removes them', () async {
      final h = _harness();

      final account = await h.devices.linkAccount(CloudProvider.googleHome);
      expect(account, isNotNull);
      expect(h.devices.isLinked(CloudProvider.googleHome), isTrue);
      expect(account!.deviceIds, hasLength(2));
      expect(h.devices.devices.map((d) => d.name), [
        'Salon Hareket Sensörü',
        'Salon Televizyonu',
      ]);
      expect(h.devices.devices.first.sourceLabel, 'Google Home hesabı');
      expect(h.sensors.events.first.title, 'Hesap bağlandı: Google Home');
      expect(
        _titles(h.sensors),
        contains('Yeni cihaz eklendi: Salon Hareket Sensörü'),
      );

      // Linking again neither duplicates devices nor events.
      final count = h.sensors.events.length;
      expect(
        await h.devices.linkAccount(CloudProvider.googleHome),
        same(account),
      );
      expect(h.devices.devices, hasLength(2));
      expect(h.sensors.events, hasLength(count));

      // Removing one imported device updates the account.
      h.devices.remove(account.deviceIds.last);
      expect(
        h.devices.account(CloudProvider.googleHome)!.deviceIds,
        hasLength(1),
      );

      expect(h.devices.unlinkAccount(CloudProvider.googleHome), isTrue);
      expect(h.devices.unlinkAccount(CloudProvider.googleHome), isFalse);
      expect(h.devices.devices, isEmpty);
      expect(h.devices.accounts, isEmpty);
      expect(
        h.sensors.events.first.title,
        'Hesap bağlantısı kaldırıldı: Google Home',
      );
    });

    test('demo reset restores the seed state and drops pending links', () {
      fakeAsync((async) {
        final h = _harness(
          pairing: const DevicePairingService(
            delays: DevicePairingDelays(cloudLink: Duration(seconds: 1)),
          ),
        );
        h.devices.addDevice(
          _pairing.discoverableDevices.first,
          source: DeviceSource.scan,
        );
        h.devices.linkAccount(CloudProvider.smartThings);
        async.elapse(const Duration(seconds: 1));
        expect(h.devices.accounts, hasLength(1));

        h.devices.linkAccount(CloudProvider.amazonAlexa);
        expect(h.devices.linking, CloudProvider.amazonAlexa);
        h.devices.startDiscovery();

        h.demo.reset();
        async.elapse(const Duration(seconds: 5));

        expect(h.devices.devices, isEmpty);
        expect(h.devices.accounts, isEmpty);
        expect(h.devices.linking, isNull);
        expect(h.devices.discoveryStatus, DiscoveryStatus.idle);
        expect(h.devices.discovered, isEmpty);
        expect(h.sensors.events, hasLength(4));
      });
    });

    test('finishing Sunum Modu resets added devices', () {
      fakeAsync((async) {
        final h = _harness();
        final appMode = AppModeProvider()..selectMode(AppMode.family);
        final presentation = PresentationProvider(
          appMode: appMode,
          clock: h.clock,
          demo: h.demo,
          routine: h.routine,
        );
        addTearDown(() {
          presentation.dispose();
          appMode.dispose();
        });

        h.devices.addDevice(
          _pairing.discoverableDevices.first,
          source: DeviceSource.scan,
        );
        presentation.start();
        expect(h.devices.devices, isEmpty);

        h.devices.addDevice(
          _pairing.discoverableDevices.last,
          source: DeviceSource.scan,
        );
        presentation.finish();
        expect(h.devices.devices, isEmpty);
        expect(h.devices.accounts, isEmpty);
      });
    });
  });
}
