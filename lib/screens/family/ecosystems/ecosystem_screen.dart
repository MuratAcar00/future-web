import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/device_provider.dart';
import '../widgets/family_page.dart';

// ── Platform data ────────────────────────────────────────────────────────────

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

class _Category {
  const _Category({required this.title, required this.platforms});

  final String title;
  final List<_Platform> platforms;
}

const _categories = [
  _Category(
    title: 'Sesli Asistan',
    platforms: [
      _Platform(
        id: 'Amazon Alexa',
        name: 'Amazon Alexa',
        protocol: 'Matter · Cloud API',
        description: 'Echo cihazlarını ve bağlı akıllı ev ekipmanlarını içe aktar.',
        color: Color(0xFF00CAFF),
        icon: Icons.record_voice_over_outlined,
      ),
      _Platform(
        id: 'Google Home',
        name: 'Google Home',
        protocol: 'Matter · Cloud API',
        description: 'Nest cihazları, termostat ve bağlı prizleri içe aktar.',
        color: Color(0xFF4285F4),
        icon: Icons.home_outlined,
      ),
      _Platform(
        id: 'Apple HomeKit',
        name: 'Apple HomeKit',
        protocol: 'Matter · HomeKit',
        description: 'HomeKit aksesuarlarını ve sahneleri içe aktar.',
        color: Color(0xFF555555),
        icon: Icons.phone_iphone_outlined,
      ),
    ],
  ),
  _Category(
    title: 'Avrupa / Endüstriyel',
    platforms: [
      _Platform(
        id: 'Siemens KNX',
        name: 'Siemens KNX',
        protocol: 'KNX / IP',
        description: 'Binalardaki KNX aktüatör, ışık ve ısıtma sistemlerini bağla.',
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
        id: 'Somfy',
        name: 'Somfy TaHoma',
        protocol: 'io-homecontrol · TaHoma API',
        description: 'Motorlu perdeler, jaluzi ve güneşlik kontrollerini bağla.',
        color: Color(0xFFE64A19),
        icon: Icons.blinds_outlined,
      ),
    ],
  ),
  _Category(
    title: 'Akıllı Işık',
    platforms: [
      _Platform(
        id: 'Philips Hue',
        name: 'Philips Hue',
        protocol: 'Zigbee · Matter',
        description: 'Ampul, şerit LED ve sahne gruplarını içe aktar.',
        color: Color(0xFF0066CC),
        icon: Icons.lightbulb_outlined,
      ),
      _Platform(
        id: 'IKEA Trådfri',
        name: 'IKEA Trådfri',
        protocol: 'Zigbee · Matter',
        description: 'IKEA akıllı ampul ve sensörlerini içe aktar.',
        color: Color(0xFF003E6B),
        icon: Icons.emoji_objects_outlined,
      ),
    ],
  ),
  _Category(
    title: 'Genel IoT',
    platforms: [
      _Platform(
        id: 'Tuya / Smart Life',
        name: 'Tuya / Smart Life',
        protocol: 'Wi-Fi · Tuya Cloud',
        description: 'Geniş marka yelpazesindeki Wi-Fi cihazlarını içe aktar.',
        color: Color(0xFF1F6BFF),
        icon: Icons.device_hub_outlined,
      ),
      _Platform(
        id: 'SmartThings',
        name: 'Samsung SmartThings',
        protocol: 'Matter · Cloud API',
        description: 'SmartThings hub ve bağlı sensörleri içe aktar.',
        color: Color(0xFF1428A0),
        icon: Icons.hub_outlined,
      ),
    ],
  ),
];

// ── Screen ───────────────────────────────────────────────────────────────────

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
        for (final category in _categories) ...[
          FamilySectionHeader(title: category.title),
          const SizedBox(height: AppSpacing.md),
          _PlatformGrid(platforms: category.platforms),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ],
    );
  }
}

// ── Responsive grid ──────────────────────────────────────────────────────────

class _PlatformGrid extends StatelessWidget {
  const _PlatformGrid({required this.platforms});

  final List<_Platform> platforms;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 1 column < 520px, 2 columns < 900px, 3 columns otherwise
        final columns = constraints.maxWidth < 520
            ? 1
            : constraints.maxWidth < 900
            ? 2
            : 3;

        if (columns == 1) {
          return Column(
            children: [
              for (final p in platforms) ...[
                _PlatformCard(platform: p),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          );
        }

        // Build rows of `columns` cards each
        final rows = <Widget>[];
        for (var i = 0; i < platforms.length; i += columns) {
          final slice = platforms.skip(i).take(columns).toList();
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var j = 0; j < slice.length; j++) ...[
                    if (j > 0) const SizedBox(width: AppSpacing.md),
                    Expanded(child: _PlatformCard(platform: slice[j])),
                  ],
                  // Fill empty slots in the last row
                  for (var k = slice.length; k < columns; k++) ...[
                    const SizedBox(width: AppSpacing.md),
                    const Expanded(child: SizedBox()),
                  ],
                ],
              ),
            ),
          );
          if (i + columns < platforms.length) {
            rows.add(const SizedBox(height: AppSpacing.md));
          }
        }

        return Column(children: rows);
      },
    );
  }
}

// ── Platform card ─────────────────────────────────────────────────────────────

class _PlatformCard extends StatelessWidget {
  const _PlatformCard({required this.platform});

  final _Platform platform;

  @override
  Widget build(BuildContext context) {
    final devices = context.watch<DeviceProvider>();
    final linked = devices.linkedAccounts.contains(platform.id);
    final count = devices.importedDeviceCount(platform.id);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border(
          top: BorderSide(color: AppColors.border),
          right: BorderSide(color: AppColors.border),
          bottom: BorderSide(color: AppColors.border),
          left: BorderSide(color: platform.color, width: 3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Colored icon badge
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: platform.color.withAlpha(20),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(platform.icon, color: platform.color, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(platform.name, style: AppTextStyles.bodyStrong),
                      const SizedBox(height: 2),
                      _ProtocolTag(label: platform.protocol),
                    ],
                  ),
                ),
                if (linked)
                  _LinkedBadge(deviceCount: count),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(platform.description, style: AppTextStyles.secondary),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: linked
                  ? OutlinedButton.icon(
                      icon: const Icon(Icons.link_off, size: 16),
                      label: const Text('Bağlantıyı kes'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.muted,
                      ),
                      onPressed: () => _confirmUnlink(context, platform, devices),
                    )
                  : FilledButton.icon(
                      icon: const Icon(Icons.link, size: 16),
                      label: const Text('Bağla'),
                      onPressed: () => _startOAuth(context, platform),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startOAuth(BuildContext context, _Platform platform) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _OAuthDialog(platform: platform),
    );
  }

  Future<void> _confirmUnlink(
    BuildContext context,
    _Platform platform,
    DeviceProvider devices,
  ) async {
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

// ── Linked badge ──────────────────────────────────────────────────────────────

class _LinkedBadge extends StatelessWidget {
  const _LinkedBadge({required this.deviceCount});

  final int deviceCount;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Protocol tag ──────────────────────────────────────────────────────────────

class _ProtocolTag extends StatelessWidget {
  const _ProtocolTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 1,
      ),
      decoration: BoxDecoration(
        color: AppColors.simulator,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: AppTextStyles.secondary.copyWith(fontSize: 11),
      ),
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

class _OAuthDialogState extends State<_OAuthDialog> {
  _OAuthStep _step = _OAuthStep.connecting;

  @override
  void initState() {
    super.initState();
    // Simulate OAuth round-trip: 2.2 s to connect, then show result
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      context.read<DeviceProvider>().linkAccount(widget.platform.id);
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
              color: widget.platform.color.withAlpha(20),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              widget.platform.icon,
              color: widget.platform.color,
              size: 16,
            ),
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
              ? _ConnectingBody(platformName: widget.platform.name)
              : _DoneBody(deviceCount: count),
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

enum _OAuthStep { connecting, done }

class _ConnectingBody extends StatelessWidget {
  const _ConnectingBody({required this.platformName});

  final String platformName;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('connecting'),
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
  const _DoneBody({required this.deviceCount});

  final int deviceCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('done'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: AppColors.success,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            const Text(
              'Bağlantı kuruldu!',
              style: TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
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
