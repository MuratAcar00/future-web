import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../models/cloud_account.dart';
import '../../models/device.dart';
import '../../providers/device_provider.dart';
import 'device_visuals.dart';

/// Asks for a new name and renames the device.
Future<void> renameDevice(BuildContext context, Device device) async {
  final name = await showDialog<String>(
    context: context,
    builder: (_) => _RenameDialog(initial: device.name),
  );
  if (name != null && context.mounted) {
    context.read<DeviceProvider>().rename(device.id, name);
  }
}

/// Lets the user pick another room for the device.
Future<void> changeDeviceRoom(BuildContext context, Device device) async {
  final room = await showDialog<Room>(
    context: context,
    builder: (_) => _RoomDialog(device: device),
  );
  if (room != null && context.mounted) {
    context.read<DeviceProvider>().changeRoom(device.id, room);
  }
}

/// Confirms, then removes the device (logged on the timeline).
Future<void> confirmRemoveDevice(BuildContext context, Device device) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Cihaz kaldırılsın mı?'),
      content: Text(
        '${device.name} (${device.room.label}) listeden çıkarılır. Geçmiş '
        'olaylar zaman çizelgesinde kalır.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Kaldır'),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    context.read<DeviceProvider>().remove(device.id);
  }
}

/// Confirms, then unlinks the account and removes its imported devices.
/// Returns true when the account was unlinked.
Future<bool> confirmUnlinkAccount(
  BuildContext context,
  CloudProvider provider,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('${provider.label} bağlantısı kaldırılsın mı?'),
      content: const Text(
        'Bu hesaptan içe aktarılan cihazlar da listeden kaldırılır.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Bağlantıyı kaldır'),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    return context.read<DeviceProvider>().unlinkAccount(provider);
  }
  return false;
}

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initial});

  final String initial;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final _controller = TextEditingController(text: widget.initial);
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Cihaz için bir ad girin.');
      return;
    }
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Yeniden adlandır'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 280, maxWidth: 420),
        child: TextField(
          controller: _controller,
          autofocus: true,
          inputFormatters: [LengthLimitingTextInputFormatter(40)],
          decoration: InputDecoration(
            labelText: 'Cihaz adı',
            errorText: _error,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) => _save(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Vazgeç'),
        ),
        FilledButton(onPressed: _save, child: const Text('Kaydet')),
      ],
    );
  }
}

class _RoomDialog extends StatefulWidget {
  const _RoomDialog({required this.device});

  final Device device;

  @override
  State<_RoomDialog> createState() => _RoomDialogState();
}

class _RoomDialogState extends State<_RoomDialog> {
  late Room _room = widget.device.room;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Odayı değiştir'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.device.name),
            const SizedBox(height: AppSpacing.md),
            RoomPicker(
              selected: _room,
              onChanged: (room) => setState(() => _room = room),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_room),
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}
