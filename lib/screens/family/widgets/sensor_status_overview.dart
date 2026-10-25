import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_time_format.dart';
import '../../../core/widgets/hover_surface.dart';
import '../../../core/widgets/status_dot.dart';
import '../../../core/widgets/tag_chip.dart';
import '../../../models/sensor.dart';
import '../../../models/sensor_type.dart';
import '../../../providers/clock_provider.dart';
import '../../../providers/demo_provider.dart';
import '../../../providers/device_provider.dart';
import '../../../providers/sensor_provider.dart';
import 'device_management.dart';
import 'family_page.dart';

/// Plain list of the simulated sensors with their latest state.
class SensorStatusOverview extends StatelessWidget {
  const SensorStatusOverview({super.key});

  @override
  Widget build(BuildContext context) {
    final devices = context.watch<DeviceProvider>().devices;
    final sensorCaption = devices.isEmpty
        ? '${SensorType.values.length} simüle sensör'
        : '${SensorType.values.length + devices.length} simüle cihaz';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FamilySectionHeader(title: 'Sensörler', caption: sensorCaption),
        FamilyCard(
          children: [
            for (final type in SensorType.values) _SensorRow(type: type),
            for (final device in devices) ConnectedDeviceRow(device: device),
          ],
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
