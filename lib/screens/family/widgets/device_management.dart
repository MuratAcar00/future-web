import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/connected_device.dart';
import '../../../providers/device_provider.dart';
import 'family_page.dart';

const _rooms = ['Salon', 'Mutfak', 'Yatak odası', 'Giriş', 'Koridor'];
const _accounts = [
  'Google Home',
  'Amazon Alexa',
  'Bosch Smart Home',
  'SmartThings',
];

class DeviceManagementSection extends StatelessWidget {
  const DeviceManagementSection({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const FamilySectionHeader(title: 'Cihazlar'),
      FamilyCard(
        children: [
          _DeviceActionRow(
            title: 'QR Kod ile cihaz ekle',
            subtitle: 'Yerel Wi-Fi veya Bluetooth cihazını eşleştirin.',
            actionLabel: 'QR ile ekle',
            onPressed: () => showQrDeviceDialog(context),
          ),
          _DeviceActionRow(
            title: 'Cihazları tara',
            subtitle: 'Zigbee sensörleri ve akıllı TV’leri keşfedin.',
            actionLabel: 'Tara',
            onPressed: () => showDiscoveryDialog(context),
          ),
          _DeviceActionRow(
            title: 'Hesap bağla',
            subtitle: 'Google Home, Alexa, Bosch veya SmartThings hesabı.',
            actionLabel: 'Hesapları yönet',
            onPressed: () => showCloudAccountsDialog(context),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      const Text(
        'Eşleştirme ve hesap bağlantıları bu demoda simüle edilir; gerçek cihazlara veya servislere bağlanılmaz.',
        style: AppTextStyles.secondary,
      ),
    ],
  );
}

class _DeviceActionRow extends StatelessWidget {
  const _DeviceActionRow({
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.bodyStrong),
              Text(subtitle, style: AppTextStyles.secondary),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        OutlinedButton(onPressed: onPressed, child: Text(actionLabel)),
      ],
    ),
  );
}

/// The dashboard shortcut opens the same three supported pairing methods.
Future<void> showDeviceAddMenu(BuildContext context) => showDialog<void>(
  context: context,
  builder: (dialogContext) => AlertDialog(
    title: const Text('Cihaz ekle'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Eklemek istediğiniz yöntemi seçin.'),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          icon: const Icon(Icons.qr_code_2),
          label: const Text('QR Kod ile cihaz ekle'),
          onPressed: () {
            Navigator.pop(dialogContext);
            showQrDeviceDialog(context);
          },
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.radar),
          label: const Text('Cihazları tara'),
          onPressed: () {
            Navigator.pop(dialogContext);
            showDiscoveryDialog(context);
          },
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.link),
          label: const Text('Hesap bağla'),
          onPressed: () {
            Navigator.pop(dialogContext);
            showCloudAccountsDialog(context);
          },
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(dialogContext),
        child: const Text('Kapat'),
      ),
    ],
  ),
);

Future<void> showQrDeviceDialog(BuildContext context) =>
    showDialog<void>(context: context, builder: (_) => const _QrDeviceDialog());

class _QrDeviceDialog extends StatefulWidget {
  const _QrDeviceDialog();

  @override
  State<_QrDeviceDialog> createState() => _QrDeviceDialogState();
}

class _QrDeviceDialogState extends State<_QrDeviceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _name = TextEditingController();
  String _room = _rooms.first;

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  void _add() {
    if (!_formKey.currentState!.validate()) return;
    final code = _code.text.trim().toUpperCase();
    final device = ConnectedDevice(
      id: 'qr-${code.toLowerCase()}',
      name: _name.text.trim(),
      category: 'Yerel Wi-Fi / Bluetooth cihazı',
      room: _room,
      method: DeviceConnectionMethod.qrCode,
    );
    final added = context.read<DeviceProvider>().addDevice(device);
    final messenger = ScaffoldMessenger.maybeOf(context);
    Navigator.pop(context);
    _showResult(
      messenger,
      added ? '${device.name} eklendi.' : 'Bu cihaz zaten ekli.',
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('QR Kod ile cihaz ekle'),
    content: SizedBox(
      width: 420,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Yerel Wi-Fi veya Bluetooth cihazı. QR tarama bu demoda simüledir; kamera izni kullanılmaz.',
              style: AppTextStyles.secondary,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _code,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Cihaz kodu',
                hintText: 'SK-1234-ABCD',
              ),
              validator: (value) =>
                  RegExp(r'^SK-[A-Z0-9]{4}-[A-Z0-9]{4}$')
                      .hasMatch((value ?? '').trim().toUpperCase())
                  ? null
                  : 'SK-XXXX-XXXX biçiminde bir kod girin.',
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  _code.text = 'SK-2048-7319';
                  if (_name.text.trim().isEmpty) {
                    _name.text = 'Yeni yerel cihaz';
                  }
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('QR taramayı simüle et'),
              ),
            ),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Cihaz adı'),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'Cihaz adı girin.' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _room,
              decoration: const InputDecoration(labelText: 'Oda'),
              items: [
                for (final room in _rooms)
                  DropdownMenuItem(value: room, child: Text(room)),
              ],
              onChanged: (value) => setState(() => _room = value ?? _room),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Vazgeç'),
      ),
      FilledButton(onPressed: _add, child: const Text('Cihazı ekle')),
    ],
  );
}

const _discovered = [
  ConnectedDevice(
    id: 'scan-zigbee-leak',
    name: 'Zigbee su kaçağı sensörü',
    category: 'Su kaçağı sensörü',
    room: 'Mutfak',
    method: DeviceConnectionMethod.discovery,
  ),
  ConnectedDevice(
    id: 'scan-zigbee-door',
    name: 'Zigbee kapı sensörü',
    category: 'Zigbee sensörü',
    room: 'Giriş',
    method: DeviceConnectionMethod.discovery,
  ),
  ConnectedDevice(
    id: 'scan-smart-tv',
    name: 'Akıllı TV',
    category: 'Akıllı TV',
    room: 'Salon',
    method: DeviceConnectionMethod.discovery,
  ),
];

Future<void> showDiscoveryDialog(BuildContext context) => showDialog<void>(
  context: context,
  builder: (_) => const _DiscoveryDialog(),
);

class _DiscoveryDialog extends StatefulWidget {
  const _DiscoveryDialog();

  @override
  State<_DiscoveryDialog> createState() => _DiscoveryDialogState();
}

class _DiscoveryDialogState extends State<_DiscoveryDialog> {
  ConnectedDevice? _selected;
  String _room = _rooms.first;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Cihazları tara'),
    content: SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Yakındaki Zigbee sensörleri ve akıllı TV’ler simüle edilerek listelenir.',
            style: AppTextStyles.secondary,
          ),
          const SizedBox(height: AppSpacing.md),
          RadioGroup<ConnectedDevice>(
            groupValue: _selected,
            onChanged: (value) => setState(() => _selected = value),
            child: Column(
              children: [
                for (final device in _discovered)
                  RadioListTile<ConnectedDevice>(
                    contentPadding: EdgeInsets.zero,
                    value: device,
                    title: Text(device.name),
                    subtitle: Text(device.category),
                  ),
              ],
            ),
          ),
          DropdownButtonFormField<String>(
            initialValue: _room,
            decoration: const InputDecoration(labelText: 'Ekleneceği oda'),
            items: [
              for (final room in _rooms)
                DropdownMenuItem(value: room, child: Text(room)),
            ],
            onChanged: (value) => setState(() => _room = value ?? _room),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Kapat'),
      ),
      FilledButton(
        onPressed: _selected == null
            ? null
            : () {
                final selected = _selected!;
                final device = ConnectedDevice(
                  id: selected.id,
                  name: selected.name,
                  category: selected.category,
                  room: _room,
                  method: selected.method,
                );
                final added = context.read<DeviceProvider>().addDevice(device);
                final messenger = ScaffoldMessenger.maybeOf(context);
                Navigator.pop(context);
                _showResult(
                  messenger,
                  added ? '${device.name} eklendi.' : 'Bu cihaz zaten ekli.',
                );
              },
        child: const Text('Seçili cihazı ekle'),
      ),
    ],
  );
}

Future<void> showCloudAccountsDialog(BuildContext context) => showDialog<void>(
  context: context,
  builder: (_) => const _CloudAccountsDialog(),
);

class _CloudAccountsDialog extends StatelessWidget {
  const _CloudAccountsDialog();

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Hesap bağla'),
    content: SizedBox(
      width: 440,
      child: Consumer<DeviceProvider>(
        builder: (context, devices, _) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Hesap izni ve içe aktarma bu demoda simüledir. Gerçek hesap bilgisi istenmez.',
              style: AppTextStyles.secondary,
            ),
            const SizedBox(height: AppSpacing.md),
            for (final account in _accounts)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(account),
                subtitle: Text(
                  devices.linkedAccounts.contains(account)
                      ? 'Bağlı · simülasyon'
                      : 'Bağlı değil',
                  style: AppTextStyles.secondary,
                ),
                trailing: TextButton(
                  onPressed: () async {
                    if (devices.linkedAccounts.contains(account)) {
                      devices.unlinkAccount(account);
                      return;
                    }
                    final approved = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: Text('$account hesabını bağla'),
                        content: Text(
                          '$account bağlantısı ve örnek cihazların içe aktarılması simüle edilecek. Gerçek hesaba erişilmeyecek.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, false),
                            child: const Text('Vazgeç'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(dialogContext, true),
                            child: const Text('Simüle ederek bağla'),
                          ),
                        ],
                      ),
                    );
                    if (approved == true && context.mounted) {
                      context.read<DeviceProvider>().linkAccount(account);
                    }
                  },
                  child: Text(
                    devices.linkedAccounts.contains(account)
                        ? 'Bağlantıyı kes'
                        : 'Bağla',
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Kapat'),
      ),
    ],
  );
}

void _showResult(ScaffoldMessengerState? messenger, String message) {
  messenger?.showSnackBar(SnackBar(content: Text(message)));
}

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
