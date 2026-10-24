import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/demo_provider.dart';

/// Asks for confirmation, then resets every demo provider.
Future<void> confirmAndResetDemo(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Demo sıfırlansın mı?'),
      content: const Text(
        'Simüle edilen olaylar, demo saati ve uyarı durumu başlangıç haline '
        'döner. Mod seçiminiz korunur.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Sıfırla'),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    context.read<DemoProvider>().reset();
  }
}
