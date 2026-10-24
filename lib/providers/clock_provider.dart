import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/utils/date_time_format.dart';

typedef NowProvider = DateTime Function();

/// Single source of time for the app.
///
/// Real time and demo time are kept separate: [realNow] follows the injected
/// clock, [currentTime] adds the demo offset created by the demo panel.
/// Listeners are notified once per minute (and on every demo change).
class ClockProvider extends ChangeNotifier {
  ClockProvider({
    NowProvider? now,
    bool autoTick = true,
    Duration tickInterval = const Duration(seconds: 1),
  }) : _now = now ?? DateTime.now {
    _realNow = _now();
    if (autoTick) {
      _timer = Timer.periodic(tickInterval, (_) => tick());
    }
  }

  final NowProvider _now;
  Timer? _timer;
  late DateTime _realNow;
  Duration _demoOffset = Duration.zero;

  DateTime get realNow => _realNow;
  DateTime get currentTime => _realNow.add(_demoOffset);
  Duration get demoOffset => _demoOffset;
  bool get isDemoTimeActive => _demoOffset != Duration.zero;

  /// `07:30`
  String get formattedTime => TurkishDateFormat.time(currentTime);

  /// `24 Ekim 2026, Cumartesi`
  String get formattedDate => TurkishDateFormat.longDate(currentTime);

  /// Reads the injected clock; notifies only when the displayed minute changes.
  void tick() {
    final before = currentTime;
    _realNow = _now();
    final after = currentTime;
    if (TurkishDateFormat.stamp(before) != TurkishDateFormat.stamp(after)) {
      notifyListeners();
    }
  }

  /// Moves demo time forward. Real time is unaffected.
  void advance(Duration duration) {
    assert(!duration.isNegative, 'Demo time only moves forward.');
    if (duration == Duration.zero) return;
    _demoOffset += duration;
    notifyListeners();
  }

  /// Sets demo time so that [currentTime] equals [target].
  void setDemoTime(DateTime target) {
    _realNow = _now();
    _demoOffset = target.difference(_realNow);
    notifyListeners();
  }

  void resetDemoTime() {
    _realNow = _now();
    _demoOffset = Duration.zero;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}
