import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_time_format.dart';
import '../../../core/widgets/hover_surface.dart';
import '../../../core/widgets/tag_chip.dart';
import '../../../models/connected_device.dart';
import '../../../models/sensor.dart';
import '../../../models/sensor_type.dart';
import '../../../providers/clock_provider.dart';
import '../../../providers/demo_provider.dart';
import '../../../providers/device_provider.dart';
import '../../../providers/sensor_provider.dart';
import 'family_page.dart';

/// Sensor cards in a responsive 2-column grid.
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
        LayoutBuilder(
          builder: (context, constraints) {
            final twoCol = constraints.maxWidth >= 480;

            final allCards = <Widget>[
              for (final type in SensorType.values) _SensorCard(type: type),
              for (final device in devices) _DeviceCard(device: device),
            ];

            if (!twoCol) {
              return Column(
                children: [
                  for (var i = 0; i < allCards.length; i++) ...[
                    allCards[i],
                    if (i < allCards.length - 1)
                      const SizedBox(height: AppSpacing.sm),
                  ],
                ],
              );
            }

            // 2-column grid
            final rows = <Widget>[];
            for (var i = 0; i < allCards.length; i += 2) {
              rows.add(
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: allCards[i]),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: i + 1 < allCards.length
                            ? allCards[i + 1]
                            : const SizedBox(),
                      ),
                    ],
                  ),
                ),
              );
              if (i + 2 < allCards.length) {
                rows.add(const SizedBox(height: AppSpacing.sm));
              }
            }
            return Column(children: rows);
          },
        ),
      ],
    );
  }
}

// ── Sensor card ───────────────────────────────────────────────────────────────

class _SensorCard extends StatelessWidget {
  const _SensorCard({required this.type});

  final SensorType type;

  @override
  Widget build(BuildContext context) {
    final sensor = context.select<SensorProvider, Sensor>(
      (p) => p.sensor(type),
    );
    final now = context.select<ClockProvider, DateTime>((c) => c.currentTime);
    final last = sensor.lastTriggered;
    final lastLabel =
        last == null ? 'Henüz yok' : TurkishDateFormat.relative(last, now);

    final (icon, iconColor, iconBg) = _sensorStyle(type, sensor.isOnline);

    return HoverSurface(
      borderRadius: AppRadius.lg,
      tooltip: 'Ayrıntılar için tıklayın',
      semanticLabel:
          '${sensor.name}. ${sensor.statusLabel}. Son durum: '
          '${sensor.lastState}, $lastLabel.',
      border: Border.all(color: AppColors.border),
      hoverBorderColor: AppColors.primaryBorder,
      hoverColor: AppColors.surfaceSecondary,
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => _SensorDetailsDialog(type: type),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: sensor.isOnline ? AppColors.success : AppColors.icon,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(sensor.name, style: AppTextStyles.bodyStrong),
            Text(sensor.location, style: AppTextStyles.secondary),
            const SizedBox(height: AppSpacing.sm),
            Text(
              lastLabel,
              style: AppTextStyles.secondary.copyWith(
                color: sensor.isOnline ? AppColors.success : AppColors.muted,
                fontWeight:
                    sensor.isOnline ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static (IconData, Color, Color) _sensorStyle(SensorType type, bool online) {
    if (!online) {
      return (Icons.sensors_off_outlined, AppColors.icon, AppColors.simulator);
    }
    return switch (type) {
      SensorType.kitchen => (
        Icons.kitchen_outlined,
        AppColors.primary,
        AppColors.primarySurface,
      ),
      SensorType.entrance => (
        Icons.door_front_door_outlined,
        AppColors.primary,
        AppColors.primarySurface,
      ),
      SensorType.bedroom => (
        Icons.bedroom_parent_outlined,
        AppColors.primary,
        AppColors.primarySurface,
      ),
    };
  }
}

// ── Connected device card ─────────────────────────────────────────────────────

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.device});

  final ConnectedDevice device;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.successSurface,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.sensors_outlined,
                  color: AppColors.success,
                  size: 18,
                ),
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(device.name, style: AppTextStyles.bodyStrong),
          Text(device.room, style: AppTextStyles.secondary),
          const SizedBox(height: AppSpacing.sm),
          Text(
            device.connectionLabel,
            style: AppTextStyles.secondary.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ── Sensor details dialog ─────────────────────────────────────────────────────

class _SensorDetailsDialog extends StatelessWidget {
  const _SensorDetailsDialog({required this.type});

  final SensorType type;

  @override
  Widget build(BuildContext context) {
    final sensor = context.select<SensorProvider, Sensor>(
      (p) => p.sensor(type),
    );
    final now =
        context.select<ClockProvider, DateTime>((c) => c.currentTime);
    final todayCount = context.select<SensorProvider, int>(
      (p) => p.events
          .where(
            (e) => e.kind.sensorType == type && e.timestamp.isSameDay(now),
          )
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

// ── ConnectedDeviceRow — kept for settings screen compatibility ───────────────

class ConnectedDeviceRow extends StatelessWidget {
  const ConnectedDeviceRow({super.key, required this.device});

  final ConnectedDevice device;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
    child: Row(
      children: [
        const Icon(Icons.sensors_outlined, color: AppColors.success),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(device.name, style: AppTextStyles.bodyStrong),
              Text(
                '${device.room} · ${device.connectionLabel} · simüle',
                style: AppTextStyles.secondary,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
