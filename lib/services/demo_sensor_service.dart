import '../core/utils/date_time_format.dart';
import '../models/cloud_account.dart';
import '../models/device.dart';
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
        SensorType.kitchen,
        previous.add(const Duration(hours: 21, minutes: 45)),
      ),
      _seed(
        SensorType.bedroom,
        previous.add(const Duration(hours: 22, minutes: 18)),
      ),
      _seed(
        SensorType.bedroom,
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
        'Mutfak kullanımına ilişkin simüle edilmiş aktivite algılandı.',
      ),
      SensorType.entrance => (
        'Dış kapı açıldı.',
        'Dış kapı sensörü için demo olayı oluşturuldu.',
      ),
      SensorType.bedroom => (
        'Yatak odasında hareket algılandı.',
        'Yatak odası hareket sensörü simülasyonu çalıştı.',
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
        'için sensör hareketi yok.',
    timestamp: at,
  );

  SensorEvent routineDelayed(DateTime at) => SensorEvent(
    id: 'routine-delayed-${TurkishDateFormat.dayStamp(at)}',
    kind: EventKind.routineDelayed,
    title: 'Sabah rutini gecikti.',
    description:
        'Beklenen saatte sabah hareketi algılanmadı. Lütfen kontrol edin.',
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

  /// Trigger of an added device. One event per device per minute.
  SensorEvent deviceActivity(Device device, DateTime at) => SensorEvent(
    id: 'device-${device.id}-${TurkishDateFormat.stamp(at)}',
    kind: EventKind.deviceActivity,
    title: '${device.name}: ${device.kind.triggeredState ?? 'olay'}.',
    description:
        '${device.room.label} · eklenen cihaz için simüle edilmiş olay '
        'oluşturuldu.',
    timestamp: at,
    tagOverride: device.room.label,
  );

  /// [sequence] keeps add → remove → add within one minute distinct.
  SensorEvent deviceAdded(Device device, DateTime at, int sequence) =>
      SensorEvent(
        id: 'device-added-${device.id}-$sequence',
        kind: EventKind.deviceSetup,
        title: 'Yeni cihaz eklendi: ${device.name}',
        description:
            '${device.room.label} · ${device.protocol.label} · '
            '${device.sourceLabel} ile eklendi. Demo: gerçek bağlantı '
            'kurulmaz.',
        timestamp: at,
      );

  SensorEvent deviceRemoved(Device device, DateTime at, int sequence) =>
      SensorEvent(
        id: 'device-removed-${device.id}-$sequence',
        kind: EventKind.deviceSetup,
        title: 'Cihaz kaldırıldı: ${device.name}',
        description:
            '${device.room.label} odasındaki cihaz listeden çıkarıldı.',
        timestamp: at,
      );

  SensorEvent accountLinked(
    CloudProvider provider,
    int deviceCount,
    DateTime at,
    int sequence,
  ) => SensorEvent(
    id: 'account-linked-${provider.name}-$sequence',
    kind: EventKind.deviceSetup,
    title: 'Hesap bağlandı: ${provider.label}',
    description:
        '$deviceCount cihaz içe aktarıldı. Yalnızca olay türleri paylaşılır; '
        'ses veya görüntü yok (simülasyon).',
    timestamp: at,
  );

  SensorEvent accountUnlinked(
    CloudProvider provider,
    int deviceCount,
    DateTime at,
    int sequence,
  ) => SensorEvent(
    id: 'account-unlinked-${provider.name}-$sequence',
    kind: EventKind.deviceSetup,
    title: 'Hesap bağlantısı kaldırıldı: ${provider.label}',
    description: 'İçe aktarılan $deviceCount cihaz kaldırıldı.',
    timestamp: at,
  );
}
