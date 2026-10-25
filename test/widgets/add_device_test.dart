import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sessiz_komsu/models/app_mode.dart';
import 'package:sessiz_komsu/models/device.dart';
import 'package:sessiz_komsu/providers/app_mode_provider.dart';
import 'package:sessiz_komsu/providers/device_provider.dart';
import 'package:sessiz_komsu/screens/devices/add_device_sheet.dart';
import 'package:sessiz_komsu/screens/family/widgets/activity_timeline.dart';
import 'package:sessiz_komsu/screens/family/widgets/demo_panel.dart';
import 'package:sessiz_komsu/screens/family/widgets/sensor_status_overview.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_app.dart';

Future<void> _pumpFamily(
  WidgetTester tester, {
  Size size = const Size(1440, 900),
}) async {
  SharedPreferences.setMockInitialValues({
    AppModeProvider.modeKey: AppMode.family.name,
  });
  final prefs = await SharedPreferences.getInstance();
  await pumpSessizKomsu(tester, preferences: prefs, size: size);
}

Finder _inSheet(Finder finder) =>
    find.descendant(of: find.byType(AddDeviceSheet), matching: finder);

Finder _inSensors(String text) => find.descendant(
  of: find.byType(SensorStatusOverview),
  matching: find.text(text),
);

Finder _inTimeline(String text) => find.descendant(
  of: find.byType(ActivityTimeline),
  matching: find.text(text),
);

Future<void> _openSheet(WidgetTester tester) => tapAndSettle(
  tester,
  find.descendant(
    of: find.byType(SensorStatusOverview),
    matching: find.widgetWithText(TextButton, 'Cihaz Ekle'),
  ),
);

Future<void> _tapInSheet(WidgetTester tester, String text) =>
    tapAndSettle(tester, _inSheet(find.text(text)).last);

void main() {
  testWidgets('sheet offers three honestly labelled methods', (tester) async {
    await _pumpFamily(tester);
    await _openSheet(tester);

    expect(find.byType(AddDeviceSheet), findsOneWidget);
    expect(find.text('Demo: gerçek bağlantı kurulmaz.'), findsOneWidget);
    for (final method in AddDeviceMethod.values) {
      expect(find.text(method.title), findsOneWidget);
      expect(find.text(method.subtitle), findsOneWidget);
    }

    await tapAndSettle(tester, find.byTooltip('Kapat'));
    expect(find.byType(AddDeviceSheet), findsNothing);
  });

  testWidgets('QR flow: demo scan → room → name → added', (tester) async {
    await _pumpFamily(tester);
    await _openSheet(tester);
    await _tapInSheet(tester, 'QR Kod ile Cihaz Ekle');

    expect(
      find.text('Kamera açılmaz. Bu ekran QR kod okutmayı simüle eder.'),
      findsOneWidget,
    );
    await _tapInSheet(tester, 'Demo QR okut');

    expect(find.text('Kod okundu: SK-BT42-7A19'), findsOneWidget);
    expect(find.text('Cihaz tanındı'), findsWidgets);
    expect(find.text('Bluetooth Hareket Sensörü'), findsOneWidget);
    await _tapInSheet(tester, 'Devam');

    await _tapInSheet(tester, 'Banyo');
    await _tapInSheet(tester, 'Devam');

    await tester.enterText(_inSheet(find.byType(TextField)), 'Banyo Sensörü');
    await _tapInSheet(tester, 'Cihazı ekle');

    expect(find.text('Eklendi: Banyo Sensörü'), findsOneWidget);
    await _tapInSheet(tester, 'Bitti');

    expect(find.byType(AddDeviceSheet), findsNothing);
    expect(_inSensors('Banyo Sensörü'), findsOneWidget);
    expect(_inSensors('4 simüle cihaz'), findsOneWidget);
    expect(_inTimeline('Yeni cihaz eklendi: Banyo Sensörü'), findsOneWidget);

    // The motion sensor can be triggered from the demo panel.
    await tapAndSettle(
      tester,
      find.descendant(
        of: find.byType(DemoPanel),
        matching: find.text('Banyo Sensörü (Banyo)'),
      ),
    );
    expect(_inTimeline('Banyo Sensörü: Hareket algılandı.'), findsOneWidget);

    // Scanning the same code again is detected as a duplicate.
    await _openSheet(tester);
    await _tapInSheet(tester, 'QR Kod ile Cihaz Ekle');
    await _tapInSheet(tester, 'Demo QR okut');
    expect(
      find.text('Bu cihaz zaten ekli. Aynı cihaz ikinci kez eklenmez.'),
      findsOneWidget,
    );
    final next = tester.widget<FilledButton>(
      _inSheet(find.widgetWithText(FilledButton, 'Devam')),
    );
    expect(next.onPressed, isNull);
  });

  testWidgets('QR flow validates the manual setup code', (tester) async {
    await _pumpFamily(tester);
    await _openSheet(tester);
    await _tapInSheet(tester, 'QR Kod ile Cihaz Ekle');

    await tester.enterText(_inSheet(find.byType(TextField)), 'SK-12');
    await _tapInSheet(tester, 'Kodu doğrula');
    expect(
      find.text('Kod SK-XXXX-XXXX biçiminde olmalı (harf ve rakam).'),
      findsOneWidget,
    );

    await tester.enterText(_inSheet(find.byType(TextField)), 'sk-ab12-cd34');
    await _tapInSheet(tester, 'Kodu doğrula');
    expect(find.text('Kod okundu: SK-AB12-CD34'), findsOneWidget);
  });

  testWidgets('scan flow: discover, select, assign room, add, rescan', (
    tester,
  ) async {
    await _pumpFamily(tester);
    await _openSheet(tester);
    await _tapInSheet(tester, 'Cihazları Tara');

    expect(find.text('4 cihaz bulundu'), findsOneWidget);
    expect(find.text('Zigbee Kapı Sensörü'), findsOneWidget);
    expect(find.text('Akıllı TV (Salon)'), findsOneWidget);
    expect(_inSheet(find.text('Zigbee')), findsNWidgets(2));
    expect(
      find.bySemanticsLabel(
        RegExp(
          r'^Zigbee Kapı Sensörü\. Zigbee\. Sinyal çok iyi\. Seçili değil',
        ),
      ),
      findsOneWidget,
    );

    await _tapInSheet(tester, 'Zigbee Kapı Sensörü');
    await _tapInSheet(tester, 'Akıllı TV (Salon)');
    await _tapInSheet(tester, 'Seçilenleri ekle (2)');

    expect(find.text('Odaya ata'), findsOneWidget);
    await _tapInSheet(tester, '2 cihazı ekle');
    expect(find.text('2 cihaz eklendi'), findsOneWidget);

    await _tapInSheet(tester, 'Tekrar tara');
    expect(find.text('2 cihaz bulundu'), findsOneWidget);
    expect(_inSheet(find.text('Zigbee Kapı Sensörü')), findsNothing);
    await _tapInSheet(tester, 'Zigbee Hareket Sensörü');
    await _tapInSheet(tester, 'Akıllı Priz');
    await _tapInSheet(tester, 'Seçilenleri ekle (2)');
    await _tapInSheet(tester, '2 cihazı ekle');

    await _tapInSheet(tester, 'Tekrar tara');
    expect(find.text('Yeni cihaz bulunamadı'), findsOneWidget);
    // Rescanning from the empty state stays empty.
    await _tapInSheet(tester, 'Tekrar tara');
    expect(find.text('Yeni cihaz bulunamadı'), findsOneWidget);

    await tapAndSettle(tester, find.byTooltip('Kapat'));
    expect(_inSensors('Zigbee Kapı Sensörü'), findsOneWidget);
    expect(_inSensors('7 simüle cihaz'), findsOneWidget);
  });

  testWidgets('cloud flow: consent → connected → unlink', (tester) async {
    await _pumpFamily(tester);
    await _openSheet(tester);
    await _tapInSheet(tester, 'Hesap Bağla');

    expect(find.text('Google Home'), findsOneWidget);
    expect(find.text('SmartThings'), findsOneWidget);
    await _tapInSheet(tester, 'Google Home');

    expect(find.text('Google Home hesabını bağla'), findsOneWidget);
    expect(find.text('Ses kaydı veya mikrofon'), findsOneWidget);
    expect(find.text('Görüntü, kamera veya video'), findsOneWidget);
    await _tapInSheet(tester, 'Bağla');

    expect(find.text('Google Home bağlandı'), findsOneWidget);
    expect(_inSheet(find.text('Salon Hareket Sensörü')), findsOneWidget);
    expect(_inSensors('Salon Televizyonu'), findsOneWidget);
    expect(_inTimeline('Hesap bağlandı: Google Home'), findsOneWidget);

    await _tapInSheet(tester, 'Diğer hesaplar');
    expect(find.text('Bağlı · 2 cihaz'), findsOneWidget);
    await _tapInSheet(tester, 'Google Home');
    await _tapInSheet(tester, 'Bağlantıyı kaldır');
    await tapAndSettle(
      tester,
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Bağlantıyı kaldır'),
      ),
    );

    expect(find.text('Bağlı · 2 cihaz'), findsNothing);
    expect(find.text('Bağlı değil'), findsNWidgets(4));
    expect(_inSensors('Salon Televizyonu'), findsNothing);
    expect(
      _inTimeline('Hesap bağlantısı kaldırıldı: Google Home'),
      findsOneWidget,
    );
  });

  testWidgets('settings: rename, change room, remove and reset', (
    tester,
  ) async {
    await _pumpFamily(tester);
    final devices = readProvider<DeviceProvider>(tester);
    devices.addDevices(
      instantPairing.discoverableDevices.take(2),
      source: DeviceSource.scan,
    );
    readProvider<AppModeProvider>(tester).selectSection(FamilySection.settings);
    await settle(tester);

    expect(find.text('Cihazlar'), findsOneWidget);
    expect(find.text('VARSAYILAN'), findsNWidgets(3));
    expect(find.text('Zigbee Kapı Sensörü'), findsOneWidget);

    await tapAndSettle(
      tester,
      find.byTooltip('Zigbee Kapı Sensörü seçenekleri'),
    );
    await tapAndSettle(tester, find.text('Yeniden adlandır'));
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'Balkon Kapısı',
    );
    await tapAndSettle(tester, find.text('Kaydet'));
    expect(find.text('Balkon Kapısı'), findsOneWidget);

    await tapAndSettle(tester, find.byTooltip('Balkon Kapısı seçenekleri'));
    await tapAndSettle(tester, find.text('Odayı değiştir'));
    await tapAndSettle(
      tester,
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Salon'),
      ),
    );
    await tapAndSettle(tester, find.text('Kaydet'));
    expect(devices.devices.first.name, 'Balkon Kapısı');
    expect(devices.devices.first.room.label, 'Salon');

    await tapAndSettle(tester, find.byTooltip('Balkon Kapısı seçenekleri'));
    await tapAndSettle(tester, find.text('Kaldır'));
    expect(find.text('Cihaz kaldırılsın mı?'), findsOneWidget);
    await tapAndSettle(
      tester,
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Kaldır'),
      ),
    );
    expect(find.text('Balkon Kapısı'), findsNothing);
    expect(devices.devices, hasLength(1));

    await tapAndSettle(
      tester,
      find.bySemanticsLabel("Sıfırla: Demo'yu Sıfırla"),
    );
    await tapAndSettle(
      tester,
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Sıfırla'),
      ),
    );
    expect(devices.devices, isEmpty);
    expect(find.text('Zigbee Hareket Sensörü'), findsNothing);
  });

  testWidgets('390px: sheet flows render without overflow', (tester) async {
    await _pumpFamily(tester, size: const Size(390, 844));
    await _openSheet(tester);
    expect(tester.takeException(), isNull);

    await _tapInSheet(tester, 'Cihazları Tara');
    expect(tester.takeException(), isNull);
    await _tapInSheet(tester, 'Akıllı TV (Salon)');
    await _tapInSheet(tester, 'Seçilenleri ekle (1)');
    expect(tester.takeException(), isNull);
    await _tapInSheet(tester, 'Cihazı ekle');
    await tapAndSettle(tester, find.byTooltip('Yöntemlere dön'));

    await _tapInSheet(tester, 'QR Kod ile Cihaz Ekle');
    expect(tester.takeException(), isNull);
    await tapAndSettle(tester, find.byTooltip('Yöntemlere dön'));

    await _tapInSheet(tester, 'Hesap Bağla');
    await _tapInSheet(tester, 'Bosch Smart Home');
    await _tapInSheet(tester, 'Bağla');
    expect(find.text('Bosch Smart Home bağlandı'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tapAndSettle(tester, find.byTooltip('Kapat'));
    expect(_inSensors('Akıllı TV (Salon)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
