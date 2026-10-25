import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/app_mode.dart';
import '../../../models/connected_device.dart';
import '../../../providers/app_mode_provider.dart';
import '../../../providers/device_provider.dart';
import 'family_page.dart';

// ── Room list ────────────────────────────────────────────────────────────────

const _rooms = ['Salon', 'Mutfak', 'Yatak odası', 'Giriş', 'Koridor', 'Banyo'];

// ── Simulated devices found during discovery ─────────────────────────────────

const _discovered = [
  ConnectedDevice(
    id: 'scan-zigbee-motion',
    name: 'Zigbee hareket sensörü',
    category: 'Zigbee sensörü',
    room: 'Giriş',
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
  ConnectedDevice(
    id: 'scan-zigbee-plug',
    name: 'Zigbee akıllı priz',
    category: 'Zigbee priz',
    room: 'Mutfak',
    method: DeviceConnectionMethod.discovery,
  ),
];

// ── Entry point: method selection sheet ──────────────────────────────────────

Future<void> showDeviceAddMenu(BuildContext context) => showDialog<void>(
  context: context,
  builder: (ctx) => _DeviceAddMenuDialog(rootContext: context),
);

class _DeviceAddMenuDialog extends StatelessWidget {
  const _DeviceAddMenuDialog({required this.rootContext});

  final BuildContext rootContext;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cihaz ekle'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Edge Hub'a yeni bir cihaz eklemek için yöntem seçin.',
              style: AppTextStyles.secondary,
            ),
            const SizedBox(height: AppSpacing.lg),
            _MethodCard(
              icon: Icons.qr_code_2,
              title: 'QR Kod ile eşleştir',
              subtitle: 'Cihazın üzerindeki QR kodu okut — Wi-Fi veya Bluetooth.',
              onTap: () {
                Navigator.pop(context);
                showQrDeviceDialog(rootContext);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _MethodCard(
              icon: Icons.radar,
              title: 'Otomatik tara',
              subtitle: 'Yakındaki Zigbee sensörleri ve akıllı TV'leri keşfet.',
              onTap: () {
                Navigator.pop(context);
                showDiscoveryDialog(rootContext);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _MethodCard(
              icon: Icons.hub_outlined,
              title: 'Ekosistem bağla',
              subtitle: 'Alexa, Google Home, Bosch, Somfy ve daha fazlası.',
              onTap: () {
                Navigator.pop(context);
                rootContext
                    .read<AppModeProvider>()
                    .selectSection(FamilySection.ecosystems);
              },
            ),
          ],
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
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyStrong),
                  Text(subtitle, style: AppTextStyles.secondary),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.icon),
          ],
        ),
      ),
    );
  }
}

// ── QR flow ───────────────────────────────────────────────────────────────────

Future<void> showQrDeviceDialog(BuildContext context) => showDialog<void>(
  context: context,
  builder: (_) => const _QrDeviceDialog(),
);

enum _QrStep { scan, confirm, done }

class _QrDeviceDialog extends StatefulWidget {
  const _QrDeviceDialog();

  @override
  State<_QrDeviceDialog> createState() => _QrDeviceDialogState();
}

class _QrDeviceDialogState extends State<_QrDeviceDialog> {
  _QrStep _step = _QrStep.scan;
  bool _scanning = false;

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController(text: '');
  String _room = _rooms.first;
  ConnectedDevice? _result;

  // Pre-set scan result (simulated)
  static const _scannedCode = 'SK-2048-7319';
  static const _scannedName = 'Mutfak akıllı prizi';
  static const _scannedCategory = 'Yerel Wi-Fi cihazı';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _simulateScan() async {
    setState(() => _scanning = true);
    await Future<void>.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    _name.text = _scannedName;
    setState(() {
      _scanning = false;
      _step = _QrStep.confirm;
    });
  }

  void _add() {
    if (!_formKey.currentState!.validate()) return;
    final device = ConnectedDevice(
      id: 'qr-${_scannedCode.toLowerCase()}',
      name: _name.text.trim(),
      category: _scannedCategory,
      room: _room,
      method: DeviceConnectionMethod.qrCode,
    );
    final added = context.read<DeviceProvider>().addDevice(device);
    setState(() {
      _result = added ? device : null;
      _step = _QrStep.done;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.qr_code_2, color: AppColors.primary, size: 20),
          const SizedBox(width: AppSpacing.sm),
          const Text('QR Kod ile eşleştir'),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: switch (_step) {
            _QrStep.scan => _QrScanBody(
              key: const ValueKey('scan'),
              scanning: _scanning,
              onSimulate: _simulateScan,
            ),
            _QrStep.confirm => _QrConfirmBody(
              key: const ValueKey('confirm'),
              formKey: _formKey,
              nameController: _name,
              code: _scannedCode,
              category: _scannedCategory,
              room: _room,
              onRoomChanged: (v) => setState(() => _room = v ?? _room),
            ),
            _QrStep.done => _QrDoneBody(
              key: const ValueKey('done'),
              device: _result,
            ),
          },
        ),
      ),
      actions: switch (_step) {
        _QrStep.scan => [
          TextButton(
            onPressed: _scanning ? null : () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
        _QrStep.confirm => [
          TextButton(
            onPressed: () => setState(() => _step = _QrStep.scan),
            child: const Text('Geri'),
          ),
          FilledButton(
            onPressed: _add,
            child: const Text('Cihazı ekle'),
          ),
        ],
        _QrStep.done => [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      },
    );
  }
}

class _QrScanBody extends StatelessWidget {
  const _QrScanBody({super.key, required this.scanning, required this.onSimulate});

  final bool scanning;
  final VoidCallback onSimulate;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: AppSpacing.sm),
        // Fake camera frame
        Container(
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Corner brackets
              ..._corners(),
              if (scanning) ...[
                const CircularProgressIndicator(color: AppColors.primaryOnDark),
                const SizedBox(),
              ] else
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.qr_code_scanner, color: AppColors.primaryOnDark, size: 36),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'Kamerayı QR koda doğrultu',
                      style: TextStyle(color: AppColors.deviceMuted, fontSize: 13),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (scanning)
          const Text('QR kod okunuyor…', style: AppTextStyles.secondary)
        else ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.qr_code_scanner, size: 18),
              label: const Text('QR taramayı simüle et'),
              onPressed: onSimulate,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Bu demoda kamera izni kullanılmaz; tarama simüle edilir.',
            style: AppTextStyles.secondary,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  static List<Widget> _corners() {
    const size = 22.0;
    const thickness = 2.5;
    const color = AppColors.primaryOnDark;
    const r = AppRadius.sm;

    Widget corner(AlignmentGeometry alignment, BorderRadius borderRadius) =>
        Positioned(
          top: alignment == Alignment.topLeft || alignment == Alignment.topRight ? 18 : null,
          bottom: alignment == Alignment.bottomLeft || alignment == Alignment.bottomRight ? 18 : null,
          left: alignment == Alignment.topLeft || alignment == Alignment.bottomLeft ? 24 : null,
          right: alignment == Alignment.topRight || alignment == Alignment.bottomRight ? 24 : null,
          child: SizedBox(
            width: size,
            height: size,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  top: alignment == Alignment.topLeft || alignment == Alignment.topRight
                      ? const BorderSide(color: color, width: thickness)
                      : BorderSide.none,
                  bottom: alignment == Alignment.bottomLeft || alignment == Alignment.bottomRight
                      ? const BorderSide(color: color, width: thickness)
                      : BorderSide.none,
                  left: alignment == Alignment.topLeft || alignment == Alignment.bottomLeft
                      ? const BorderSide(color: color, width: thickness)
                      : BorderSide.none,
                  right: alignment == Alignment.topRight || alignment == Alignment.bottomRight
                      ? const BorderSide(color: color, width: thickness)
                      : BorderSide.none,
                ),
                borderRadius: borderRadius,
              ),
            ),
          ),
        );

    return [
      corner(Alignment.topLeft, const BorderRadius.only(topLeft: Radius.circular(r))),
      corner(Alignment.topRight, const BorderRadius.only(topRight: Radius.circular(r))),
      corner(Alignment.bottomLeft, const BorderRadius.only(bottomLeft: Radius.circular(r))),
      corner(Alignment.bottomRight, const BorderRadius.only(bottomRight: Radius.circular(r))),
    ];
  }
}

class _QrConfirmBody extends StatelessWidget {
  const _QrConfirmBody({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.code,
    required this.category,
    required this.room,
    required this.onRoomChanged,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final String code;
  final String category;
  final String room;
  final ValueChanged<String?> onRoomChanged;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Found device banner
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.successSurface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.successBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: AppColors.success, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cihaz bulundu!',
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Kod: $code · $category',
                        style: AppTextStyles.secondary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Cihaz adı'),
            validator: (v) => (v ?? '').trim().isEmpty ? 'Cihaz adı girin.' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            value: room,
            decoration: const InputDecoration(labelText: 'Oda / Grup'),
            items: [
              for (final r in _rooms)
                DropdownMenuItem(value: r, child: Text(r)),
            ],
            onChanged: onRoomChanged,
          ),
        ],
      ),
    );
  }
}

class _QrDoneBody extends StatelessWidget {
  const _QrDoneBody({super.key, required this.device});

  final ConnectedDevice? device;

  @override
  Widget build(BuildContext context) {
    if (device == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Text('Bu cihaz zaten ekli.'),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 48),
          const SizedBox(height: AppSpacing.md),
          Text(
            '${device!.name} eklendi!',
            style: AppTextStyles.section,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${device!.room} grubuna atandı. Cihaz verileri Edge Hub üzerinden akıyor.',
            style: AppTextStyles.secondary,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Discovery flow ─────────────────────────────────────────────────────────────

Future<void> showDiscoveryDialog(BuildContext context) => showDialog<void>(
  context: context,
  builder: (_) => const _DiscoveryDialog(),
);

enum _DiscoveryStep { scanning, select, done }

class _DiscoveryDialog extends StatefulWidget {
  const _DiscoveryDialog();

  @override
  State<_DiscoveryDialog> createState() => _DiscoveryDialogState();
}

class _DiscoveryDialogState extends State<_DiscoveryDialog> {
  _DiscoveryStep _step = _DiscoveryStep.scanning;
  final List<ConnectedDevice> _found = [];
  ConnectedDevice? _selected;
  String _room = _rooms.first;
  ConnectedDevice? _result;
  Timer? _timer;
  int _scanProgress = 0;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startScan() {
    // Reveal devices one by one with 600ms gaps, then switch to select step
    _timer = Timer.periodic(const Duration(milliseconds: 600), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _scanProgress++);

      if (_scanProgress <= _discovered.length) {
        setState(() => _found.add(_discovered[_scanProgress - 1]));
      }

      if (_scanProgress >= _discovered.length + 1) {
        t.cancel();
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) setState(() => _step = _DiscoveryStep.select);
        });
      }
    });
  }

  void _add() {
    final selected = _selected;
    if (selected == null) return;
    final device = ConnectedDevice(
      id: selected.id,
      name: selected.name,
      category: selected.category,
      room: _room,
      method: selected.method,
    );
    final added = context.read<DeviceProvider>().addDevice(device);
    setState(() {
      _result = added ? device : null;
      _step = _DiscoveryStep.done;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.radar, color: AppColors.primary, size: 20),
          const SizedBox(width: AppSpacing.sm),
          const Text('Otomatik tara'),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: switch (_step) {
            _DiscoveryStep.scanning => _ScanningBody(
              key: const ValueKey('scanning'),
              found: _found,
            ),
            _DiscoveryStep.select => _SelectBody(
              key: const ValueKey('select'),
              found: _found,
              selected: _selected,
              room: _room,
              onSelected: (v) => setState(() => _selected = v),
              onRoomChanged: (v) => setState(() => _room = v ?? _room),
            ),
            _DiscoveryStep.done => _DiscoveryDoneBody(
              key: const ValueKey('done'),
              device: _result,
            ),
          },
        ),
      ),
      actions: switch (_step) {
        _DiscoveryStep.scanning => [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
        ],
        _DiscoveryStep.select => [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
          FilledButton(
            onPressed: _selected == null ? null : _add,
            child: const Text('Seçili cihazı ekle'),
          ),
        ],
        _DiscoveryStep.done => [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      },
    );
  }
}

class _ScanningBody extends StatelessWidget {
  const _ScanningBody({super.key, required this.found});

  final List<ConnectedDevice> found;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: AppSpacing.md),
            const Text('Yakın cihazlar taranıyor…', style: AppTextStyles.secondary),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        // Devices appearing one by one
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          alignment: Alignment.topCenter,
          child: Column(
            children: [
              for (final device in found)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _FoundDeviceTile(device: device, selected: false, onTap: null),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Zigbee, Wi-Fi ve Matter cihazlar için yerel ağ taranır.',
          style: AppTextStyles.secondary,
        ),
      ],
    );
  }
}

class _SelectBody extends StatelessWidget {
  const _SelectBody({
    super.key,
    required this.found,
    required this.selected,
    required this.room,
    required this.onSelected,
    required this.onRoomChanged,
  });

  final List<ConnectedDevice> found;
  final ConnectedDevice? selected;
  final String room;
  final ValueChanged<ConnectedDevice?> onSelected;
  final ValueChanged<String?> onRoomChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${found.length} cihaz bulundu. Eklemek istediğinizi seçin.',
          style: AppTextStyles.secondary,
        ),
        const SizedBox(height: AppSpacing.md),
        for (final device in found)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _FoundDeviceTile(
              device: device,
              selected: selected == device,
              onTap: () => onSelected(device),
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String>(
          value: room,
          decoration: const InputDecoration(labelText: 'Oda / Grup'),
          items: [
            for (final r in _rooms)
              DropdownMenuItem(value: r, child: Text(r)),
          ],
          onChanged: onRoomChanged,
        ),
      ],
    );
  }
}

class _FoundDeviceTile extends StatelessWidget {
  const _FoundDeviceTile({
    required this.device,
    required this.selected,
    required this.onTap,
  });

  final ConnectedDevice device;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySurface : AppColors.simulator,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? AppColors.primaryBorder : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.sensors_outlined,
              size: 18,
              color: selected ? AppColors.primary : AppColors.muted,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(device.name, style: AppTextStyles.bodyStrong),
                  Text(device.category, style: AppTextStyles.secondary),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
          ],
        ),
      ),
    );
  }
}

class _DiscoveryDoneBody extends StatelessWidget {
  const _DiscoveryDoneBody({super.key, required this.device});

  final ConnectedDevice? device;

  @override
  Widget build(BuildContext context) {
    if (device == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Text('Bu cihaz zaten ekli.'),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 48),
          const SizedBox(height: AppSpacing.md),
          Text(
            '${device!.name} eklendi!',
            style: AppTextStyles.section,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${device!.room} grubuna atandı. Edge Hub üzerinden veri akışı başladı.',
            style: AppTextStyles.secondary,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Settings: device management section ──────────────────────────────────────

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
            subtitle: 'Zigbee sensörleri ve akıllı TV'leri keşfedin.',
            actionLabel: 'Tara',
            onPressed: () => showDiscoveryDialog(context),
          ),
          _DeviceActionRow(
            title: 'Ekosistem bağla',
            subtitle: 'Alexa, Google Home, Bosch, Somfy ve daha fazlası.',
            actionLabel: 'Ekosistemler',
            onPressed: () => context
                .read<AppModeProvider>()
                .selectSection(FamilySection.ecosystems),
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

// ── Connected device row (used in settings device list) ──────────────────────

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

