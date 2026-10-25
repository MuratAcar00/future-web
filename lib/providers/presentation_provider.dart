import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/utils/date_time_format.dart';
import '../models/app_mode.dart';
import '../models/presentation_step.dart';
import '../models/sensor_type.dart';
import 'app_mode_provider.dart';
import 'clock_provider.dart';
import 'demo_provider.dart';
import 'routine_provider.dart';

/// Guided "Sunum Modu" walkthrough for presenting the app.
///
/// Drives the real app providers through [presentationSteps]. A single timer
/// schedules the next beat (or the auto-advance at the end of a step).
/// Going back resets the demo and replays every earlier step; event ids are
/// deterministic, so replaying never duplicates timeline events.
class PresentationProvider extends ChangeNotifier
    implements PresentationScript {
  PresentationProvider({
    required this._appMode,
    required this._clock,
    required this._demo,
    required this._routine,
    List<PresentationStep>? steps,
  }) : steps = steps ?? presentationSteps;

  final AppModeProvider _appMode;
  final ClockProvider _clock;
  final DemoProvider _demo;
  final RoutineProvider _routine;
  final List<PresentationStep> steps;

  Timer? _timer;
  bool _active = false;
  bool _paused = false;
  int _index = 0;

  /// Next beat of the current step to run.
  int _beatCursor = 0;

  /// Step-relative time of the last beat that ran.
  Duration _cursorTime = Duration.zero;

  late DateTime _storyDay;
  AppMode _returnMode = AppMode.family;

  bool get isActive => _active;
  bool get isPaused => _paused;
  int get index => _index;
  int get stepCount => steps.length;
  PresentationStep get step => steps[_index];
  bool get isFirst => _index == 0;
  bool get isLast => _index == steps.length - 1;

  /// Overall progress, 1/n for the first step and 1.0 for the last.
  double get progress => (_index + 1) / steps.length;

  /// Highlighted areas of the current step (empty when inactive).
  Set<PresentationTarget> get focus => _active ? step.focus : const {};

  /// Resets the demo and plays the walkthrough from the first step.
  void start() {
    if (_active) return;
    _returnMode = _appMode.mode == AppMode.onboarding
        ? AppMode.onboarding
        : AppMode.family;
    _storyDay = _clock.realNow.startOfDay.add(const Duration(days: 1));
    _active = true;
    _paused = false;
    _appMode.selectSection(FamilySection.home);
    _rebuildTo(0);
  }

  void pause() {
    if (!_active || _paused) return;
    _paused = true;
    _cancelTimer();
    notifyListeners();
  }

  /// Continues the current segment; its wait restarts from the last beat.
  void resume() {
    if (!_active || !_paused) return;
    _paused = false;
    _schedule();
    notifyListeners();
  }

  void togglePause() => _paused ? resume() : pause();

  void next() {
    if (!_active || isLast) return;
    _runBeats(upTo: null);
    _enter(_index + 1);
  }

  void previous() {
    if (!_active) return;
    _rebuildTo(_index == 0 ? 0 : _index - 1);
  }

  /// Stops the walkthrough and returns to a clean, normal demo state.
  void finish() {
    if (!_active) return;
    _cancelTimer();
    _active = false;
    _paused = false;
    _index = 0;
    _demo.reset();
    if (_returnMode == AppMode.onboarding) {
      _appMode.returnToModeSelection();
    } else {
      _appMode.selectMode(AppMode.family);
      _appMode.selectSection(FamilySection.home);
    }
    notifyListeners();
  }

  /// Resets demo data, replays steps before [target] and enters [target].
  void _rebuildTo(int target) {
    _cancelTimer();
    _demo.reset();
    for (var i = 0; i < target; i++) {
      for (final beat in steps[i].beats) {
        beat.run(this);
      }
    }
    _enter(target);
  }

  void _enter(int target) {
    _index = target;
    _beatCursor = 0;
    _cursorTime = Duration.zero;
    _runBeats(upTo: Duration.zero);
    _schedule();
    notifyListeners();
  }

  /// Runs pending beats due at or before [upTo] (all when null).
  void _runBeats({required Duration? upTo}) {
    final beats = step.beats;
    while (_beatCursor < beats.length &&
        (upTo == null || beats[_beatCursor].at <= upTo)) {
      final beat = beats[_beatCursor++];
      _cursorTime = beat.at;
      beat.run(this);
    }
  }

  void _schedule() {
    _cancelTimer();
    if (!_active || _paused) return;
    final beats = step.beats;
    if (_beatCursor < beats.length) {
      final at = beats[_beatCursor].at;
      _timer = Timer(at - _cursorTime, () {
        _timer = null;
        _runBeats(upTo: at);
        _schedule();
        notifyListeners();
      });
    } else if (!isLast) {
      final remaining = step.duration - _cursorTime;
      _timer = Timer(remaining.isNegative ? Duration.zero : remaining, () {
        _timer = null;
        next();
      });
    }
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // PresentationScript ------------------------------------------------------

  @override
  void showFamily() {
    _appMode.selectMode(AppMode.family);
    _appMode.selectSection(FamilySection.home);
  }

  @override
  void showDevice() => _appMode.selectMode(AppMode.device);

  @override
  void setTime(int dayOffset, int hour, int minute) => _clock.setDemoTime(
    _storyDay
        .add(Duration(days: dayOffset))
        .atTimeOfDay(Duration(hours: hour, minutes: minute)),
  );

  @override
  void triggerSensor(SensorType type) => _demo.triggerSensor(type);

  @override
  void startAlertScenario() => _demo.startAlertScenario();

  @override
  void confirmOkay() => _routine.confirmOkay();

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }
}
