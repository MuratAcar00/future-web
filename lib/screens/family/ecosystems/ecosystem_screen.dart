import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/device_provider.dart';
import '../widgets/family_page.dart';

// ── Platform data ─────────────────────────────────────────────────────────────

class _Platform {
  const _Platform({
    required this.id,
    required this.name,
    required this.protocol,
    required this.description,
    required this.color,
    required this.icon,
  });

  final String id;
  final String name;
  final String protocol;
  final String description;
  final Color color;
  final IconData icon;
}


const _platforms = [
  _Platform(
    id: 'Amazon Alexa',
    name: 'Amazon Alexa',
    protocol: 'Cloud API',
    description: 'Echo cihazlarına bağlı akıllı ev ekipmanlarını içe aktar.',
    color: Color(0xFF00CAFF),
    icon: Icons.record_voice_over_outlined,
  ),
  _Platform(
    id: 'Google Home',
    name: 'Google Home',
    protocol: 'Cloud API',
    description: 'Nest cihazları, termostat ve bağlı prizleri içe aktar.',
    color: Color(0xFF4285F4),
    icon: Icons.home_outlined,
  ),
  _Platform(
    id: 'Apple HomeKit',
    name: 'Apple HomeKit',
    protocol: 'HomeKit',
    description: 'HomeKit aksesuarlarını ve sahneleri içe aktar.',
    color: Color(0xFF555555),
    icon: Icons.phone_iphone_outlined,
  ),
  _Platform(
    id: 'Siemens KNX',
    name: 'Siemens KNX',
    protocol: 'KNX / IP',
    description: 'Bina otomasyonu — ışık, ısıtma ve aktüatörleri bağla.',
    color: Color(0xFF009999),
    icon: Icons.settings_input_component_outlined,
  ),
  _Platform(
    id: 'Bosch Smart Home',
    name: 'Bosch Smart Home',
    protocol: 'Cloud API',
    description: 'Kontak, hareket ve pencere sensörlerini içe aktar.',
    color: Color(0xFF00479B),
    icon: Icons.sensors_outlined,
  ),
  _Platform(
    id: 'Philips Hue',
    name: 'Philips Hue',
    protocol: 'Zigbee · Matter',
    description: 'Ampul, şerit LED ve sahne gruplarını içe aktar.',
    color: Color(0xFF0066CC),
    icon: Icons.lightbulb_outlined,
  ),
  _Platform(
    id: 'SmartThings',
    name: 'Samsung SmartThings',
    protocol: 'Cloud API',
    description: 'SmartThings hub ve bağlı sensörleri içe aktar.',
    color: Color(0xFF1428A0),
    icon: Icons.hub_outlined,
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class EcosystemScreen extends StatelessWidget {
  const EcosystemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FamilyPage(
      children: [
        const FamilyPageTitle(
          title: 'Ekosistemler',
          subtitle:
              'Mevcut akıllı ev platformlarınızı bağlayın; cihazlar otomatik içe aktarılır.',
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Hesap izni ve içe aktarma bu demoda simüledir. Gerçek hesap bilgisi gerekmez.',
          style: AppTextStyles.secondary,
        ),
        const SizedBox(height: AppSpacing.xxl),
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < _platforms.length; i++) ...[
                if (i > 0)
                  const Divider(height: 1, indent: AppSpacing.lg, endIndent: AppSpacing.lg),
                _PlatformRow(platform: _platforms[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── Platform row ──────────────────────────────────────────────────────────────

class _PlatformRow extends StatelessWidget {
  const _PlatformRow({required this.platform});

  final _Platform platform;

  @override
  Widget build(BuildContext context) {
    final devices = context.watch<DeviceProvider>();
    final linked = devices.linkedAccounts.contains(platform.id);
    final count = devices.importedDeviceCount(platform.id);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          // Icon badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: platform.color.withValues(alpha: 20 / 255.0),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: platform.color.withValues(alpha: 40 / 255.0),
              ),
            ),
            child: Icon(platform.icon, color: platform.color, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          // Name + protocol + description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(platform.name, style: AppTextStyles.bodyStrong),
                    const SizedBox(width: AppSpacing.sm),
                    _ProtocolChip(label: platform.protocol),
                  ],
                ),
                const SizedBox(height: 2),
                Text(platform.description, style: AppTextStyles.secondary),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Action
          linked
              ? _LinkedBadge(
                  deviceCount: count,
                  onUnlink: () => _confirmUnlink(context, devices),
                )
              : FilledButton(
                  onPressed: () => _startOAuth(context),
                  child: const Text('Bağla'),
                ),
        ],
      ),
    );
  }

  Future<void> _startOAuth(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _OAuthDialog(platform: platform),
    );
  }

  Future<void> _confirmUnlink(BuildContext context, DeviceProvider devices) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${platform.name} bağlantısını kes'),
        content: Text(
          '${platform.name} içe aktarılan tüm cihazlar kaldırılacak. Devam edilsin mi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Bağlantıyı kes'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<DeviceProvider>().unlinkAccount(platform.id);
    }
  }
}

// ── Linked badge with unlink ──────────────────────────────────────────────────

class _LinkedBadge extends StatelessWidget {
  const _LinkedBadge({required this.deviceCount, required this.onUnlink});

  final int deviceCount;
  final VoidCallback onUnlink;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxs,
          ),
          decoration: BoxDecoration(
            color: AppColors.successSurface,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.successBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline, size: 12, color: AppColors.success),
              const SizedBox(width: 4),
              Text(
                'Bağlı · $deviceCount cihaz',
                style: AppTextStyles.secondary.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onUnlink,
          child: Text(
            'Bağlantıyı kes',
            style: AppTextStyles.secondary.copyWith(
              fontSize: 11,
              color: AppColors.muted,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Protocol chip ─────────────────────────────────────────────────────────────

class _ProtocolChip extends StatelessWidget {
  const _ProtocolChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.simulator,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(label, style: AppTextStyles.secondary.copyWith(fontSize: 10)),
    );
  }
}

// ── OAuth simulation dialog ───────────────────────────────────────────────────

class _OAuthDialog extends StatefulWidget {
  const _OAuthDialog({required this.platform});

  final _Platform platform;

  @override
  State<_OAuthDialog> createState() => _OAuthDialogState();
}

enum _OAuthStep { connecting, done }

class _OAuthDialogState extends State<_OAuthDialog> {
  _OAuthStep _step = _OAuthStep.connecting;

  @override
  void initState() {
    super.initState();
    final deviceProvider = context.read<DeviceProvider>();
    final platformId = widget.platform.id;
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      deviceProvider.linkAccount(platformId);
      setState(() => _step = _OAuthStep.done);
    });
  }

  @override
  Widget build(BuildContext context) {
    final count = context.watch<DeviceProvider>().importedDeviceCount(widget.platform.id);

    return AlertDialog(
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: widget.platform.color.withValues(alpha: 20 / 255.0),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(widget.platform.icon, color: widget.platform.color, size: 16),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(widget.platform.name),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _step == _OAuthStep.connecting
              ? _ConnectingBody(key: const ValueKey('c'), platformName: widget.platform.name)
              : _DoneBody(key: const ValueKey('d'), deviceCount: count),
        ),
      ),
      actions: [
        if (_step == _OAuthStep.done)
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
      ],
    );
  }
}

class _ConnectingBody extends StatelessWidget {
  const _ConnectingBody({super.key, required this.platformName});

  final String platformName;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('$platformName hesabına bağlanılıyor…'),
        const SizedBox(height: AppSpacing.lg),
        const LinearProgressIndicator(),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Hesap izni ve cihaz listesi bu demoda simüle edilir.',
          style: AppTextStyles.secondary,
        ),
      ],
    );
  }
}

class _DoneBody extends StatelessWidget {
  const _DoneBody({super.key, required this.deviceCount});

  final int deviceCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
            const SizedBox(width: AppSpacing.sm),
            const Text(
              'Bağlantı kuruldu!',
              style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          '$deviceCount cihaz başarıyla içe aktarıldı. '
          'Cihazlar "Ayarlar → Cihazlar" bölümünde görüntülenebilir.',
        ),
      ],
    );
  }
}
