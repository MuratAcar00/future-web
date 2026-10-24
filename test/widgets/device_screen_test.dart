import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sessiz_komsu/core/constants/app_strings.dart';
import 'package:sessiz_komsu/models/app_mode.dart';
import 'package:sessiz_komsu/models/routine_status.dart';
import 'package:sessiz_komsu/models/sensor_event.dart';
import 'package:sessiz_komsu/providers/app_mode_provider.dart';
import 'package:sessiz_komsu/providers/demo_provider.dart';
import 'package:sessiz_komsu/providers/routine_provider.dart';
import 'package:sessiz_komsu/providers/sensor_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_app.dart';

Future<void> _pumpDevice(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({
    AppModeProvider.modeKey: AppMode.device.name,
  });
  final prefs = await SharedPreferences.getInstance();
  await pumpSessizKomsu(tester, preferences: prefs);
}

int _confirmations(WidgetTester tester) =>
    readProvider<SensorProvider>(tester).events
        .where((e) => e.kind == EventKind.confirmed)
        .length;

void main() {
  testWidgets('shows a large clock and the Turkish date', (tester) async {
    await _pumpDevice(tester);

    expect(find.text('08:00'), findsOneWidget);
    expect(find.text('24 Ekim 2026, Cumartesi'), findsOneWidget);
    expect(find.text(AppStrings.confirmButton), findsNothing);
  });

  testWidgets('alert shows İYİYİM; pressing it confirms once and returns', (
    tester,
  ) async {
    await _pumpDevice(tester);

    readProvider<DemoProvider>(tester).startAlertScenario();
    await settle(tester);
    expect(find.text(AppStrings.confirmButton), findsOneWidget);
    expect(find.text('10:30'), findsNothing);

    // Rapid double tap: only the first press counts.
    await tester.tap(find.text(AppStrings.confirmButton));
    await tester.tap(find.text(AppStrings.confirmButton), warnIfMissed: false);
    await settle(tester);

    expect(find.text(AppStrings.confirmButton), findsNothing);
    expect(find.text('10:30'), findsOneWidget);
    expect(find.text(AppStrings.confirmThanks), findsOneWidget);
    expect(_confirmations(tester), 1);
    expect(
      readProvider<RoutineProvider>(tester).status,
      RoutineStatus.confirmedOkay,
    );
  });

  testWidgets('İYİYİM can be confirmed with the keyboard', (tester) async {
    await _pumpDevice(tester);
    readProvider<DemoProvider>(tester).startAlertScenario();
    await settle(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await settle(tester);

    expect(_confirmations(tester), 1);
    expect(find.text(AppStrings.confirmButton), findsNothing);
  });

  testWidgets('pulse is disabled when reduced motion is requested', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await _pumpDevice(tester);

    readProvider<DemoProvider>(tester).startAlertScenario();
    // Would time out if the repeating pulse animation were running.
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.confirmButton), findsOneWidget);
  });

  testWidgets('back button returns to mode selection', (tester) async {
    await _pumpDevice(tester);

    await tapAndSettle(tester, find.byTooltip(AppStrings.backToModeSelection));

    expect(find.text(AppStrings.modeQuestion), findsOneWidget);
  });
}
