/// Motion durations shared by every animated widget.
abstract final class AppDurations {
  static const hover = Duration(milliseconds: 150);
  static const fade = Duration(milliseconds: 220);
  static const state = Duration(milliseconds: 320);
  static const timeline = Duration(milliseconds: 300);
  static const deviceSwitch = Duration(milliseconds: 400);
  static const pulse = Duration(milliseconds: 1800);
}

/// Width breakpoints for the responsive family dashboard.
abstract final class AppBreakpoints {
  /// Below this width the dashboard uses a bottom navigation bar.
  static const double mobile = 600;

  /// From this width the demo panel is shown as a right-hand column.
  static const double desktop = 1024;

  /// From this width the demo panel uses its wide size.
  static const double wide = 1280;
}

/// Fixed layout measurements.
abstract final class AppLayout {
  static const double sidebarWidth = 72;
  static const double demoPanelWidth = 320;
  static const double demoPanelCompactWidth = 300;
  static const double contentMaxWidth = 760;
  static const double bannerMinHeight = 172;
}
