import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/hover_surface.dart';
import '../../core/widgets/logo_mark.dart';
import '../../models/app_mode.dart';
import '../../providers/app_mode_provider.dart';

/// First screen: asks who will use the system.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final titleSize = width < 600 ? 40.0 : AppTextStyles.display.fontSize!;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.xxxl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                children: [
                  const LogoMark.tile(size: 56),
                  const SizedBox(height: AppSpacing.xl),
                  Semantics(
                    header: true,
                    child: Text(
                      AppStrings.appName,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.display.copyWith(
                        fontSize: titleSize,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const SizedBox(width: 48, child: Divider()),
                  const SizedBox(height: AppSpacing.xl),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Text(
                      AppStrings.tagline,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 16,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  Semantics(
                    header: true,
                    child: const Text(
                      AppStrings.modeQuestion,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.section,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const device = _ModeOption(
                        mode: AppMode.device,
                        icon: Icons.tablet_mac_outlined,
                        title: AppStrings.deviceModeTitle,
                        description: AppStrings.deviceModeDescription,
                      );
                      const family = _ModeOption(
                        mode: AppMode.family,
                        icon: Icons.people_outline,
                        title: AppStrings.familyModeTitle,
                        description: AppStrings.familyModeDescription,
                      );
                      if (constraints.maxWidth < 560) {
                        return const Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            device,
                            SizedBox(height: AppSpacing.lg),
                            family,
                          ],
                        );
                      }
                      return const IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: device),
                            SizedBox(width: AppSpacing.lg),
                            Expanded(child: family),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: const Text(
                      AppStrings.demoDisclaimer,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.mode,
    required this.icon,
    required this.title,
    required this.description,
  });

  final AppMode mode;
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return HoverSurface(
      onTap: () => context.read<AppModeProvider>().selectMode(mode),
      border: Border.all(color: AppColors.border),
      hoverBorderColor: AppColors.primaryBorder,
      hoverColor: AppColors.surfaceSecondary,
      pressedColor: AppColors.simulator,
      borderRadius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  border: Border.all(color: AppColors.primaryBorder),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                style: AppTextStyles.bodyStrong.copyWith(fontSize: 16),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                description,
                style: AppTextStyles.secondary.copyWith(fontSize: 14),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.lg),
            child: Row(
              children: [
                Text('Devam et', style: AppTextStyles.link),
                SizedBox(width: AppSpacing.xs),
                Icon(Icons.arrow_forward, size: 16, color: AppColors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
