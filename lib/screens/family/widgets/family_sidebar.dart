import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/motion.dart';
import '../../../core/widgets/hover_surface.dart';
import '../../../core/widgets/logo_mark.dart';
import '../../../models/app_mode.dart';
import '../../../providers/app_mode_provider.dart';

/// One navigation destination or action, shared by sidebar and bottom bar.
class _NavEntry {
  const _NavEntry({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onSelected,
    this.section,
  });

  final IconData icon;
  final String label;
  final String tooltip;
  final FamilySection? section;
  final void Function(AppModeProvider provider) onSelected;
}

final _sections = [
  _NavEntry(
    icon: Icons.home_outlined,
    label: 'Ev',
    tooltip: 'Ev — günlük durum ve etkinlikler',
    section: FamilySection.home,
    onSelected: (p) => p.selectSection(FamilySection.home),
  ),
  _NavEntry(
    icon: Icons.tune,
    label: 'Ayarlar',
    tooltip: 'Ayarlar — görünüm ve demo tercihleri',
    section: FamilySection.settings,
    onSelected: (p) => p.selectSection(FamilySection.settings),
  ),
  _NavEntry(
    icon: Icons.person_outline,
    label: 'Profil',
    tooltip: 'Profil — takip edilen kişi',
    section: FamilySection.profile,
    onSelected: (p) => p.selectSection(FamilySection.profile),
  ),
];

final _actions = [
  _NavEntry(
    icon: Icons.tablet_mac_outlined,
    label: 'Cihaz',
    tooltip: 'Cihaz Modu',
    onSelected: (p) => p.selectMode(AppMode.device),
  ),
  _NavEntry(
    icon: Icons.swap_horiz,
    label: 'Mod',
    tooltip: AppStrings.backToModeSelection,
    onSelected: (p) => p.returnToModeSelection(),
  ),
];

/// Narrow vertical navigation for tablet and desktop widths.
class FamilySidebar extends StatelessWidget {
  const FamilySidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final current = context.select<AppModeProvider, FamilySection>(
      (p) => p.familySection,
    );
    return SizedBox(
      width: AppLayout.sidebarWidth,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  const Tooltip(
                    message: AppStrings.appName,
                    child: LogoMark(size: 28),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  for (final entry in _sections)
                    _SidebarButton(
                      entry: entry,
                      selected: entry.section == current,
                    ),
                  const Spacer(),
                  for (final entry in _actions)
                    _SidebarButton(entry: entry, selected: false),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarButton extends StatelessWidget {
  const _SidebarButton({required this.entry, required this.selected});

  final _NavEntry entry;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final duration = context.motion(AppDurations.hover);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          AnimatedContainer(
            duration: duration,
            width: 3,
            height: 20,
            decoration: BoxDecoration(
              color: selected ? AppColors.heading : Colors.transparent,
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(AppRadius.sm),
              ),
            ),
          ),
          const Spacer(),
          HoverSurface(
            tooltip: entry.tooltip,
            semanticLabel: entry.label,
            selected: selected,
            color: selected ? AppColors.simulator : Colors.transparent,
            onTap: () => entry.onSelected(context.read<AppModeProvider>()),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                entry.icon,
                color: selected ? AppColors.heading : AppColors.muted,
              ),
            ),
          ),
          const Spacer(),
          const SizedBox(width: 3),
        ],
      ),
    );
  }
}

/// Bottom navigation for phone widths.
class FamilyBottomNav extends StatelessWidget {
  const FamilyBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final current = context.select<AppModeProvider, FamilySection>(
      (p) => p.familySection,
    );
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              for (final entry in [..._sections, ..._actions])
                Expanded(
                  child: _BottomNavButton(
                    entry: entry,
                    selected: entry.section != null && entry.section == current,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavButton extends StatelessWidget {
  const _BottomNavButton({required this.entry, required this.selected});

  final _NavEntry entry;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.heading : AppColors.muted;
    return HoverSurface(
      tooltip: entry.tooltip,
      semanticLabel: entry.label,
      selected: selected,
      onTap: () => entry.onSelected(context.read<AppModeProvider>()),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(entry.icon, color: color),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            entry.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.micro.copyWith(
              color: color,
              letterSpacing: 0,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
