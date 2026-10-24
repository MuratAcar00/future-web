import 'package:flutter_test/flutter_test.dart';
import 'package:sessiz_komsu/models/app_mode.dart';
import 'package:sessiz_komsu/providers/app_mode_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AppModeProvider', () {
    test('starts at onboarding and remembers the selected mode', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final provider = AppModeProvider(preferences: prefs);

      expect(provider.mode, AppMode.onboarding);
      expect(provider.onboardingCompleted, isFalse);

      provider.selectMode(AppMode.family);
      expect(provider.mode, AppMode.family);
      expect(prefs.getString(AppModeProvider.modeKey), 'family');

      final restored = AppModeProvider(preferences: prefs);
      expect(restored.mode, AppMode.family);
      expect(restored.onboardingCompleted, isTrue);
    });

    test('returning to mode selection clears the stored mode', () async {
      SharedPreferences.setMockInitialValues({
        AppModeProvider.modeKey: 'device',
      });
      final prefs = await SharedPreferences.getInstance();
      final provider = AppModeProvider(preferences: prefs);
      expect(provider.mode, AppMode.device);

      provider.returnToModeSelection();

      expect(provider.mode, AppMode.onboarding);
      expect(provider.onboardingCompleted, isTrue);
      expect(prefs.getString(AppModeProvider.modeKey), isNull);
    });

    test('ignores unknown stored values', () async {
      SharedPreferences.setMockInitialValues({
        AppModeProvider.modeKey: 'garbage',
      });
      final prefs = await SharedPreferences.getInstance();

      expect(AppModeProvider(preferences: prefs).mode, AppMode.onboarding);
    });

    test('works without storage and tracks UI preferences', () {
      final provider = AppModeProvider();
      var notifications = 0;
      provider.addListener(() => notifications++);

      provider
        ..selectMode(AppMode.family)
        ..selectSection(FamilySection.settings)
        ..setReduceMotion(true)
        ..setShowDemoPanel(false)
        ..setShowDemoPanel(false);

      expect(provider.familySection, FamilySection.settings);
      expect(provider.reduceMotion, isTrue);
      expect(provider.showDemoPanel, isFalse);
      expect(notifications, 4);
    });
  });
}
