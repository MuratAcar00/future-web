import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_time_format.dart';
import '../../../core/widgets/reset_demo_dialog.dart';
import '../../../core/widgets/tag_chip.dart';
import '../../../models/app_mode.dart';
import '../../../models/cloud_account.dart';
import '../../../models/device.dart';
import '../../../models/sensor_type.dart';
import '../../../providers/app_mode_provider.dart';
import '../../../providers/device_provider.dart';
import '../../../providers/routine_provider.dart';
import '../../devices/add_device_sheet.dart';
import '../../devices/device_actions.dart';
import '../../devices/device_visuals.dart';
import '../widgets/family_page.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final modeProvider = context.read<AppModeProvider>();
    final reduceMotion = context.select<AppModeProvider, bool>(
      (p) => p.reduceMotion,
    );
    final systemReduceMotion = MediaQuery.disableAnimationsOf(context);
    final showDemoPanel = context.select<AppModeProvider, bool>(
      (p) => p.showDemoPanel,
    );
    final engine = context.read<RoutineProvider>().engine;

    return FamilyPage(
      children: [
        const FamilyPageTitle(
          title: 'Ayarlar',
          subtitle: 'Görünüm, kullanım modu ve demo tercihleri.',
        ),
        const SizedBox(height: AppSpacing.xxl),
        const _DevicesSection(),
        const SizedBox(height: AppSpacing.xxl),
        const FamilySectionHeader(title: 'Görünüm'),
        FamilyCard(
          children: [
            _SwitchRow(
              title: 'Hareketi azalt',
              subtitle: systemReduceMotion
                  ? 'Sistem ayarınız nedeniyle animasyonlar zaten kapalı.'
                  : 'Geçiş ve nabız animasyonlarını kapatır.',
              value: reduceMotion || systemReduceMotion,
              onChanged: systemReduceMotion
                  ? null
                  : modeProvider.setReduceMotion,
            ),
            _SwitchRow(
              title: 'Demo panelini göster',
              subtitle: 'Senaryo kontrollerini aile panelinde gösterir.',
              value: showDemoPanel,
              onChanged: modeProvider.setShowDemoPanel,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        const FamilySectionHeader(title: 'Kullanım modu'),
        FamilyCard(
          children: [
            _ActionRow(
              title: 'Cihaz modunu aç',
              subtitle: 'Yaşam alanı ekranını bu tarayıcıda gösterir.',
              actionLabel: 'Aç',
              onPressed: () => modeProvider.selectMode(AppMode.device),
            ),
            _ActionRow(
              title: AppStrings.backToModeSelection,
              subtitle: 'Bu sistemi kimin kullanacağını yeniden seçin.',
              actionLabel: 'Seç',
              onPressed: modeProvider.returnToModeSelection,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        const FamilySectionHeader(title: 'Rutin kuralları'),
        FamilyCard(
          children: [
            _InfoRow(
              title: 'Sabah hareket penceresi',
              value:
                  '${TurkishDateFormat.timeOfDay(engine.windowStart)} – '
                  '${TurkishDateFormat.timeOfDay(engine.delayAfter)}',
            ),
            _InfoRow(
              title: 'Gecikme uyarısı',
              value: TurkishDateFormat.timeOfDay(engine.delayAfter),
            ),
            _InfoRow(
              title: 'Cihazdan onay isteği',
              value: TurkishDateFormat.timeOfDay(engine.confirmationAfter),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        const FamilySectionHeader(title: 'Demo verileri'),
        FamilyCard(
          children: [
            _ActionRow(
              title: AppStrings.resetDemo,
              subtitle:
                  'Olayları, demo saatini, uyarı durumunu, eklenen cihazları '
                  've bağlı hesapları sıfırlar.',
              actionLabel: 'Sıfırla',
              onPressed: () => confirmAndResetDemo(context),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        const Text(
          '${AppStrings.demoDisclaimer} Sayfa yenilendiğinde yalnızca mod '
          'seçimi hatırlanır.',
          style: AppTextStyles.secondary,
        ),
      ],
    );
  }
}

/// "Cihazlar": built-in sensors, added devices and linked accounts.
class _DevicesSection extends StatelessWidget {
  const _DevicesSection();

  @override
  Widget build(BuildContext context) {
    final devices = context.select<DeviceProvider, List<Device>>(
      (p) => p.devices,
    );
    final accounts = context.select<DeviceProvider, List<CloudAccount>>(
      (p) => p.accounts,
    );
    final count = SensorType.values.length + devices.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FamilySectionHeader(title: 'Cihazlar', caption: '$count simüle cihaz'),
        FamilyCard(
          children: [
            _ActionRow(
              title: 'Yeni cihaz ekle',
              subtitle:
                  'QR kod, cihaz taraması veya hesap bağlama. $demoConnectionNote',
              actionLabel: 'Cihaz Ekle',
              onPressed: () => showAddDeviceSheet(context),
            ),
            for (final type in SensorType.values) _BuiltInSensorRow(type: type),
            for (final device in devices) _ManagedDeviceRow(device: device),
          ],
        ),
        if (accounts.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          const FamilySectionHeader(title: 'Bağlı hesaplar'),
          FamilyCard(
            children: [
              for (final account in accounts) _AccountRow(account: account),
            ],
          ),
        ],
      ],
    );
  }
}

class _BuiltInSensorRow extends StatelessWidget {
  const _BuiltInSensorRow({required this.type});

  final SensorType type;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Padding(
        padding: _rowPadding,
        child: Row(
          children: [
            Expanded(
              child: _TitleBlock(
                title: type.name,
                subtitle: '${type.location} · Varsayılan kurulum',
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            const TagChip(label: 'VARSAYILAN', background: AppColors.simulator),
          ],
        ),
      ),
    );
  }
}

enum _DeviceMenuAction { rename, room, remove }

class _ManagedDeviceRow extends StatelessWidget {
  const _ManagedDeviceRow({required this.device});

  final Device device;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: _rowPadding,
      child: Row(
        children: [
          Expanded(
            child: MergeSemantics(
              child: _TitleBlock(
                title: device.name,
                subtitle:
                    '${device.room.label} · ${device.protocol.label} · '
                    '${device.sourceLabel}',
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          PopupMenuButton<_DeviceMenuAction>(
            tooltip: '${device.name} seçenekleri',
            icon: const Icon(Icons.more_horiz),
            elevation: 0,
            color: AppColors.background,
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            onSelected: (action) => switch (action) {
              _DeviceMenuAction.rename => renameDevice(context, device),
              _DeviceMenuAction.room => changeDeviceRoom(context, device),
              _DeviceMenuAction.remove => confirmRemoveDevice(context, device),
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _DeviceMenuAction.rename,
                child: Text('Yeniden adlandır'),
              ),
              PopupMenuItem(
                value: _DeviceMenuAction.room,
                child: Text('Odayı değiştir'),
              ),
              PopupMenuItem(
                value: _DeviceMenuAction.remove,
                child: Text('Kaldır'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.account});

  final CloudAccount account;

  @override
  Widget build(BuildContext context) {
    final provider = account.provider;
    return Padding(
      padding: _rowPadding,
      child: Row(
        children: [
          Expanded(
            child: _TitleBlock(
              title: provider.label,
              subtitle:
                  'Bağlı · ${account.deviceIds.length} cihaz · simülasyon',
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          OutlinedButton(
            onPressed: () => confirmUnlinkAccount(context, provider),
            child: Text(
              'Bağlantıyı kaldır',
              semanticsLabel: 'Bağlantıyı kaldır: ${provider.label}',
            ),
          ),
        ],
      ),
    );
  }
}

const _rowPadding = EdgeInsets.symmetric(
  horizontal: AppSpacing.lg,
  vertical: AppSpacing.md,
);

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    // The whole row toggles the switch; the switch itself keeps keyboard focus.
    return MergeSemantics(
      child: InkWell(
        canRequestFocus: false,
        onTap: onChanged == null ? null : () => onChanged(!value),
        child: Padding(
          padding: _rowPadding,
          child: Row(
            children: [
              Expanded(
                child: _TitleBlock(title: title, subtitle: subtitle),
              ),
              const SizedBox(width: AppSpacing.md),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: _rowPadding,
      child: Row(
        children: [
          Expanded(
            child: _TitleBlock(title: title, subtitle: subtitle),
          ),
          const SizedBox(width: AppSpacing.md),
          OutlinedButton(
            onPressed: onPressed,
            child: Text(actionLabel, semanticsLabel: '$actionLabel: $title'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Padding(
        padding: _rowPadding,
        child: Row(
          children: [
            Expanded(child: Text(title, style: AppTextStyles.body)),
            const SizedBox(width: AppSpacing.md),
            Text(value, style: AppTextStyles.bodyStrong),
          ],
        ),
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
        ),
        Text(subtitle, style: AppTextStyles.secondary),
      ],
    );
  }
}
