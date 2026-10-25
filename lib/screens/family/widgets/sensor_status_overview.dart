import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_time_format.dart';
import '../../../core/widgets/hover_surface.dart';
import '../../../core/widgets/status_dot.dart';
import '../../../core/widgets/tag_chip.dart';
import '../../../models/device.dart';
import '../../../models/sensor.dart';
import '../../../models/sensor_type.dart';
import '../../../providers/clock_provider.dart';
import '../../../providers/demo_provider.dart';
import '../../../providers/device_provider.dart';
import '../../../providers/sensor_provider.dart';
import '../../devices/add_device_sheet.dart';
import 'family_page.dart';

/// Plain list of the simulated sensors and added devices with their latest
/// state, plus the "Cihaz Ekle" entry point.
class SensorStatusOverview extends StatelessWidget {
  const SensorStatusOverview({super.key});

  @override
  Widget build(BuildContext context) {
    final devices = context.select<DeviceProvider, List<Device>>(
      (p) => p.devices,
    );
    final count = SensorType.values.length + devices.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FamilySectionHeader(
          title: 'Sensörler',
          caption: '$count simüle cihaz',
          trailing: TextButton.icon(
            onPressed: () => showAddDeviceSheet(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Cihaz Ekle'),
          ),
        ),
        FamilyCard(
          children: [
            for (final type in SensorType.values) _SensorRow(type: type),
            for (final device in devices) _DeviceRow(device: device),
          ],
        ),
      ],
    );
  }
}

/// Row of a device added through the add-device flows.
class _DeviceRow extends StatelessWidget {
  const _DeviceRow({required this.device});

  final Device device;

  @override
  Widget build(BuildContext context) {
    final now = context.select<ClockProvider, DateTime>((c) => c.currentTime);
    final last = device.lastTriggered;
    final lastLabel = last == null
        ? 'Henüz yok'
        : TurkishDateFormat.relative(last, now);

    return HoverSurface(
      borderRadius: 0,
      tooltip: 'Ayrıntılar için tıklayın',
      semanticLabel:
          '${device.name}. ${device.room.label}, ${device.protocol.label}. '
          '${device.statusLabel}. Son durum: ${device.lastState}, $lastLabel.',
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => _DeviceDetailsDialog(id: device.id),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: ExcludeSemantics(
        child: Row(
          children: [
            const StatusDot(color: AppColors.success),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        device.name,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TagChip(label: device.protocol.label.toUpperCase()),
                    ],
                  ),
                  Text(
                    '${device.room.label} · ${device.lastState}',
                    style: AppTextStyles.secondary,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(lastLabel, style: AppTextStyles.secondary),
            const SizedBox(width: AppSpacing.sm),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.icon),
          ],
        ),
      ),
    );
  }
}

class _DeviceDetailsDialog extends StatelessWidget {
  const _DeviceDetailsDialog({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final device = context.select<DeviceProvider, Device?>((p) => p.device(id));
    final now = context.select<ClockProvider, DateTime>((c) => c.currentTime);
    if (device == null) {
      return AlertDialog(
        title: const Text('Cihaz kaldırıldı'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
        ],
      );
    }
    final last = device.lastTriggered;

    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(device.name)),
          const SizedBox(width: AppSpacing.sm),
          const TagChip(label: 'SİMÜLE', background: AppColors.simulator),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DetailRow(label: 'Oda', value: device.room.label),
            _DetailRow(label: 'Tür', value: device.kind.label),
            _DetailRow(label: 'Protokol', value: device.protocol.label),
            _DetailRow(label: 'Eklenme', value: device.sourceLabel),
            _DetailRow(label: 'Bağlantı', value: device.statusLabel),
            _DetailRow(label: 'Son durum', value: device.lastState),
            _DetailRow(
              label: 'Son tetiklenme',
              value: last == null
                  ? 'Henüz yok'
                  : TurkishDateFormat.relative(last, now),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Bu cihaz tarayıcıda simüle edilir; gerçek bir bağlantı '
              'kurulmamıştır. Ayarlar > Cihazlar bölümünden yönetebilirsiniz.',
              style: AppTextStyles.secondary,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Kapat'),
        ),
        if (device.canTrigger)
          FilledButton(
            onPressed: () => context.read<DemoProvider>().triggerDevice(id),
            child: const Text('Şimdi tetikle'),
          ),
      ],
    );
  }
}

class _SensorRow extends StatelessWidget {
  const _SensorRow({required this.type});

  final SensorType type;

  @override
  Widget build(BuildContext context) {
    final sensor = context.select<SensorProvider, Sensor>(
      (p) => p.sensor(type),
    );
    final now = context.select<ClockProvider, DateTime>((c) => c.currentTime);
    final last = sensor.lastTriggered;
    final lastLabel = last == null
        ? 'Henüz yok'
        : TurkishDateFormat.relative(last, now);

    return HoverSurface(
      borderRadius: 0,
      tooltip: 'Ayrıntılar için tıklayın',
      semanticLabel:
          '${sensor.name}. ${sensor.statusLabel}. Son durum: '
          '${sensor.lastState}, $lastLabel.',
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => _SensorDetailsDialog(type: type),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: ExcludeSemantics(
        child: Row(
          children: [
            StatusDot(
              color: sensor.isOnline ? AppColors.success : AppColors.icon,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sensor.name,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${sensor.location} · ${sensor.lastState}',
                    style: AppTextStyles.secondary,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(lastLabel, style: AppTextStyles.secondary),
            const SizedBox(width: AppSpacing.sm),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.icon),
          ],
        ),
      ),
    );
  }
}

class _SensorDetailsDialog extends StatelessWidget {
  const _SensorDetailsDialog({required this.type});

  final SensorType type;

  @override
  Widget build(BuildContext context) {
    final sensor = context.select<SensorProvider, Sensor>(
      (p) => p.sensor(type),
    );
    final now = context.select<ClockProvider, DateTime>((c) => c.currentTime);
    final todayCount = context.select<SensorProvider, int>(
      (p) => p.events
          .where((e) => e.kind.sensorType == type && e.timestamp.isSameDay(now))
          .length,
    );
    final last = sensor.lastTriggered;

    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(sensor.name)),
          const SizedBox(width: AppSpacing.sm),
          const TagChip(label: 'SİMÜLE', background: AppColors.simulator),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DetailRow(label: 'Konum', value: sensor.location),
            _DetailRow(label: 'Bağlantı', value: sensor.statusLabel),
            _DetailRow(label: 'Son durum', value: sensor.lastState),
            _DetailRow(
              label: 'Son tetiklenme',
              value: last == null
                  ? 'Henüz yok'
                  : TurkishDateFormat.relative(last, now),
            ),
            _DetailRow(label: 'Bugünkü olay', value: '$todayCount'),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Bu sensör tarayıcıda simüle edilir; gerçek bir cihaza bağlı değildir.',
              style: AppTextStyles.secondary,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Kapat'),
        ),
        FilledButton(
          onPressed: () => context.read<DemoProvider>().triggerSensor(type),
          child: const Text('Şimdi tetikle'),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
            child: Text(label, style: AppTextStyles.secondary),
          ),
          Expanded(child: Text(value, style: AppTextStyles.body)),
        ],
      ),
    );
  }
}
