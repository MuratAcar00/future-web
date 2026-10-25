import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/motion.dart';
import '../../core/widgets/hover_surface.dart';
import '../../core/widgets/tag_chip.dart';
import '../../models/device.dart';
import '../../providers/device_provider.dart';
import 'device_visuals.dart';

enum _ScanStep { results, assign, added }

/// Simulated Zigbee / Wi-Fi discovery: devices appear one by one, the user
/// selects some, assigns rooms and adds them.
class ScanFlow extends StatefulWidget {
  const ScanFlow({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<ScanFlow> createState() => _ScanFlowState();
}

class _ScanFlowState extends State<ScanFlow> {
  late final DeviceProvider _devices;
  _ScanStep _step = _ScanStep.results;
  final Set<String> _selected = {};
  final Map<String, Room> _rooms = {};
  List<Device> _added = const [];

  @override
  void initState() {
    super.initState();
    _devices = context.read<DeviceProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _devices.startDiscovery();
    });
  }

  @override
  void dispose() {
    _devices.clearDiscovery(notify: false);
    super.dispose();
  }

  void _rescan() {
    setState(() {
      _selected.clear();
      _rooms.clear();
      _step = _ScanStep.results;
    });
    _devices.startDiscovery();
  }

  void _toggle(DeviceCandidate candidate) => setState(() {
    if (!_selected.remove(candidate.id)) {
      _selected.add(candidate.id);
      _rooms.putIfAbsent(candidate.id, () => candidate.room);
    }
  });

  List<DeviceCandidate> get _selectedCandidates => [
    for (final c in _devices.discovered)
      if (_selected.contains(c.id)) c,
  ];

  void _add() {
    final added = _devices.addDevices(
      _selectedCandidates,
      source: DeviceSource.scan,
      rooms: _rooms,
    );
    setState(() {
      _added = added;
      _step = _ScanStep.added;
    });
  }

  @override
  Widget build(BuildContext context) {
    return switch (_step) {
      _ScanStep.results => _buildResults(context),
      _ScanStep.assign => _buildAssign(),
      _ScanStep.added => _buildAdded(),
    };
  }

  Widget _buildResults(BuildContext context) {
    final status = context.select<DeviceProvider, DiscoveryStatus>(
      (p) => p.discoveryStatus,
    );
    final found = context.select<DeviceProvider, List<DeviceCandidate>>(
      (p) => p.discovered,
    );
    final scanning = status != DiscoveryStatus.done;

    if (!scanning && found.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.lg),
          const Icon(Icons.search_off, size: 40, color: AppColors.icon),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            liveRegion: true,
            child: const Text(
              'Yeni cihaz bulunamadı',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyStrong,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Yakındaki demo cihazlarının tümü zaten ekli. Tekrar tarayabilir '
            'veya diğer yöntemleri deneyebilirsiniz.',
            textAlign: TextAlign.center,
            style: AppTextStyles.secondary,
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: OutlinedButton.icon(
              onPressed: _rescan,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Tekrar tara'),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (scanning)
          const BusyLine(text: 'Taranıyor… Zigbee ve Wi-Fi cihazları aranıyor.')
        else
          Row(
            children: [
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    '${found.length} cihaz bulundu',
                    style: AppTextStyles.bodyStrong,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _rescan,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Tekrar tara'),
              ),
            ],
          ),
        const SizedBox(height: AppSpacing.md),
        for (final candidate in found)
          Padding(
            key: ValueKey(candidate.id),
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _FadeIn(
              child: _DiscoveredRow(
                candidate: candidate,
                selected: _selected.contains(candidate.id),
                onTap: () => _toggle(candidate),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: _selected.isEmpty
                ? null
                : () => setState(() => _step = _ScanStep.assign),
            child: Text(
              _selected.isEmpty
                  ? 'Cihaz seçin'
                  : 'Seçilenleri ekle (${_selected.length})',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAssign() {
    final candidates = _selectedCandidates;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Odaya ata', style: AppTextStyles.bodyStrong),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Önerilen odalar seçili; isterseniz değiştirin.',
          style: AppTextStyles.secondary,
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final candidate in candidates) ...[
          DeviceSummaryRow(
            icon: candidate.kind.icon,
            title: candidate.name,
            subtitle: '${candidate.kind.label} · ${candidate.protocol.label}',
          ),
          const SizedBox(height: AppSpacing.sm),
          RoomPicker(
            selected: _rooms[candidate.id],
            semanticPrefix: '${candidate.name}: ',
            onChanged: (room) => setState(() => _rooms[candidate.id] = room),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        FlowButtons(
          onBack: () => setState(() => _step = _ScanStep.results),
          nextLabel: candidates.length == 1
              ? 'Cihazı ekle'
              : '${candidates.length} cihazı ekle',
          onNext: _add,
        ),
      ],
    );
  }

  Widget _buildAdded() {
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
                  '${_added.length} cihaz eklendi',
                  style: AppTextStyles.bodyStrong,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final device in _added)
          CheckLine(text: '${device.name} · ${device.room.label}'),
        const SizedBox(height: AppSpacing.xl),
        FlowButtons(
          backLabel: 'Tekrar tara',
          onBack: _rescan,
          nextLabel: 'Bitti',
          onNext: widget.onDone,
        ),
      ],
    );
  }
}

class _DiscoveredRow extends StatelessWidget {
  const _DiscoveredRow({
    required this.candidate,
    required this.selected,
    required this.onTap,
  });

  final DeviceCandidate candidate;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HoverSurface(
      onTap: onTap,
      selected: selected,
      semanticLabel:
          '${candidate.name}. ${candidate.protocol.label}. Sinyal '
          '${candidate.signal.label}. ${selected ? 'Seçili' : 'Seçili değil'}.',
      color: selected ? AppColors.primarySurface : AppColors.background,
      hoverColor: selected ? AppColors.primarySurface : AppColors.simulator,
      border: Border.all(
        color: selected ? AppColors.primary : AppColors.border,
      ),
      hoverBorderColor: selected ? AppColors.primary : AppColors.borderStrong,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: ExcludeSemantics(
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_box : Icons.check_box_outline_blank,
              color: selected ? AppColors.primary : AppColors.icon,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
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
            ),
          ],
        ),
      ),
    );
  }
}

/// Fades a newly discovered row in (instant with reduced motion).
class _FadeIn extends StatelessWidget {
  const _FadeIn({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: context.motion(AppDurations.state),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 6),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
