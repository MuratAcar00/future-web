import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/motion.dart';
import '../../../core/widgets/hover_surface.dart';
import '../../../core/widgets/reset_demo_dialog.dart';
import '../../../core/widgets/tag_chip.dart';
import '../../../models/routine_status.dart';
import '../../../models/sensor_type.dart';
import '../../../providers/clock_provider.dart';
import '../../../providers/demo_provider.dart';
import '../../../providers/routine_provider.dart';
import '../../presentation/presentation_layer.dart';

/// Developer / demo controls that drive the simulated scenarios.
///
/// As a right-hand column it fills its parent with the simulator background;
/// with [collapsible] it renders a header that expands/collapses the body.
class DemoPanel extends StatefulWidget {
  const DemoPanel({
    super.key,
    this.collapsible = false,
    this.initiallyExpanded = true,
  });

  final bool collapsible;
  final bool initiallyExpanded;

  @override
  State<DemoPanel> createState() => _DemoPanelState();
}

class _DemoPanelState extends State<DemoPanel> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    if (!widget.collapsible) {
      return const ColoredBox(
        color: AppColors.simulator,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: _DemoPanelBody(showHeader: true),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HoverSurface(
          borderRadius: AppRadius.lg,
          hoverColor: AppColors.border,
          pressedColor: AppColors.borderStrong,
          semanticLabel: _expanded
              ? 'Demo kontrollerini gizle'
              : 'Demo kontrollerini göster',
          onTap: () => setState(() => _expanded = !_expanded),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ExcludeSemantics(
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Geliştirici / Demo Kontrolleri',
                    style: AppTextStyles.bodyStrong,
                  ),
                ),
                const TagChip(label: 'DEMO MODE'),
                const SizedBox(width: AppSpacing.sm),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: context.motion(AppDurations.fade),
                  child: const Icon(Icons.expand_more, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: context.motion(AppDurations.state),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: _expanded
              ? const Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: _DemoPanelBody(showHeader: false),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _DemoPanelBody extends StatelessWidget {
  const _DemoPanelBody({required this.showHeader});

  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final demo = context.read<DemoProvider>();
    final status = context.select<RoutineProvider, RoutineStatus>(
      (r) => r.status,
    );
    final lastAction = context.select<DemoProvider, String?>(
      (d) => d.lastAction,
    );
    final date = context.select<ClockProvider, String>((c) => c.formattedDate);
    final time = context.select<ClockProvider, String>((c) => c.formattedTime);
    final demoTime = context.select<ClockProvider, bool>(
      (c) => c.isDemoTimeActive,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeader) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    'Geliştirici / Demo Kontrolleri',
                    style: AppTextStyles.section.copyWith(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const TagChip(label: 'DEMO MODE'),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        const Text(
          'Senaryoları tetikleyerek aile panelindeki değişimleri test edin.',
          style: AppTextStyles.secondary,
        ),
        const SizedBox(height: AppSpacing.xl),
        const _GroupLabel('SUNUM'),
        const StartPresentationButton(expand: true),
        const SizedBox(height: AppSpacing.xl),
        const _GroupLabel('SİMÜLASYONDAKİ SİNYALLER'),
        _DemoButton(
          icon: Icons.kitchen_outlined,
          label: 'Mutfak Prizini Aç',
          onTap: () => demo.triggerSensor(SensorType.kitchen),
        ),
        _DemoButton(
          icon: Icons.door_front_door_outlined,
          label: 'Dış Kapı Sensörü',
          onTap: () => demo.triggerSensor(SensorType.entrance),
        ),
        _DemoButton(
          icon: Icons.kitchen_outlined,
          label: 'Buzdolabı Kapağını Aç',
          onTap: () => demo.triggerSensor(SensorType.fridge),
        ),
        _DemoButton(
          icon: Icons.lightbulb_outline,
          label: 'Salon Işığını Aç',
          onTap: () => demo.triggerSensor(SensorType.livingRoomLight),
        ),
        const SizedBox(height: AppSpacing.sm),
        const _SimulationDetails(),
        const SizedBox(height: AppSpacing.xl),
        const _GroupLabel('ZAMAN'),
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            '${demoTime ? 'Demo saati' : 'Gerçek saat'}: $date · $time',
            style: AppTextStyles.secondary,
          ),
        ),
        _DemoButton(
          icon: Icons.fast_forward_outlined,
          label: 'Zamanı Hızlandır (+1 Saat)',
          onTap: demo.advanceOneHour,
        ),
        const SizedBox(height: AppSpacing.xl),
        const _GroupLabel('SENARYOLAR'),
        if (status.isAlert) _AlertActiveNotice(status: status),
        _DemoButton(
          icon: Icons.warning_amber_rounded,
          iconColor: AppColors.alert,
          label: 'Uyarı Senaryosunu Başlat',
          disabledHint: 'Uyarı zaten aktif',
          onTap: status.isAlert ? null : demo.startAlertScenario,
        ),
        _DemoButton(
          icon: Icons.restart_alt,
          label: AppStrings.resetDemo,
          onTap: () => confirmAndResetDemo(context),
        ),
        if (lastAction != null) ...[
          const SizedBox(height: AppSpacing.md),
          Semantics(
            liveRegion: true,
            child: Text(
              'Son işlem: $lastAction',
              style: AppTextStyles.secondary,
            ),
          ),
        ],
      ],
    );
  }
}

class _SimulationDetails extends StatelessWidget {
  const _SimulationDetails();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.background,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Bu demo hangi verileri üretir?', style: AppTextStyles.bodyStrong),
        SizedBox(height: AppSpacing.sm),
        _SimulationDetailRow(
          icon: Icons.power_outlined,
          label: 'Mutfak prizi',
          detail: 'Prizin açılma zamanı simüle edilir.',
        ),
        SizedBox(height: AppSpacing.xs),
        _SimulationDetailRow(
          icon: Icons.door_front_door_outlined,
          label: 'Dış kapı',
          detail: 'Yalnızca kapının açılma olayı kaydedilir.',
        ),
        SizedBox(height: AppSpacing.xs),
        _SimulationDetailRow(
          icon: Icons.kitchen_outlined,
          label: 'Buzdolabı kapağı',
          detail: 'Yalnızca kapağın açılma zamanı kaydedilir.',
        ),
        SizedBox(height: AppSpacing.xs),
        _SimulationDetailRow(
          icon: Icons.lightbulb_outline,
          label: 'Salon ışığı',
          detail: 'Yalnızca ışığın açılma zamanı kaydedilir.',
        ),
        SizedBox(height: AppSpacing.xs),
        _SimulationDetailRow(
          icon: Icons.schedule_outlined,
          label: 'Rutin durumu',
          detail: 'Saat ve bu dört sinyale göre hesaplanır.',
        ),
        Divider(height: AppSpacing.xl),
        Text(
          'Yatak odası hareketi izlenmez. Kamera, mikrofon ve konum kullanılmaz. Olaylar tarayıcı belleğinde simüle edilir.',
          style: AppTextStyles.secondary,
        ),
      ],
    ),
  );
}

class _SimulationDetailRow extends StatelessWidget {
  const _SimulationDetailRow({
    required this.icon,
    required this.label,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 16, color: AppColors.muted),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Text.rich(
          TextSpan(
            style: AppTextStyles.secondary,
            children: [
              TextSpan(
                text: '$label · ',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              TextSpan(text: detail),
            ],
          ),
        ),
      ),
    ],
  );
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(text, style: AppTextStyles.micro),
    );
  }
}

class _AlertActiveNotice extends StatelessWidget {
  const _AlertActiveNotice({required this.status});

  final RoutineStatus status;

  @override
  Widget build(BuildContext context) {
    final text = status == RoutineStatus.awaitingConfirmation
        ? 'Uyarı aktif: cihaz ekranında İYİYİM onayı bekleniyor.'
        : 'Gecikme algılandı: aktivite olayı olmazsa cihazdan onay istenecek.';
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.alertSurface,
        border: Border.all(color: AppColors.alertBorder),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 16, color: AppColors.alert),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.secondary.copyWith(color: AppColors.alert),
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoButton extends StatelessWidget {
  const _DemoButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = AppColors.text,
    this.disabledHint,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color iconColor;
  final String? disabledHint;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: HoverSurface(
        onTap: onTap,
        color: enabled ? AppColors.background : AppColors.simulator,
        border: Border.all(color: AppColors.border),
        tooltip: enabled ? null : disabledHint,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: enabled ? iconColor : AppColors.icon),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: enabled ? AppColors.text : AppColors.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
