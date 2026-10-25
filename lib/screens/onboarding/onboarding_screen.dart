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
import '../presentation/presentation_layer.dart';

/// First screen: asks who will use the system.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final titleSize = width < 600 ? 38.0 : AppTextStyles.display.fontSize!;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.45, 1.0],
            colors: [
              Color(0xFFEFFEFB), // teal-50 tint
              Color(0xFFF8FFFE),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.xxxl,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 740),
                child: Column(
                  children: [
                    // ── Hero ──────────────────────────────────────────────
                    const _HeroBadge(),
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
                    const SizedBox(height: AppSpacing.lg),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Text(
                        AppStrings.tagline,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 17,
                          color: AppColors.muted,
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    // ── How it works pills ─────────────────────────────────
                    const _HowItWorksPills(),
                    const SizedBox(height: AppSpacing.xxxl),
                    // ── Mode selection ────────────────────────────────────
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
                          features: [
                            'Büyük saat ekranı',
                            'İYİYİM onay butonu',
                            'Dokunmaya duyarlı',
                          ],
                          accentColor: AppColors.primaryOnDark,
                          dark: true,
                        );
                        const family = _ModeOption(
                          mode: AppMode.family,
                          icon: Icons.people_outline,
                          title: AppStrings.familyModeTitle,
                          description: AppStrings.familyModeDescription,
                          features: [
                            'Sabah rutini takibi',
                            'Sensör & etkinlik akışı',
                            'Ekosistem entegrasyonu',
                          ],
                          accentColor: AppColors.primary,
                          dark: false,
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
                    const SizedBox(height: AppSpacing.xl),
                    const StartPresentationButton(),
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
      ),
    );
  }
}

// ── Hero badge ────────────────────────────────────────────────────────────────

class _HeroBadge extends StatelessWidget {
  const _HeroBadge();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primaryBorder, width: 1.5),
          ),
          child: const Center(child: LogoMark(size: 32, color: AppColors.primary, accent: AppColors.primary)),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.primaryBorder),
          ),
          child: const Text(
            'Edge Hub · Akıllı ev ağ geçidi',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }
}

// ── How it works pills ────────────────────────────────────────────────────────

class _HowItWorksPills extends StatelessWidget {
  const _HowItWorksPills();

  @override
  Widget build(BuildContext context) {
    const steps = [
      (Icons.sensors, 'Sensörler bağlanır'),
      (Icons.arrow_forward, null),
      (Icons.hub_outlined, 'Edge Hub toplar'),
      (Icons.arrow_forward, null),
      (Icons.cloud_outlined, 'Bulut analiz eder'),
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final (icon, label) in steps)
          label != null
              ? _Pill(icon: icon, label: label)
              : Icon(icon, size: 14, color: AppColors.icon),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.muted),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mode option card ──────────────────────────────────────────────────────────

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.mode,
    required this.icon,
    required this.title,
    required this.description,
    required this.features,
    required this.accentColor,
    required this.dark,
  });

  final AppMode mode;
  final IconData icon;
  final String title;
  final String description;
  final List<String> features;
  final Color accentColor;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final bgColor = dark ? const Color(0xFF0F1F1E) : Colors.white;
    final textColor = dark ? Colors.white : AppColors.heading;
    final subColor = dark ? const Color(0xB3FFFFFF) : AppColors.muted;
    final borderColor = dark ? const Color(0xFF1F3533) : AppColors.border;
    final hoverBorder = dark ? const Color(0xFF2DD4BF) : AppColors.primaryBorder;
    final featureDotColor = dark ? AppColors.primaryOnDark : AppColors.primary;

    return HoverSurface(
      onTap: () => context.read<AppModeProvider>().selectMode(mode),
      color: bgColor,
      border: Border.all(color: borderColor),
      hoverBorderColor: hoverBorder,
      hoverColor: dark ? const Color(0xFF162120) : AppColors.surfaceSecondary,
      pressedColor: dark ? const Color(0xFF0A1514) : AppColors.simulator,
      borderRadius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon badge
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(dark ? 30 : 18),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: accentColor.withAlpha(50)),
                ),
                child: Icon(icon, color: accentColor, size: 26),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                style: AppTextStyles.bodyStrong.copyWith(
                  fontSize: 17,
                  color: textColor,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                description,
                style: AppTextStyles.secondary.copyWith(
                  fontSize: 13,
                  color: subColor,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Feature bullets
              for (final feat in features)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: featureDotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        feat,
                        style: TextStyle(
                          fontSize: 13,
                          color: subColor,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: Row(
              children: [
                Text(
                  'Devam et',
                  style: AppTextStyles.link.copyWith(color: accentColor),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(Icons.arrow_forward, size: 16, color: accentColor),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
