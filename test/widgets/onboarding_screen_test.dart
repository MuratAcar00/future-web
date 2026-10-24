import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sessiz_komsu/core/constants/app_strings.dart';
import 'package:sessiz_komsu/models/app_mode.dart';
import 'package:sessiz_komsu/providers/app_mode_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('shows brand, tagline, question and both mode options', (
    tester,
  ) async {
    await pumpSessizKomsu(tester);

    expect(find.text(AppStrings.appName), findsOneWidget);
    expect(find.text(AppStrings.tagline), findsOneWidget);
    expect(find.text(AppStrings.modeQuestion), findsOneWidget);
    expect(find.text(AppStrings.deviceModeTitle), findsOneWidget);
    expect(find.text(AppStrings.deviceModeDescription), findsOneWidget);
    expect(find.text(AppStrings.familyModeTitle), findsOneWidget);
    expect(find.text(AppStrings.familyModeDescription), findsOneWidget);
  });

  testWidgets('choosing the family option opens the dashboard and persists', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await pumpSessizKomsu(tester, preferences: prefs);

    await tapAndSettle(tester, find.text(AppStrings.familyModeTitle));

    expect(find.text(AppStrings.homeName), findsOneWidget);
    expect(prefs.getString(AppModeProvider.modeKey), AppMode.family.name);
  });

  testWidgets('choosing the device option opens the clock', (tester) async {
    await pumpSessizKomsu(tester);

    await tapAndSettle(tester, find.text(AppStrings.deviceModeTitle));

    expect(find.text('08:00'), findsOneWidget);
    expect(find.text('24 Ekim 2026, Cumartesi'), findsOneWidget);
  });

  testWidgets('options are keyboard accessible', (tester) async {
    await pumpSessizKomsu(tester);

    // Focus order: device option, then family option.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await settle(tester);

    expect(find.text(AppStrings.homeName), findsOneWidget);
  });

  testWidgets('stacks options on phones without overflow', (tester) async {
    await pumpSessizKomsu(tester, size: const Size(390, 844));

    final device = tester.getTopLeft(find.text(AppStrings.deviceModeTitle));
    final family = tester.getTopLeft(find.text(AppStrings.familyModeTitle));
    expect(family.dy, greaterThan(device.dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a stored mode is restored after a refresh', (tester) async {
    SharedPreferences.setMockInitialValues({
      AppModeProvider.modeKey: AppMode.family.name,
    });
    final prefs = await SharedPreferences.getInstance();
    await pumpSessizKomsu(tester, preferences: prefs);

    expect(find.text(AppStrings.homeName), findsOneWidget);
    expect(find.text(AppStrings.modeQuestion), findsNothing);
  });
}
