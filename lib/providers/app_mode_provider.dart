import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_mode.dart';

/// Active mode, onboarding state and UI preferences.
///
/// Only the selected mode is persisted (via shared_preferences) so a page
/// refresh returns to the same screen. Demo data is never persisted.
class AppModeProvider extends ChangeNotifier {
  AppModeProvider({SharedPreferences? preferences}) : _prefs = preferences {
    final stored = AppMode.fromStorage(_prefs?.getString(modeKey));
    _mode = stored ?? AppMode.onboarding;
    _onboardingCompleted =
        (_prefs?.getBool(onboardingKey) ?? false) || stored != null;
  }

  static const modeKey = 'sessiz_komsu.mode';
  static const onboardingKey = 'sessiz_komsu.onboarding_completed';

  final SharedPreferences? _prefs;

  late AppMode _mode;
  late bool _onboardingCompleted;
  FamilySection _familySection = FamilySection.home;
  bool _reduceMotion = false;
  bool _showDemoPanel = true;

  AppMode get mode => _mode;
  bool get onboardingCompleted => _onboardingCompleted;
  FamilySection get familySection => _familySection;

  /// In-app reduced motion preference; combined with the OS setting in UI.
  bool get reduceMotion => _reduceMotion;
  bool get showDemoPanel => _showDemoPanel;

  void selectMode(AppMode mode) {
    assert(mode != AppMode.onboarding, 'Use returnToModeSelection instead.');
    if (_mode == mode && _onboardingCompleted) return;
    _mode = mode;
    _onboardingCompleted = true;
    if (mode == AppMode.family) _familySection = FamilySection.home;
    notifyListeners();
    _prefs?.setString(modeKey, mode.name).ignore();
    _prefs?.setBool(onboardingKey, true).ignore();
  }

  /// Shows the onboarding question again so the user can pick another mode.
  void returnToModeSelection() {
    if (_mode == AppMode.onboarding) return;
    _mode = AppMode.onboarding;
    notifyListeners();
    _prefs?.remove(modeKey).ignore();
  }

  void selectSection(FamilySection section) {
    if (_familySection == section) return;
    _familySection = section;
    notifyListeners();
  }

  void setReduceMotion(bool value) {
    if (_reduceMotion == value) return;
    _reduceMotion = value;
    notifyListeners();
  }

  void setShowDemoPanel(bool value) {
    if (_showDemoPanel == value) return;
    _showDemoPanel = value;
    notifyListeners();
  }
}
