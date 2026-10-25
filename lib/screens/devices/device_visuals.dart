import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/motion.dart';
import '../../core/widgets/hover_surface.dart';
import '../../models/cloud_account.dart';
import '../../models/device.dart';

/// Honest label shown on every add-device screen.
const demoConnectionNote = 'Demo: gerçek bağlantı kurulmaz.';

extension DeviceKindIcon on DeviceKind {
  IconData get icon => switch (this) {
    DeviceKind.doorSensor => Icons.door_front_door_outlined,
    DeviceKind.motionSensor => Icons.sensors_outlined,
    DeviceKind.smartPlug => Icons.power_outlined,
    DeviceKind.smartTv => Icons.tv_outlined,
  };
}

/// Neutral, generic icons; no third-party logos are shipped.
extension CloudProviderIcon on CloudProvider {
  IconData get icon => switch (this) {
    CloudProvider.googleHome => Icons.home_outlined,
    CloudProvider.amazonAlexa => Icons.speaker_outlined,
    CloudProvider.boschSmartHome => Icons.hub_outlined,
    CloudProvider.smartThings => Icons.device_hub_outlined,
  };
}

/// Icon on a soft brand tile, used for device and method rows.
class DeviceIconTile extends StatelessWidget {
  const DeviceIconTile({super.key, required this.icon, this.size = 40});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        border: Border.all(color: AppColors.primaryBorder),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(icon, size: size * 0.5, color: AppColors.primary),
    );
  }
}

/// Four signal bars with a text equivalent for screen readers.
class SignalBars extends StatelessWidget {
  const SignalBars({super.key, required this.signal});

  final SignalStrength signal;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Sinyal: ${signal.label}',
      child: ExcludeSemantics(
        child: Tooltip(
          message: 'Simüle sinyal: ${signal.label}',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 1; i <= 4; i++) ...[
                if (i > 1) const SizedBox(width: 2),
                Container(
                  width: 4,
                  height: 4.0 + i * 3,
                  decoration: BoxDecoration(
                    color: i <= signal.bars
                        ? AppColors.primary
                        : AppColors.borderStrong,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Small inline note that the flow is simulated.
class DemoNote extends StatelessWidget {
  const DemoNote({super.key, this.text = demoConnectionNote});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.simulator,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.muted),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: AppTextStyles.secondary)),
        ],
      ),
    );
  }
}

/// Wrap of selectable room pills (keyboard accessible).
class RoomPicker extends StatelessWidget {
  const RoomPicker({
    super.key,
    required this.selected,
    required this.onChanged,
    this.semanticPrefix = '',
  });

  final Room? selected;
  final ValueChanged<Room> onChanged;

  /// Prepended to each pill's semantic label, e.g. the device name.
  final String semanticPrefix;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final room in Room.values)
          _RoomPill(
            room: room,
            selected: room == selected,
            semanticPrefix: semanticPrefix,
            onTap: () => onChanged(room),
          ),
      ],
    );
  }
}

class _RoomPill extends StatelessWidget {
  const _RoomPill({
    required this.room,
    required this.selected,
    required this.semanticPrefix,
    required this.onTap,
  });

  final Room room;
  final bool selected;
  final String semanticPrefix;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HoverSurface(
      onTap: onTap,
      selected: selected,
      semanticLabel: '$semanticPrefix${room.label}',
      color: selected ? AppColors.primarySurface : AppColors.background,
      hoverColor: selected ? AppColors.primarySurface : AppColors.simulator,
      border: Border.all(
        color: selected ? AppColors.primary : AppColors.border,
      ),
      hoverBorderColor: selected ? AppColors.primary : AppColors.borderStrong,
      borderRadius: AppRadius.pill,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check, size: 16, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              room.label,
              style: AppTextStyles.body.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: selected ? AppColors.primaryPressed : AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Adım 2/5 · Cihaz tanındı" with a thin determinate progress bar.
class FlowStepIndicator extends StatelessWidget {
  const FlowStepIndicator({
    super.key,
    required this.current,
    required this.labels,
  });

  /// Zero-based index into [labels].
  final int current;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Adım ${current + 1}/${labels.length} · ${labels[current]}',
          style: AppTextStyles.micro,
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            value: (current + 1) / labels.length,
            minHeight: 3,
          ),
        ),
      ],
    );
  }
}

/// Checklist row used on the recognised / consent screens.
class CheckLine extends StatelessWidget {
  const CheckLine({super.key, required this.text, this.allowed = true});

  final String text;

  /// True renders a check mark, false a "not shared" cross.
  final bool allowed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            allowed ? Icons.check_circle_outline : Icons.block,
            size: 18,
            color: allowed ? AppColors.success : AppColors.muted,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: AppTextStyles.body)),
        ],
      ),
    );
  }
}

/// Icon tile, name and subtitle with an optional trailing widget.
class DeviceSummaryRow extends StatelessWidget {
  const DeviceSummaryRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final trailing = this.trailing;
    return Row(
      children: [
        DeviceIconTile(icon: icon),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
              ),
              Text(subtitle, style: AppTextStyles.secondary),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.md),
          trailing,
        ],
      ],
    );
  }
}

/// Progress text announced to screen readers. The spinner is replaced by a
/// static icon when reduced motion is requested.
class BusyLine extends StatelessWidget {
  const BusyLine({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Row(
        children: [
          if (context.reduceMotion)
            const Icon(
              Icons.hourglass_top_outlined,
              size: 18,
              color: AppColors.primary,
            )
          else
            const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(text, style: AppTextStyles.body)),
        ],
      ),
    );
  }
}

/// Back / next button pair shared by the flows.
class FlowButtons extends StatelessWidget {
  const FlowButtons({
    super.key,
    required this.onBack,
    required this.nextLabel,
    required this.onNext,
    this.backLabel = 'Geri',
  });

  final String backLabel;
  final VoidCallback onBack;
  final String nextLabel;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        OutlinedButton(onPressed: onBack, child: Text(backLabel)),
        FilledButton(onPressed: onNext, child: Text(nextLabel)),
      ],
    );
  }
}
