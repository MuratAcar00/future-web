import '../core/utils/date_time_format.dart';
import '../models/sensor_event.dart';
import '../models/sensor_type.dart';

/// Produces every simulated event. No real hardware or backend is involved.
///
/// Event ids are deterministic so repeating an action never creates
/// duplicates in the event log.
class DemoSensorService {
  const DemoSensorService();

  static const _seedMorningCutoff = Duration(hours: 7, minutes: 30);

  /// Realistic seed history relative to [now].
  ///
  /// The morning events land on today once 07:30 has passed, otherwise on
  /// yesterday, so seed data is never in the future.
  List<SensorEvent> seedEvents(DateTime now) {
    final today = now.startOfDay;
    final anchor = now.isBefore(today.add(_seedMorningCutoff))
        ? today.subtract(const Duration(days: 1))
        : today;
    final previous = anchor.subtract(const Duration(days: 1));

    return [
      _seed(
        SensorType.fridge,
        previous.add(const Duration(hours: 21, minutes: 45)),
      ),
      _seed(
        SensorType.livingRoomLight,
        previous.add(const Duration(hours: 22, minutes: 18)),
      ),
      _seed(
        SensorType.entrance,
        anchor.add(const Duration(hours: 7, minutes: 12)),
      ),
      _seed(
        SensorType.kitchen,
        anchor.add(const Duration(hours: 7, minutes: 30)),
      ),
    ];
  }

  SensorEvent _seed(SensorType type, DateTime at) {
    final event = sensorEvent(type, at);
    return SensorEvent(
      id: 'seed-${event.id}',
      kind: event.kind,
      title: event.title,
      description: event.description,
      timestamp: at,
    );
  }

  /// Event for a sensor trigger. One event per sensor per minute.
  SensorEvent sensorEvent(SensorType type, DateTime at) {
    final (title, description) = switch (type) {
      SensorType.kitchen => (
        'Mutfak sensörü tetiklendi.',
        'Mutfak prizinin açılma zamanı simüle edildi; görüntü veya ses alınmaz.',
      ),
      SensorType.entrance => (
        'Dış kapı açıldı.',
        'Yalnızca kapının açılma zamanı simüle edilir; kişi tanıma yapılmaz.',
      ),
      SensorType.fridge => (
        'Buzdolabı kapağı açıldı.',
        'Kapağın açılma zamanı simüle edilir; içerik veya kişi belirlenmez.',
      ),
      SensorType.livingRoomLight => (
        'Salon ışığı açıldı.',
        'Işığın açılma zamanı simüle edilir; görüntü veya hareket verisi alınmaz.',
      ),
    };
    return SensorEvent(
      id: '${type.id}-${TurkishDateFormat.stamp(at)}',
      kind: EventKind.fromSensor(type),
      title: title,
      description: description,
      timestamp: at,
    );
  }

  SensorEvent alertScenarioStarted(DateTime at) => SensorEvent(
    id: 'scenario-alert-${TurkishDateFormat.dayStamp(at)}',
    kind: EventKind.demoScenario,
    title: 'Uyarı senaryosu başlatıldı.',
    description:
        'Demo saati ${TurkishDateFormat.time(at)} olarak ayarlandı; bu sabah '
        'için aktivite olayı kaydedilmedi.',
    timestamp: at,
  );

  SensorEvent routineDelayed(DateTime at) => SensorEvent(
    id: 'routine-delayed-${TurkishDateFormat.dayStamp(at)}',
    kind: EventKind.routineDelayed,
    title: 'Sabah rutini gecikti.',
    description: 'Beklenen saate kadar simüle aktivite olayı kaydedilmedi. Lütfen kontrol edin.',
    timestamp: at,
    severity: EventSeverity.alert,
  );

  SensorEvent confirmationRequested(DateTime at) => SensorEvent(
    id: 'confirmation-requested-${TurkishDateFormat.dayStamp(at)}',
    kind: EventKind.confirmationRequested,
    title: 'Cihaz ekranında onay istendi.',
    description: 'Yaşam alanı ekranında İYİYİM butonu gösterildi.',
    timestamp: at,
    severity: EventSeverity.alert,
  );

  SensorEvent confirmed(DateTime at) => SensorEvent(
    id: 'user-confirmation-${TurkishDateFormat.stamp(at)}',
    kind: EventKind.confirmed,
    title: 'Ayşe Hanım iyi olduğunu bildirdi.',
    description: 'Cihaz ekranındaki İYİYİM butonuna basıldı; uyarı kapatıldı.',
    timestamp: at,
    severity: EventSeverity.success,
  );
}
