import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sessiz_komsu/core/constants/app_strings.dart';
import 'package:sessiz_komsu/core/theme/app_theme.dart';
import 'package:sessiz_komsu/models/app_mode.dart';
import 'package:sessiz_komsu/models/sensor_type.dart';
import 'package:sessiz_komsu/providers/app_mode_provider.dart';
import 'package:sessiz_komsu/providers/clock_provider.dart';
import 'package:sessiz_komsu/providers/sensor_provider.dart';
import 'package:sessiz_komsu/screens/family/widgets/activity_timeline.dart';
import 'package:sessiz_komsu/screens/family/widgets/demo_panel.dart';
import 'package:sessiz_komsu/screens/family/widgets/event_empty_state.dart';
import 'package:sessiz_komsu/screens/family/widgets/sensor_status_overview.dart';
import 'package:sessiz_komsu/screens/family/widgets/timeline_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_app.dart';

Finder _inPanel(String text) =>
    find.descendant(of: find.byType(DemoPanel), matching: find.text(text));

Finder _inSensors(String text) => find.descendant(
  of: find.byType(SensorStatusOverview),
  matching: find.text(text),
);

const _panelDescription =
    'Senaryoları tetikleyerek aile panelindeki değişimleri test edin.';

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

void main() {
  testWidgets('desktop shows header, banner, sensors, timeline and panel', (
    tester,
  ) async {
    await _pumpFamily(tester);

    expect(find.text(AppStrings.homeName), findsOneWidget);
    expect(find.text(AppStrings.demoLive), findsOneWidget);
    expect(find.text(AppStrings.bannerNormal), findsOneWidget);
    for (final type in SensorType.values) {
      expect(_inSensors(type.name), findsOneWidget);
    }
    expect(find.byType(TimelineItem), findsNWidgets(4));
    expect(find.text('4 olay · simüle'), findsOneWidget);
    expect(find.text('Geliştirici / Demo Kontrolleri'), findsOneWidget);
    expect(find.text('DEMO MODE'), findsOneWidget);
    expect(find.text(_panelDescription), findsOneWidget);
  });

  testWidgets('sensor buttons add animated timeline entries', (tester) async {
    await _pumpFamily(tester);

    await tapAndSettle(tester, _inPanel('Dış Kapı Sensörü'));

    expect(find.text('Dış kapı açıldı.'), findsOneWidget);
    expect(
      find.text(
        'Yalnızca kapının açılma zamanı simüle edilir; kişi tanıma yapılmaz.',
      ),
      findsOneWidget,
    );
    expect(find.byType(TimelineItem), findsNWidgets(5));
    expect(find.text('5 olay · simüle'), findsOneWidget);
  });

  testWidgets('+1 hour updates the header clock', (tester) async {
    await _pumpFamily(tester);

    await tapAndSettle(tester, find.text('Zamanı Hızlandır (+1 Saat)'));

    expect(find.text('24 Ekim 2026, Cumartesi · 09:00'), findsOneWidget);
    expect(find.text('DEMO SAATİ'), findsOneWidget);
  });

  testWidgets('alert scenario turns the banner red and disables the button', (
    tester,
  ) async {
    await _pumpFamily(tester);

    await tapAndSettle(tester, find.text('Uyarı Senaryosunu Başlat'));

    expect(find.text(AppStrings.bannerDelayed), findsOneWidget);
    expect(
      find.text('Uyarı aktif: cihaz ekranında İYİYİM onayı bekleniyor.'),
      findsOneWidget,
    );
    final eventsBefore = find.byType(TimelineItem).evaluate().length;

    await tapAndSettle(tester, find.text('Uyarı Senaryosunu Başlat'));
    expect(find.byType(TimelineItem), findsNWidgets(eventsBefore));
  });

  testWidgets('reset asks for confirmation; cancel keeps data', (tester) async {
    await _pumpFamily(tester);
    await tapAndSettle(tester, find.text('Dış Kapı Sensörü'));
    expect(find.byType(TimelineItem), findsNWidgets(5));

    await tapAndSettle(tester, find.text(AppStrings.resetDemo));
    expect(find.text('Demo sıfırlansın mı?'), findsOneWidget);
    await tapAndSettle(tester, find.text('Vazgeç'));
    expect(find.byType(TimelineItem), findsNWidgets(5));

    await tapAndSettle(tester, find.text(AppStrings.resetDemo));
    await tapAndSettle(tester, find.text('Sıfırla'));
    expect(find.byType(TimelineItem), findsNWidgets(4));
  });

  testWidgets('sensor rows open a details dialog', (tester) async {
    await _pumpFamily(tester);

    await tapAndSettle(tester, _inSensors(SensorType.kitchen.name));

    expect(find.text('Son tetiklenme'), findsOneWidget);
    expect(find.text('Bugün 07:30'), findsWidgets);
    await tapAndSettle(tester, find.text('Kapat'));
    expect(find.text('Son tetiklenme'), findsNothing);
  });

  testWidgets('sidebar navigates to settings and profile', (tester) async {
    await _pumpFamily(tester);

    await tapAndSettle(
      tester,
      find.byTooltip('Ayarlar — görünüm ve demo tercihleri'),
    );
    expect(find.text('Rutin kuralları'), findsOneWidget);
    expect(find.text('09:30'), findsOneWidget);

    await tapAndSettle(tester, find.text('Demo panelini göster'));
    expect(find.text(_panelDescription), findsNothing);

    await tapAndSettle(tester, find.byTooltip('Profil — takip edilen kişi'));
    expect(find.text(AppStrings.residentName), findsOneWidget);
    expect(find.text('Mutfak · Bugün 07:30'), findsOneWidget);

    await tapAndSettle(
      tester,
      find.byTooltip('Ev — günlük durum ve etkinlikler'),
    );
    expect(find.text(AppStrings.bannerNormal), findsOneWidget);
  });

  for (final size in const [
    Size(1440, 900),
    Size(1280, 800),
    Size(1024, 768),
    Size(768, 1024),
    Size(390, 844),
  ]) {
    testWidgets('renders without overflow at ${size.width.toInt()}px', (
      tester,
    ) async {
      await _pumpFamily(tester, size: size);
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.bannerNormal), findsOneWidget);
      expect(find.text('Geliştirici / Demo Kontrolleri'), findsOneWidget);

      final isMobile = size.width < 600;
      expect(
        find.byTooltip('Cihaz Modu'),
        findsOneWidget,
        reason: isMobile ? 'bottom navigation' : 'sidebar',
      );
      // The phone layout collapses the simulator by default.
      expect(
        find.text(_panelDescription),
        isMobile ? findsNothing : findsOneWidget,
      );
      if (isMobile) {
        await tapAndSettle(tester, find.text('Geliştirici / Demo Kontrolleri'));
        expect(find.text(_panelDescription), findsOneWidget);
        await tapAndSettle(tester, find.text('Mutfak Prizini Aç'));
        expect(find.byType(TimelineItem), findsNWidgets(5));
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('timeline shows an empty state and stays in sync with resets', (
    tester,
  ) async {
    final clock = ClockProvider(now: () => fixedNow, autoTick: false);
    final sensors = SensorProvider(initialTime: fixedNow, seed: false);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppModeProvider()),
          ChangeNotifierProvider.value(value: clock),
          ChangeNotifierProvider.value(value: sensors),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: SingleChildScrollView(child: ActivityTimeline()),
          ),
        ),
      ),
    );

    expect(find.byType(EventEmptyState), findsOneWidget);
    expect(find.byType(TimelineItem), findsNothing);

    sensors.trigger(SensorType.entrance, fixedNow);
    await settle(tester);
    expect(find.byType(EventEmptyState), findsNothing);
    expect(find.byType(TimelineItem), findsOneWidget);

    // Reset removes the trigger and inserts the four seed events.
    sensors.reset(fixedNow);
    await settle(tester);
    expect(find.byType(TimelineItem), findsNWidgets(4));
    expect(find.text('Dış kapı açıldı.'), findsNothing);
    expect(find.text('Mutfak sensörü tetiklendi.'), findsNWidgets(2));
  });
}
