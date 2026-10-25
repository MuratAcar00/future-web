import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/motion.dart';
import '../../core/widgets/hover_surface.dart';
import '../../core/widgets/tag_chip.dart';
import 'cloud_flow.dart';
import 'device_visuals.dart';
import 'qr_flow.dart';
import 'scan_flow.dart';

/// The three simulated ways of adding a device.
enum AddDeviceMethod {
  qr(
    'QR Kod ile Cihaz Ekle',
    'Yerel cihazlar (Wi-Fi · Bluetooth)',
    Icons.qr_code_2_outlined,
  ),
  scan(
    'Cihazları Tara',
    "Zigbee sensörleri ve akıllı TV'ler",
    Icons.wifi_tethering_outlined,
  ),
  cloud('Hesap Bağla', 'Bulut entegrasyonları', Icons.cloud_outlined);

  const AddDeviceMethod(this.title, this.subtitle, this.icon);

  final String title;
  final String subtitle;
  final IconData icon;
}

/// Opens the "Cihaz Ekle" dialog. Full-width on phones.
Future<void> showAddDeviceSheet(
  BuildContext context, {
  AddDeviceMethod? initialMethod,
}) {
  final isMobile = MediaQuery.sizeOf(context).width < AppBreakpoints.mobile;
  return showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      insetPadding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.xl),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: AddDeviceSheet(initialMethod: initialMethod),
      ),
    ),
  );
}

class AddDeviceSheet extends StatefulWidget {
  const AddDeviceSheet({super.key, this.initialMethod});

  final AddDeviceMethod? initialMethod;

  @override
  State<AddDeviceSheet> createState() => _AddDeviceSheetState();
}

class _AddDeviceSheetState extends State<AddDeviceSheet> {
  late AddDeviceMethod? _method = widget.initialMethod;

  void _close() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final method = _method;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.sm,
            0,
          ),
          child: Row(
            children: [
              if (method != null)
                IconButton(
                  tooltip: 'Yöntemlere dön',
                  onPressed: () => setState(() => _method = null),
                  icon: const Icon(Icons.arrow_back),
                )
              else
                const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    method?.title ?? 'Cihaz Ekle',
                    style: AppTextStyles.section,
                  ),
                ),
              ),
              const TagChip(label: 'SİMÜLE', background: AppColors.simulator),
              IconButton(
                tooltip: 'Kapat',
                onPressed: _close,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.sm,
            AppSpacing.xl,
            AppSpacing.lg,
          ),
          child: DemoNote(),
        ),
        const Divider(),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: AnimatedSwitcher(
              duration: context.motion(AppDurations.fade),
              child: KeyedSubtree(
                key: ValueKey(method),
                child: switch (method) {
                  null => _MethodChooser(
                    onSelected: (m) => setState(() => _method = m),
                  ),
                  AddDeviceMethod.qr => QrFlow(onDone: _close),
                  AddDeviceMethod.scan => ScanFlow(onDone: _close),
                  AddDeviceMethod.cloud => CloudFlow(onDone: _close),
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MethodChooser extends StatelessWidget {
  const _MethodChooser({required this.onSelected});

  final ValueChanged<AddDeviceMethod> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Evinize yeni bir sensör veya cihaz eklemek için bir yöntem seçin.',
          style: AppTextStyles.secondary,
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final method in AddDeviceMethod.values)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _MethodCard(
              method: method,
              autofocus: method == AddDeviceMethod.qr,
              onTap: () => onSelected(method),
            ),
          ),
      ],
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.method,
    required this.onTap,
    this.autofocus = false,
  });

  final AddDeviceMethod method;
  final VoidCallback onTap;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return HoverSurface(
      onTap: onTap,
      autofocus: autofocus,
      borderRadius: AppRadius.lg,
      color: AppColors.background,
      hoverColor: AppColors.surfaceSecondary,
      border: Border.all(color: AppColors.border),
      hoverBorderColor: AppColors.primary,
      semanticLabel: '${method.title}. ${method.subtitle}',
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: ExcludeSemantics(
        child: DeviceSummaryRow(
          icon: method.icon,
          title: method.title,
          subtitle: method.subtitle,
          trailing: const Icon(Icons.chevron_right, color: AppColors.icon),
        ),
      ),
    );
  }
}
