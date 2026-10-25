import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sessiz_komsu/app.dart';
import 'package:sessiz_komsu/services/device_pairing_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Saturday, 24 October 2026, 08:00 — deterministic "now" for every test.
final fixedNow = DateTime(2026, 10, 24, 8);

/// Mutable clock for provider tests.
class FakeClock {
  FakeClock(this.now);

  DateTime now;

  DateTime call() => now;
}

/// Simulated pairing without waits.
const instantPairing = DevicePairingService(
  delays: DevicePairingDelays.instant,
);

/// Pumps the full app at [size] with a frozen clock, no periodic timer and
/// instant (simulated) device pairing.
Future<void> pumpSessizKomsu(
  WidgetTester tester, {
  Size size = const Size(1440, 900),
  SharedPreferences? preferences,
  DateTime? now,
}) async {
  setViewSize(tester, size);
  final time = now ?? fixedNow;
  await tester.pumpWidget(
    SessizKomsuApp(
      preferences: preferences,
      now: () => time,
      autoTick: false,
      pairing: instantPairing,
    ),
  );
  await tester.pump();
}

void setViewSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Advances enough frames for every finite animation to finish. Used instead
/// of `pumpAndSettle` because the İYİYİM pulse repeats forever.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Scrolls [finder] into view (if needed), taps it and settles.
Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await settle(tester);
}

/// Reads a provider from anywhere below the app root.
T readProvider<T>(WidgetTester tester) =>
    Provider.of<T>(tester.element(find.byType(Scaffold).first), listen: false);
