import 'package:flutter/foundation.dart';

import '../models/routine_status.dart';
import '../services/demo_sensor_service.dart';
import '../services/routine_engine.dart';
import 'clock_provider.dart';
import 'sensor_provider.dart';

/// Routine status derived from the clock and sensor events.
///
/// Re-evaluates whenever time or events change. The rules themselves live in
/// [RoutineEngine]; this provider only applies side effects (alert events)
/// and the resident's confirmation.
class RoutineProvider extends ChangeNotifier {
  RoutineProvider({
    required this._clock,
    required this._sensors,
    this._engine = const RoutineEngine(),
    this._service = const DemoSensorService(),
  }) {
    _evaluation = _compute();
    _clock.addListener(evaluate);
    _sensors.addListener(evaluate);
    evaluate();
  }

  final ClockProvider _clock;
  final SensorProvider _sensors;
  final RoutineEngine _engine;
  final DemoSensorService _service;

  late RoutineEvaluation _evaluation;
  DateTime? _confirmedAt;
  int _batchDepth = 0;
  bool _evaluating = false;

  RoutineEngine get engine => _engine;
  RoutineEvaluation get evaluation => _evaluation;
  RoutineStatus get status => _evaluation.status;
  bool get isAlertActive => status.isAlert;
  DateTime? get confirmedAt => _confirmedAt;

  /// Runs [changes] on the clock/sensors and evaluates once afterwards.
  void batch(VoidCallback changes) {
    _batchDepth++;
    try {
      changes();
    } finally {
      _batchDepth--;
    }
    evaluate();
  }

  void evaluate() {
    if (_batchDepth > 0 || _evaluating) return;
    _evaluating = true;
    try {
      final result = _compute();
      if (result.status.isAlert) {
        final now = _clock.currentTime;
        _sensors.addEvent(_service.routineDelayed(now));
        if (result.status == RoutineStatus.awaitingConfirmation) {
          _sensors.addEvent(_service.confirmationRequested(now));
        }
      }
      if (result != _evaluation) {
        _evaluation = result;
        notifyListeners();
      }
    } finally {
      _evaluating = false;
    }
  }

  /// Resident pressed İYİYİM. Returns false when there is no active alert.
  bool confirmOkay() {
    if (!isAlertActive) return false;
    final now = _clock.currentTime;
    _confirmedAt = now;
    batch(() => _sensors.addEvent(_service.confirmed(now)));
    return true;
  }

  /// Forgets the confirmation; used by the demo reset.
  void clearConfirmation() {
    if (_confirmedAt == null) return;
    _confirmedAt = null;
    evaluate();
  }

  RoutineEvaluation _compute() => _engine.evaluate(
    now: _clock.currentTime,
    events: _sensors.events,
    confirmedAt: _confirmedAt,
  );

  @override
  void dispose() {
    _clock.removeListener(evaluate);
    _sensors.removeListener(evaluate);
    super.dispose();
  }
}
