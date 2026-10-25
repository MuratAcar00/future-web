import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/tag_chip.dart';
import '../../models/device.dart';
import '../../providers/device_provider.dart';
import '../../services/device_pairing_service.dart';
import 'device_visuals.dart';

enum _QrStep { scan, recognized, room, name, added }

const _qrStepLabels = [
  'Kodu okut',
  'Cihaz tanındı',
  'Odaya ata',
  'Ad ver',
  'Eklendi',
];

/// QR / setup-code pairing. The camera is never used: "Demo QR okut"
/// resolves a sample device and the manual code is validated locally.
class QrFlow extends StatefulWidget {
  const QrFlow({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<QrFlow> createState() => _QrFlowState();
}

class _QrFlowState extends State<QrFlow> {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();

  _QrStep _step = _QrStep.scan;
  String? _busyText;
  String? _codeError;
  String? _nameError;
  String? _code;
  DeviceCandidate? _candidate;
  Room? _room;
  Device? _added;

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _resolve(
    String busyText,
    Future<DeviceCandidate> Function() lookup,
    String code,
  ) async {
    setState(() {
      _busyText = busyText;
      _codeError = null;
    });
    final candidate = await lookup();
    if (!mounted) return;
    setState(() {
      _busyText = null;
      _code = code;
      _candidate = candidate;
      _room = candidate.room;
      _nameController.text = candidate.name;
      _step = _QrStep.recognized;
    });
  }

  void _scanDemo() => _resolve(
    'Demo QR okunuyor…',
    context.read<DeviceProvider>().scanDemoQr,
    DevicePairingService.demoQrCode,
  );

  void _submitCode() {
    final raw = _codeController.text;
    final error = DevicePairingService.validateSetupCode(raw);
    if (error != null) {
      setState(() => _codeError = error);
      return;
    }
    final code = DevicePairingService.normalizeCode(raw);
    _resolve(
      'Kurulum kodu doğrulanıyor…',
      () => context.read<DeviceProvider>().lookupSetupCode(code),
      code,
    );
  }

  void _add() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Cihaz için bir ad girin.');
      return;
    }
    final added = context.read<DeviceProvider>().addDevice(
      _candidate!,
      source: DeviceSource.qr,
      room: _room,
      name: name,
    );
    setState(() {
      _nameError = null;
      _added = added;
      _step = _QrStep.added;
    });
  }

  void _restart() {
    _codeController.clear();
    setState(() {
      _step = _QrStep.scan;
      _candidate = null;
      _added = null;
      _code = null;
      _codeError = null;
      _nameError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FlowStepIndicator(current: _step.index, labels: _qrStepLabels),
        const SizedBox(height: AppSpacing.xl),
        switch (_step) {
          _QrStep.scan => _buildScan(),
          _QrStep.recognized => _buildRecognized(),
          _QrStep.room => _buildRoom(),
          _QrStep.name => _buildName(),
          _QrStep.added => _buildAdded(),
        },
      ],
    );
  }

  Widget _buildScan() {
    final busy = _busyText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: _ScanFrame()),
        const SizedBox(height: AppSpacing.md),
        const Text(
          'Kamera açılmaz. Bu ekran QR kod okutmayı simüle eder.',
          textAlign: TextAlign.center,
          style: AppTextStyles.secondary,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (busy != null)
          BusyLine(text: busy)
        else ...[
          FilledButton.icon(
            onPressed: _scanDemo,
            icon: const Icon(Icons.qr_code_scanner, size: 18),
            label: const Text('Demo QR okut'),
          ),
          const SizedBox(height: AppSpacing.xl),
          const Row(
            children: [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text('veya', style: AppTextStyles.secondary),
              ),
              Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9-]')),
              LengthLimitingTextInputFormatter(12),
              _UpperCaseFormatter(),
            ],
            decoration: InputDecoration(
              labelText: 'Kurulum kodunu gir',
              hintText: 'SK-XXXX-XXXX',
              helperText: 'Cihazın üzerindeki 12 karakterli kod.',
              errorText: _codeError,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submitCode(),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            onPressed: _submitCode,
            child: const Text('Kodu doğrula'),
          ),
        ],
      ],
    );
  }

  Widget _buildRecognized() {
    final candidate = _candidate!;
    final duplicate = context.select<DeviceProvider, bool>(
      (p) => p.isAdded(candidate.id),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CheckLine(text: 'Kod okundu: $_code'),
        const CheckLine(text: 'Cihaz tanındı'),
        const SizedBox(height: AppSpacing.md),
        _CandidateCard(candidate: candidate),
        if (duplicate) ...[
          const SizedBox(height: AppSpacing.md),
          const DemoNote(
            text: 'Bu cihaz zaten ekli. Aynı cihaz ikinci kez eklenmez.',
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        FlowButtons(
          backLabel: 'Başka kod',
          onBack: _restart,
          nextLabel: 'Devam',
          onNext: duplicate ? null : () => setState(() => _step = _QrStep.room),
        ),
      ],
    );
  }

  Widget _buildRoom() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${_candidate!.name} hangi odada?',
          style: AppTextStyles.bodyStrong,
        ),
        const SizedBox(height: AppSpacing.md),
        RoomPicker(
          selected: _room,
          onChanged: (room) => setState(() => _room = room),
        ),
        const SizedBox(height: AppSpacing.xl),
        FlowButtons(
          onBack: () => setState(() => _step = _QrStep.recognized),
          nextLabel: 'Devam',
          onNext: _room == null
              ? null
              : () => setState(() => _step = _QrStep.name),
        ),
      ],
    );
  }

  Widget _buildName() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _nameController,
          autofocus: true,
          inputFormatters: [LengthLimitingTextInputFormatter(40)],
          decoration: InputDecoration(
            labelText: 'Cihaz adı',
            helperText: 'Örneğin: ${_room!.label} ${_candidate!.kind.label}',
            errorText: _nameError,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) => _add(),
        ),
        const SizedBox(height: AppSpacing.xl),
        FlowButtons(
          onBack: () => setState(() => _step = _QrStep.room),
          nextLabel: 'Cihazı ekle',
          onNext: _add,
        ),
      ],
    );
  }

  Widget _buildAdded() {
    final added = _added;
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
                  added == null
                      ? 'Bu cihaz zaten ekliydi.'
                      : 'Eklendi: ${added.name}',
                  style: AppTextStyles.bodyStrong,
                ),
              ),
            ],
          ),
        ),
        if (added != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${added.room.label} · ${added.protocol.label}. Sensörler '
            'listesinde ve zaman çizelgesinde görünür.',
            style: AppTextStyles.secondary,
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        FlowButtons(
          backLabel: 'Başka cihaz ekle',
          onBack: _restart,
          nextLabel: 'Bitti',
          onNext: widget.onDone,
        ),
      ],
    );
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({required this.candidate});

  final DeviceCandidate candidate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: DeviceSummaryRow(
        icon: candidate.kind.icon,
        title: candidate.name,
        subtitle: candidate.kind.label,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TagChip(label: candidate.protocol.label),
            const SizedBox(width: AppSpacing.sm),
            SignalBars(signal: candidate.signal),
          ],
        ),
      ),
    );
  }
}

/// Square viewfinder with corner brackets. Purely decorative.
class _ScanFrame extends StatelessWidget {
  const _ScanFrame();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: 168,
        child: CustomPaint(
          painter: _CornerPainter(),
          child: const Center(
            child: Icon(Icons.qr_code_2, size: 72, color: AppColors.icon),
          ),
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const arm = 28.0;
    final w = size.width;
    final h = size.height;
    final corners = [
      const [Offset(0, arm), Offset.zero, Offset(arm, 0)],
      [Offset(w - arm, 0), Offset(w, 0), Offset(w, arm)],
      [Offset(w, h - arm), Offset(w, h), Offset(w - arm, h)],
      [Offset(arm, h), Offset(0, h), Offset(0, h - arm)],
    ];
    for (final c in corners) {
      canvas.drawPath(
        Path()
          ..moveTo(c[0].dx, c[0].dy)
          ..lineTo(c[1].dx, c[1].dy)
          ..lineTo(c[2].dx, c[2].dy),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}
