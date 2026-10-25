import 'package:flutter/foundation.dart';

import '../core/utils/date_time_format.dart';
import '../models/sensor_type.dart';
import '../services/demo_sensor_service.dart';
import 'clock_provider.dart';
import 'device_provider.dart';
import 'routine_provider.dart';
import 'sensor_provider.dart';

/// Demo panel scenarios. Every action is idempotent: repeating it never
/// creates duplicate timeline events.
class DemoProvider extends ChangeNotifier {
  DemoProvider({
    required this._clock,
    required this._sensors,
    required this._routine,
    this._devices,
    this._service = const DemoSensorService(),
  });

  final ClockProvider _clock;
  final SensorProvider _sensors;
  final RoutineProvider _routine;
  final DemoSensorService _service;
  final DeviceProvider? _devices;

  String? _lastAction;

  /// Text describing the latest demo action, announced to screen readers.
  String? get lastAction => _lastAction;

  bool triggerSensor(SensorType type) {
    final now = _clock.currentTime;
    final added = _sensors.trigger(type, now);
    _setLastAction(
      added
          ? '${type.name} tetiklendi (${TurkishDateFormat.time(now)}).'
          : '${type.name} bu dakika içinde zaten tetiklendi.',
    );
    return added;
  }

  /// Advances demo time by one hour; the routine re-evaluates on that clock.
  void advanceOneHour() {
    _clock.advance(const Duration(hours: 1));
    _setLastAction(
      'Demo saati ileri alındı: ${TurkishDateFormat.relative(_clock.currentTime, _clock.realNow)}.',
    );
  }

  /// Moves demo time to the next late morning without activity, which makes
  /// the routine engine raise the alert. No-op while an alert is active.
  bool startAlertScenario() {
    if (_routine.isAlertActive) {
      _setLastAction('Uyarı senaryosu zaten aktif.');
      return false;
    }
    final target = alertScenarioTarget();
    _routine.batch(() {
      _clock.setDemoTime(target);
      _sensors.addEvent(_service.alertScenarioStarted(target));
    });
    _setLastAction(
      'Uyarı senaryosu başlatıldı: ${TurkishDateFormat.relative(target, _clock.realNow)}.',
    );
    return true;
  }

  /// Late morning today if that would raise an alert, otherwise tomorrow.
  @visibleForTesting
  DateTime alertScenarioTarget() {
    final now = _clock.currentTime;
    final engine = _routine.engine;
    final todayTarget = now.atTimeOfDay(engine.lateMorning);
    if (todayTarget.isAfter(now)) {
      final preview = engine.evaluate(
        now: todayTarget,
        events: _sensors.events,
        confirmedAt: _routine.confirmedAt,
      );
      if (preview.status.isAlert) return todayTarget;
    }
    return now.add(const Duration(days: 1)).atTimeOfDay(engine.lateMorning);
  }

  /// Restores clock, sensors, routine and demo state to their initial values.
  void reset() {
    _routine.batch(() {
      _clock.resetDemoTime();
      _sensors.reset(_clock.currentTime);
      _devices?.reset();
      _routine.clearConfirmation();
    });
    _lastAction = null;
    notifyListeners();
  }

  void _setLastAction(String value) {
    _lastAction = value;
    notifyListeners();
  }
}
