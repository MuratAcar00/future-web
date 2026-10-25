import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/hover_surface.dart';
import '../../core/widgets/tag_chip.dart';
import '../../models/cloud_account.dart';
import '../../models/device.dart';
import '../../providers/device_provider.dart';
import 'device_actions.dart';
import 'device_visuals.dart';

/// Simulated cloud account linking: provider list → consent → connected.
/// No sign-in happens and no third-party service is contacted.
class CloudFlow extends StatefulWidget {
  const CloudFlow({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<CloudFlow> createState() => _CloudFlowState();
}

class _CloudFlowState extends State<CloudFlow> {
  CloudProvider? _provider;

  void _open(CloudProvider? provider) => setState(() => _provider = provider);

  Future<void> _link(CloudProvider provider) async {
    await context.read<DeviceProvider>().linkAccount(provider);
    if (mounted) setState(() {});
  }

  Future<void> _unlink(CloudProvider provider) async {
    final unlinked = await confirmUnlinkAccount(context, provider);
    if (unlinked && mounted) _open(null);
  }

  @override
  Widget build(BuildContext context) {
    final provider = _provider;
    if (provider == null) return _ProviderList(onSelected: _open);

    final linked = context.select<DeviceProvider, bool>(
      (p) => p.isLinked(provider),
    );
    if (linked) {
      return _Connected(
        provider: provider,
        onUnlink: () => _unlink(provider),
        onBack: () => _open(null),
        onDone: widget.onDone,
      );
    }
    return _Consent(
      provider: provider,
      onCancel: () => _open(null),
      onLink: () => _link(provider),
    );
  }
}

class _ProviderList extends StatelessWidget {
  const _ProviderList({required this.onSelected});

  final ValueChanged<CloudProvider> onSelected;

  @override
  Widget build(BuildContext context) {
    final devices = context.watch<DeviceProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Mevcut akıllı ev hesabınızdaki sensörleri içe aktarın. Logolar '
          'gösterilmez; bağlantılar simüledir.',
          style: AppTextStyles.secondary,
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final provider in CloudProvider.values)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _ProviderRow(
              provider: provider,
              account: devices.account(provider),
              onTap: () => onSelected(provider),
            ),
          ),
      ],
    );
  }
}

class _ProviderRow extends StatelessWidget {
  const _ProviderRow({
    required this.provider,
    required this.account,
    required this.onTap,
  });

  final CloudProvider provider;
  final CloudAccount? account;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final account = this.account;
    final status = account == null
        ? 'Bağlı değil'
        : 'Bağlı · ${account.deviceIds.length} cihaz';
    return HoverSurface(
      onTap: onTap,
      color: AppColors.background,
      border: Border.all(color: AppColors.border),
      hoverBorderColor: AppColors.borderStrong,
      semanticLabel: '${provider.label}. $status.',
      padding: const EdgeInsets.all(AppSpacing.md),
      child: ExcludeSemantics(
        child: DeviceSummaryRow(
          icon: provider.icon,
          title: provider.label,
          subtitle: status,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (account != null) const TagChip.success(label: 'BAĞLI'),
              const SizedBox(width: AppSpacing.xs),
              const Icon(Icons.chevron_right, color: AppColors.icon),
            ],
          ),
        ),
      ),
    );
  }
}

class _Consent extends StatelessWidget {
  const _Consent({
    required this.provider,
    required this.onCancel,
    required this.onLink,
  });

  final CloudProvider provider;
  final VoidCallback onCancel;
  final VoidCallback onLink;

  @override
  Widget build(BuildContext context) {
    final linking = context.select<DeviceProvider, CloudProvider?>(
      (p) => p.linking,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DeviceSummaryRow(
          icon: provider.icon,
          title: '${provider.label} hesabını bağla',
          subtitle: 'Simüle edilmiş izin ekranı · gerçek oturum açılmaz',
        ),
        const SizedBox(height: AppSpacing.xl),
        const Text(
          'Sessiz Komşu ile paylaşılacaklar',
          style: AppTextStyles.micro,
        ),
        const SizedBox(height: AppSpacing.xs),
        const CheckLine(text: 'Kapı açıldı / kapandı olayları'),
        const CheckLine(text: 'Hareket algılandı olayları'),
        const CheckLine(text: 'Priz açıldı / kapandı olayları'),
        const CheckLine(text: 'Cihaz adı ve oda bilgisi'),
        const SizedBox(height: AppSpacing.lg),
        const Text('Paylaşılmayacaklar', style: AppTextStyles.micro),
        const SizedBox(height: AppSpacing.xs),
        const CheckLine(text: 'Ses kaydı veya mikrofon', allowed: false),
        const CheckLine(text: 'Görüntü, kamera veya video', allowed: false),
        const CheckLine(text: 'Konum ve hesap şifresi', allowed: false),
        const SizedBox(height: AppSpacing.xl),
        if (linking == provider)
          BusyLine(text: '${provider.label} bağlanıyor… (simülasyon)')
        else
          FlowButtons(
            backLabel: 'Vazgeç',
            onBack: onCancel,
            nextLabel: 'Bağla',
            onNext: linking == null ? onLink : null,
          ),
      ],
    );
  }
}

class _Connected extends StatelessWidget {
  const _Connected({
    required this.provider,
    required this.onUnlink,
    required this.onBack,
    required this.onDone,
  });

  final CloudProvider provider;
  final VoidCallback onUnlink;
  final VoidCallback onBack;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final imported = context.select<DeviceProvider, List<Device>>(
      (p) => [
        for (final d in p.devices)
          if (d.account == provider) d,
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.success),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '${provider.label} bağlandı',
                  style: AppTextStyles.bodyStrong,
                ),
              ),
              const TagChip.success(label: 'BAĞLI'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          imported.isEmpty
              ? 'Bu hesapta içe aktarılan cihaz kalmadı.'
              : '${imported.length} cihaz içe aktarıldı. Yalnızca olay '
                    'türleri paylaşılır.',
          style: AppTextStyles.secondary,
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final device in imported)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: DeviceSummaryRow(
              icon: device.kind.icon,
              title: device.name,
              subtitle: '${device.room.label} · ${device.kind.label}',
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            TextButton(
              onPressed: onUnlink,
              style: TextButton.styleFrom(foregroundColor: AppColors.alert),
              child: const Text('Bağlantıyı kaldır'),
            ),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton(
                  onPressed: onBack,
                  child: const Text('Diğer hesaplar'),
                ),
                FilledButton(onPressed: onDone, child: const Text('Bitti')),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
