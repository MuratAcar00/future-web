/// Top-level screen the app is showing.
enum AppMode {
  onboarding,
  device,
  family;

  static AppMode? fromStorage(String? value) {
    for (final mode in values) {
      if (mode.name == value) return mode;
    }
    return null;
  }
}

/// Sections reachable from the family dashboard navigation.
enum FamilySection { home, settings, profile }
