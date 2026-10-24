import 'package:flutter/foundation.dart';

/// Morning routine state as computed by the routine engine.
enum RoutineStatus {
  /// Activity seen today, or still inside the expected morning window.
  normal('Normal'),

  /// No activity after the delay threshold; the family is warned.
  delayed('Gecikme'),

  /// Escalated: the device screen asks the resident to confirm.
  awaitingConfirmation('Onay bekleniyor'),

  /// The resident pressed İYİYİM on the device today.
  confirmedOkay('Onaylandı');

  const RoutineStatus(this.label);

  final String label;

  bool get isAlert => this == delayed || this == awaitingConfirmation;
}

/// Result of one routine engine evaluation.
@immutable
class RoutineEvaluation {
  const RoutineEvaluation({
    required this.status,
    required this.reason,
    this.hasActivityToday = false,
  });

  final RoutineStatus status;

  /// Human readable explanation of why the status was chosen.
  final String reason;
  final bool hasActivityToday;

  @override
  bool operator ==(Object other) =>
      other is RoutineEvaluation &&
      other.status == status &&
      other.reason == reason &&
      other.hasActivityToday == hasActivityToday;

  @override
  int get hashCode => Object.hash(status, reason, hasActivityToday);
}
