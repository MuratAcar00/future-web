import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/motion.dart';
import '../../models/app_mode.dart';
import '../../models/presentation_step.dart';
import '../../providers/app_mode_provider.dart';
import '../presentation/presentation_highlight.dart';
import 'ecosystems/ecosystem_screen.dart';
import 'profile/profile_screen.dart';
import 'settings/settings_screen.dart';
import 'widgets/activity_timeline.dart';
import 'widgets/demo_panel.dart';
import 'widgets/family_header.dart';
import 'widgets/family_page.dart';
import 'widgets/family_sidebar.dart';
import 'widgets/routine_banner.dart';
import 'widgets/sensor_status_overview.dart';

/// Responsive family dashboard shell.
///
/// * ≥ 1024px: sidebar · feed · demo panel column (300–320px).
/// * 600–1023px: sidebar · feed with a collapsible demo panel.
/// * < 600px: feed with a collapsible demo panel and bottom navigation.
class FamilyDashboard extends StatelessWidget {
  const FamilyDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final section = context.select<AppModeProvider, FamilySection>(
      (p) => p.familySection,
    );
    final showDemoPanel = context.select<AppModeProvider, bool>(
      (p) => p.showDemoPanel,
    );

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isDesktop = width >= AppBreakpoints.desktop;
          final isMobile = width < AppBreakpoints.mobile;

          final content = AnimatedSwitcher(
            duration: context.motion(AppDurations.fade),
            child: KeyedSubtree(
              key: ValueKey(section),
              child: switch (section) {
                FamilySection.home => _HomeFeed(
                  inlineDemoPanel: showDemoPanel && !isDesktop,
                  demoPanelExpanded: !isMobile,
                ),
                FamilySection.ecosystems => const EcosystemScreen(),
                FamilySection.settings => const SettingsScreen(),
                FamilySection.profile => const ProfileScreen(),
              },
            ),
          );

          if (isMobile) {
            return Column(
              children: [
                Expanded(child: SafeArea(bottom: false, child: content)),
                const FamilyBottomNav(),
              ],
            );
          }

          return SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const FamilySidebar(),
                const VerticalDivider(width: 1),
                Expanded(child: content),
                if (isDesktop && showDemoPanel) ...[
                  const VerticalDivider(width: 1),
                  SizedBox(
                    width: width >= AppBreakpoints.wide
                        ? AppLayout.demoPanelWidth
                        : AppLayout.demoPanelCompactWidth,
                    child: const PresentationHighlight(
                      target: PresentationTarget.demoPanel,
                      child: DemoPanel(),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HomeFeed extends StatelessWidget {
  const _HomeFeed({
    required this.inlineDemoPanel,
    required this.demoPanelExpanded,
  });

  final bool inlineDemoPanel;
  final bool demoPanelExpanded;

  @override
  Widget build(BuildContext context) {
    return FamilyPage(
      children: [
        const FamilyHeader(),
        const SizedBox(height: AppSpacing.xl),
        const PresentationHighlight(
          target: PresentationTarget.banner,
          child: RoutineBanner(),
        ),
        if (inlineDemoPanel) ...[
          const SizedBox(height: AppSpacing.xl),
          PresentationHighlight(
            target: PresentationTarget.demoPanel,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.simulator,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: DemoPanel(
                collapsible: true,
                initiallyExpanded: demoPanelExpanded,
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xxl),
        const PresentationHighlight(
          target: PresentationTarget.sensors,
          child: SensorStatusOverview(),
        ),
        const SizedBox(height: AppSpacing.xxl),
        const PresentationHighlight(
          target: PresentationTarget.timeline,
          child: ActivityTimeline(),
        ),
      ],
    );
  }
}
