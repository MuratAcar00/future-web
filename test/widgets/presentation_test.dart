import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sessiz_komsu/core/constants/app_strings.dart';
import 'package:sessiz_komsu/models/app_mode.dart';
import 'package:sessiz_komsu/models/presentation_step.dart';
import 'package:sessiz_komsu/models/routine_status.dart';
import 'package:sessiz_komsu/providers/app_mode_provider.dart';
import 'package:sessiz_komsu/providers/presentation_provider.dart';
import 'package:sessiz_komsu/providers/routine_provider.dart';
import 'package:sessiz_komsu/screens/device/device_screen.dart';
import 'package:sessiz_komsu/screens/family/family_dashboard.dart';
import 'package:sessiz_komsu/screens/onboarding/onboarding_screen.dart';
import 'package:sessiz_komsu/screens/presentation/presentation_layer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_app.dart';

Finder _caption(String text) => find.descendant(
  of: find.byType(PresentationCaption),
  matching: find.text(text),
);

/// Pumps until the presentation leaves step [index] (auto-advance), then
/// lets the caption transition finish.
Future<void> _playStep(WidgetTester tester, int index) async {
  final presentation = readProvider<PresentationProvider>(tester);
  final limit = presentationSteps[index].duration * 2;
  var waited = Duration.zero;
  while (presentation.index == index && waited < limit) {
    await tester.pump(const Duration(milliseconds: 100));
    waited += const Duration(milliseconds: 100);
  }
  expect(presentation.index, index + 1, reason: 'auto-advance from $index');
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('presentation runs from onboarding to the end and back', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpSessizKomsu(tester);
    expect(find.byType(OnboardingScreen), findsOne);

    await tapAndSettle(tester, find.text(AppStrings.presentationStart));
    final presentation = readProvider<PresentationProvider>(tester);
    expect(presentation.isActive, isTrue);
    expect(find.byType(PresentationCaption), findsOne);
    expect(find.byType(FamilyDashboard), findsOne);

    for (var i = 0; i < presentationSteps.length; i++) {
      final step = presentationSteps[i];
      expect(_caption(step.title), findsOne, reason: 'step ${i + 1}');
      expect(_caption('${i + 1} / ${presentationSteps.length}'), findsOne);
      if (i == 4) {
        expect(find.byType(DeviceScreen), findsOne);
        expect(find.text(AppStrings.confirmButton), findsOne);
      }
      if (i < presentationSteps.length - 1) await _playStep(tester, i);
    }

    expect(find.byType(FamilyDashboard), findsOne);
    expect(
      readProvider<RoutineProvider>(tester).status,
      RoutineStatus.confirmedOkay,
    );
    expect(_caption('SUNUM · SİMÜLE VERİ'), findsOne);

    await tapAndSettle(tester, _caption('Bitir'));
    expect(find.byType(PresentationCaption), findsNothing);
    expect(find.byType(OnboardingScreen), findsOne);
    expect(readProvider<RoutineProvider>(tester).status, RoutineStatus.normal);
    semantics.dispose();
  });

  testWidgets('keyboard: space pauses, arrows step, escape finishes', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      AppModeProvider.modeKey: AppMode.family.name,
    });
    final prefs = await SharedPreferences.getInstance();
    await pumpSessizKomsu(tester, preferences: prefs);

    await tapAndSettle(tester, find.text(AppStrings.presentationStart));
    final presentation = readProvider<PresentationProvider>(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await settle(tester);
    expect(presentation.isPaused, isTrue);
    expect(_caption('Devam'), findsOne);
    await tester.pump(const Duration(seconds: 20));
    expect(presentation.index, 0);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await settle(tester);
    expect(presentation.index, 2);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await settle(tester);
    expect(presentation.index, 1);
    expect(_caption(presentationSteps[1].title), findsOne);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle(tester);
    expect(presentation.isActive, isFalse);
    expect(find.byType(FamilyDashboard), findsOne);
  });

  testWidgets('demo panel offers the presentation button with a tooltip', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      AppModeProvider.modeKey: AppMode.family.name,
    });
    final prefs = await SharedPreferences.getInstance();
    await pumpSessizKomsu(tester, preferences: prefs);

    expect(find.byType(StartPresentationButton), findsOne);
    expect(find.byTooltip(AppStrings.presentationTooltip), findsOne);
  });
}
